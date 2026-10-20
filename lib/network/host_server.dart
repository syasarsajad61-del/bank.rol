import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/action_request.dart';

/// A connected socket plus its liveness bookkeeping.
class _Peer {
  _Peer(this.id, this.channel);

  final String id;
  final WebSocketChannel channel;
  DateTime lastSeen = DateTime.now();
  bool closed = false;

  void touch() => lastSeen = DateTime.now();
}

/// Host-side WebSocket server.
///
/// Owns the transport only: it never touches game rules. Every decoded
/// [ActionRequest] is handed to [onMessage] together with the peer id, and
/// the game controller decides what to do with it.
class HostServer {
  HostServer({
    required this.onPeerConnected,
    required this.onPeerDisconnected,
    required this.onMessage,
    this.port = 8080,
    this.heartbeatInterval = const Duration(seconds: 3),
    this.peerTimeout = const Duration(seconds: 12),
  });

  final void Function(String socketId)? onPeerConnected;
  final void Function(String socketId)? onPeerDisconnected;
  final void Function(String socketId, WireMessage message) onMessage;

  final int port;
  final Duration heartbeatInterval;
  final Duration peerTimeout;

  HttpServer? _httpServer;
  Timer? _heartbeat;
  final Map<String, _Peer> _peers = <String, _Peer>{};
  int _peerSeq = 0;
  bool _running = false;
  int _boundPort = 0;

  bool get isRunning => _running;

  int get boundPort => _boundPort;

  int get peerCount => _peers.length;

  /// Starts listening. Tries [port], then the next few ports if busy.
  Future<int> start() async {
    if (_running) {
      return _boundPort;
    }
    final Handler wsHandler = webSocketHandler(
      (WebSocketChannel channel, String? protocol) => _accept(channel),
      pingInterval: const Duration(seconds: 15),
    );

    final Handler pipeline = const Pipeline()
        .addMiddleware(logRequests(logger: (String message, bool isError) {}))
        .addHandler(wsHandler);

    Object? lastError;
    for (int candidate = port; candidate < port + 12; candidate++) {
      try {
        final HttpServer server = await shelf_io.serve(
          pipeline,
          InternetAddress.anyIPv4,
          candidate,
          shared: false,
        );
        server.autoCompress = true;
        _httpServer = server;
        _boundPort = candidate;
        break;
      } catch (error) {
        lastError = error;
      }
    }

    if (_httpServer == null) {
      throw StateError(
        'راه‌اندازی سرور ممکن نشد. پورت $port تا ${port + 11} در دسترس نیست. ($lastError)',
      );
    }

    _running = true;
    _heartbeat = Timer.periodic(heartbeatInterval, (_) => _tickHeartbeat());
    return _boundPort;
  }

  void _accept(WebSocketChannel channel) {
    final String id = 's${++_peerSeq}';
    final _Peer peer = _Peer(id, channel);
    _peers[id] = peer;

    channel.stream.listen(
      (dynamic data) {
        peer.touch();
        _handleRaw(id, data);
      },
      onDone: () => _dropPeer(id),
      onError: (Object error) => _dropPeer(id),
      cancelOnError: true,
    );

    send(id, WireMessage(WireMessage.info, <String, dynamic>{
      'server': 'neon-bankroll',
      'protocol': 1,
      'port': _boundPort,
    }));
    onPeerConnected?.call(id);
  }

  void _handleRaw(String id, dynamic data) {
    if (data is! String) {
      return;
    }
    Map<String, dynamic> decoded;
    try {
      final dynamic raw = jsonDecode(data);
      if (raw is! Map) {
        return;
      }
      decoded = Map<String, dynamic>.from(raw);
    } catch (_) {
      return;
    }
    final WireMessage message = WireMessage.fromJson(decoded);
    if (message.type == WireMessage.pong || message.type == WireMessage.ping) {
      final _Peer? peer = _peers[id];
      peer?.touch();
      if (message.type == WireMessage.ping) {
        send(id, WireMessage(WireMessage.pong, message.payload));
      }
      return;
    }
    onMessage(id, message);
  }

  void _tickHeartbeat() {
    final DateTime now = DateTime.now();
    final List<String> dead = <String>[];
    _peers.forEach((String id, _Peer peer) {
      if (now.difference(peer.lastSeen) > peerTimeout) {
        dead.add(id);
        return;
      }
      send(id, WireMessage(WireMessage.ping, <String, dynamic>{
        'ts': now.millisecondsSinceEpoch,
      }));
    });
    for (final String id in dead) {
      _closePeer(id, reason: 'heartbeat timeout');
    }
  }

  void _dropPeer(String id) {
    final _Peer? peer = _peers.remove(id);
    if (peer == null) {
      return;
    }
    peer.closed = true;
    onPeerDisconnected?.call(id);
  }

  void _closePeer(String id, {String reason = ''}) {
    final _Peer? peer = _peers[id];
    if (peer == null) {
      return;
    }
    send(id, WireMessage(WireMessage.bye, <String, dynamic>{'reason': reason}));
    try {
      peer.channel.sink.close();
    } catch (_) {
      // Socket already gone; nothing to do.
    }
    _dropPeer(id);
  }

  /// Sends an envelope to a single peer.
  void send(String socketId, WireMessage message) {
    final _Peer? peer = _peers[socketId];
    if (peer == null || peer.closed) {
      return;
    }
    try {
      peer.channel.sink.add(jsonEncode(message.toJson()));
    } catch (_) {
      _dropPeer(socketId);
    }
  }

  /// Sends an envelope to every connected peer.
  void broadcast(WireMessage message) {
    final String encoded = jsonEncode(message.toJson());
    final List<String> broken = <String>[];
    _peers.forEach((String id, _Peer peer) {
      if (peer.closed) {
        return;
      }
      try {
        peer.channel.sink.add(encoded);
      } catch (_) {
        broken.add(id);
      }
    });
    for (final String id in broken) {
      _dropPeer(id);
    }
  }

  bool isConnected(String socketId) {
    final _Peer? peer = _peers[socketId];
    return peer != null && !peer.closed;
  }

  Future<void> stop() async {
    _heartbeat?.cancel();
    _heartbeat = null;
    _running = false;
    for (final String id in _peers.keys.toList(growable: false)) {
      _closePeer(id, reason: 'server stopping');
    }
    _peers.clear();
    await _httpServer?.close(force: true);
    _httpServer = null;
  }

  /// Best-effort LAN IPv4 address used for the QR payload.
  static Future<String?> findLocalIpv4() async {
    try {
      final List<NetworkInterface> interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
        includeLinkLocal: false,
      );
      final List<String> addresses = <String>[];
      for (final NetworkInterface interface in interfaces) {
        for (final InternetAddress address in interface.addresses) {
          if (address.type == InternetAddressType.IPv4) {
            addresses.add(address.address);
          }
        }
      }
      if (addresses.isEmpty) {
        return null;
      }
      for (final String address in addresses) {
        if (address.startsWith('192.168.') ||
            address.startsWith('10.') ||
            address.startsWith('172.')) {
          return address;
        }
      }
      return addresses.first;
    } catch (_) {
      return null;
    }
  }
}
