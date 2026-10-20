import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/action_request.dart';

enum LinkStatus {
  idle,
  connecting,
  connected,
  reconnecting,
  closed,
  failed,
}

extension LinkStatusX on LinkStatus {
  String get labelFa {
    switch (this) {
      case LinkStatus.idle:
        return 'آماده';
      case LinkStatus.connecting:
        return 'در حال اتصال';
      case LinkStatus.connected:
        return 'متصل';
      case LinkStatus.reconnecting:
        return 'تلاش مجدد برای اتصال';
      case LinkStatus.closed:
        return 'قطع شده';
      case LinkStatus.failed:
        return 'اتصال ناموفق';
    }
  }
}

/// Client-side socket with automatic reconnect and a 3 second heartbeat.
class ClientSocket {
  ClientSocket({
    required this.host,
    required this.port,
    required this.onMessage,
    required this.onStatus,
    this.path = '/',
    this.heartbeatInterval = const Duration(seconds: 3),
    this.timeout = const Duration(seconds: 12),
  });

  final String host;
  final int port;
  final String path;
  final void Function(WireMessage message) onMessage;
  final void Function(LinkStatus status) onStatus;
  final Duration heartbeatInterval;
  final Duration timeout;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Timer? _heartbeat;
  Timer? _reconnectTimer;
  DateTime _lastSeen = DateTime.now();
  int _attempt = 0;
  bool _disposed = false;

  LinkStatus _status = LinkStatus.idle;

  LinkStatus get status => _status;

  bool get isConnected => _status == LinkStatus.connected;

  Uri get uri => Uri(
        scheme: 'ws',
        host: host,
        port: port,
        path: path,
      );

  Future<void> connect() async {
    if (_disposed) {
      return;
    }
    _reconnectTimer?.cancel();
    _setStatus(_attempt == 0 ? LinkStatus.connecting : LinkStatus.reconnecting);
    try {
      final WebSocketChannel channel = WebSocketChannel.connect(uri);
      await channel.ready.timeout(const Duration(seconds: 8));
      if (_disposed) {
        await channel.sink.close();
        return;
      }
      _channel = channel;
      _lastSeen = DateTime.now();
      _attempt = 0;
      _setStatus(LinkStatus.connected);
      _subscription?.cancel();
      _subscription = channel.stream.listen(
        _handleData,
        onDone: _handleDrop,
        onError: (Object error) => _handleDrop(),
        cancelOnError: true,
      );
      _startHeartbeat();
    } catch (_) {
      _setStatus(LinkStatus.failed);
      _scheduleReconnect();
    }
  }

  void _handleData(dynamic data) {
    _lastSeen = DateTime.now();
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
    if (message.type == WireMessage.ping) {
      // Answer the host heartbeat so it keeps this peer marked as alive.
      send(WireMessage(WireMessage.pong, message.payload));
      return;
    }
    if (message.type == WireMessage.pong) {
      return;
    }
    if (message.type == WireMessage.bye) {
      _disposed = true;
      _setStatus(LinkStatus.closed);
      return;
    }
    _dispatch(message);
  }

  void _dispatch(WireMessage message) {
    try {
      onMessage(message);
    } catch (_) {
      // A rendering error must never kill the socket.
    }
  }

  void _startHeartbeat() {
    _heartbeat?.cancel();
    _heartbeat = Timer.periodic(heartbeatInterval, (_) {
      if (_disposed || _status != LinkStatus.connected) {
        return;
      }
      if (DateTime.now().difference(_lastSeen) > timeout) {
        _handleDrop();
        return;
      }
      send(WireMessage(WireMessage.ping, <String, dynamic>{
        'ts': DateTime.now().millisecondsSinceEpoch,
      }));
    });
  }

  void _handleDrop() {
    if (_disposed) {
      return;
    }
    _heartbeat?.cancel();
    _heartbeat = null;
    _subscription?.cancel();
    _subscription = null;
    try {
      _channel?.sink.close();
    } catch (_) {
      // Already closed.
    }
    _channel = null;
    if (_status == LinkStatus.connected) {
      _setStatus(LinkStatus.closed);
    }
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_disposed) {
      return;
    }
    _reconnectTimer?.cancel();
    _attempt++;
    final int seconds = _attempt <= 1 ? 1 : (_attempt <= 3 ? 2 : 4);
    _setStatus(LinkStatus.reconnecting);
    _reconnectTimer = Timer(Duration(seconds: seconds), () {
      if (!_disposed) {
        connect();
      }
    });
  }

  void _setStatus(LinkStatus next) {
    if (_status == next) {
      return;
    }
    _status = next;
    onStatus(next);
  }

  void send(WireMessage message) {
    final WebSocketChannel? channel = _channel;
    if (channel == null) {
      return;
    }
    try {
      channel.sink.add(jsonEncode(message.toJson()));
    } catch (_) {
      _handleDrop();
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    _heartbeat?.cancel();
    _reconnectTimer?.cancel();
    await _subscription?.cancel();
    _subscription = null;
    try {
      await _channel?.sink.close();
    } catch (_) {
      // Already gone.
    }
    _channel = null;
    _setStatus(LinkStatus.closed);
  }
}
