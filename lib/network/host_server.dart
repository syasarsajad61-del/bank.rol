// [M01][M06][M08][M09][M11][M13][A01][A05][A06] Host authority.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:uuid/uuid.dart';
import '../core/models/game_state.dart';
import '../core/utils/logger.dart';
import 'protocol.dart';
import 'snapshot.dart';

class Peer {
  final String id, name, address;
  WebSocket? socket;
  SecureProtocol codec;
  int lastSeen;
  Future<void> outgoing = Future.value(), incoming = Future.value();
  Peer(this.id, this.name, this.address, this.socket, this.codec)
    : lastSeen = DateTime.now().millisecondsSinceEpoch;
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'address': address,
    'connected': socket != null,
  };
}

class HostServer {
  HttpServer? server;
  final String hostId, hostName, pin, session;
  final int port;
  final Map<String, Peer> peers = {};
  final void Function(String, String, Map<String, dynamic>, int) onAction;
  final void Function() onRoster;
  GameState? Function() state;
  HostServer({
    required this.hostId,
    required this.hostName,
    required this.pin,
    required this.onAction,
    required this.onRoster,
    required this.state,
    this.port = 7823,
    String? session,
  }) : session = session ?? const Uuid().v4();
  Future<void> start() async {
    server = await HttpServer.bind(InternetAddress.anyIPv4, port);
    server!.listen((request) async {
      if (!WebSocketTransformer.isUpgradeRequest(request)) {
        request.response.statusCode = 404;
        await request.response.close();
        return;
      }
      final address = request.connectionInfo?.remoteAddress.address ?? '';
      final socket = await WebSocketTransformer.upgrade(request);
      socket.pingInterval = const Duration(seconds: 10);
      socket.add(
        jsonEncode({'type': 'hello', 'session': session, 'hostId': hostId}),
      );
      String? peerId;
      SecureProtocol? codec;
      Future<void> queue = Future.value();
      final authTimer = Timer(const Duration(seconds: 10), () {
        if (peerId == null) socket.close(1008, 'Join timeout');
      });
      socket.listen(
        (raw) {
          queue = queue.then((_) async {
            try {
              if (raw is! String || raw.length > 2000000) {
                throw const FormatException('Invalid frame');
              }
              if (peerId == null) {
                final envelope = jsonDecode(raw) as Map<String, dynamic>;
                final id = envelope['clientId'] as String;
                if (id == hostId || !RegExp(r'^[a-f0-9-]{36}$').hasMatch(id)) {
                  throw const FormatException('Invalid identity');
                }
                codec =
                    peers[id]?.codec ??
                    await SecureProtocol.derive(pin, session, id);
                final j = await codec!.decode(envelope['join']);
                if (j['type'] != 'join' || j['id'] != id) {
                  throw const FormatException('Invalid join');
                }
                final existing = peers[id];
                final now = DateTime.now().millisecondsSinceEpoch;
                final knownPlayer =
                    state()?.players.any(
                      (p) => p.id == id && !p.bot && !p.eliminated,
                    ) ??
                    false;
                if (existing == null &&
                    (peers.length >= 5 || (state() != null && !knownPlayer))) {
                  throw StateError('اتاق پر است یا بازی شروع شده');
                }
                if (existing != null &&
                    existing.socket == null &&
                    now - existing.lastSeen > 60000) {
                  throw StateError('مهلت اتصال مجدد تمام شد');
                }
                if (existing != null && existing.socket != null) {
                  throw StateError('این شناسه متصل است');
                }
                final name = (j['name'] as String).trim();
                if (name.isEmpty || name.length > 24) {
                  throw StateError('نام معتبر نیست');
                }
                peerId = id;
                authTimer.cancel();
                peers[id] = Peer(
                  id,
                  existing?.name ?? name,
                  address,
                  socket,
                  codec!,
                );
                send(id, {'type': 'welcome', 'id': id, 'hostId': hostId});
                onRoster();
                await broadcast();
                return;
              }
              final peer = peers[peerId]!;
              final j = await codec!.decode(raw);
              peer.lastSeen = DateTime.now().millisecondsSinceEpoch;
              if (j['type'] == 'action') {
                final s = state();
                if (s == null) throw StateError('بازی آغاز نشده');
                if (j['revision'] != s.revision &&
                    j['action'] != 'bid' &&
                    j['action'] != 'vote') {
                  throw StateError('وضعیت تغییر کرده؛ دوباره تلاش کنید');
                }
                onAction(
                  peer.id,
                  j['action'],
                  Map<String, dynamic>.from(j['data'] ?? {}),
                  DateTime.now().millisecondsSinceEpoch,
                );
                await broadcast();
              }
              if (j['type'] == 'ping') send(peer.id, {'type': 'pong'});
            } catch (e) {
              if (peerId == null) {
                socket.close(1008, 'Join refused');
              } else {
                send(peerId!, {
                  'type': 'error',
                  'message': e is StateError
                      ? e.message
                      : 'پیام نامعتبر یا تکراری',
                });
              }
              GameLogger.event('network_reject');
            }
          });
        },
        onDone: () {
          authTimer.cancel();
          if (peerId != null && peers[peerId]?.socket == socket) {
            peers[peerId]!.socket = null;
            peers[peerId]!.lastSeen = DateTime.now().millisecondsSinceEpoch;
            onRoster();
          }
        },
        onError: (Object e) {
          socket.close();
        },
      );
    });
  }

  List<Map<String, dynamic>> get roster => [
    {'id': hostId, 'name': hostName, 'address': '', 'connected': true},
    ...peers.values.map((p) => p.toJson()),
  ];
  String? get successor {
    final live =
        peers.values.where((p) => p.socket != null).map((p) => p.id).toList()
          ..sort();
    return live.isEmpty ? null : live.first;
  }

  void send(String id, Map<String, dynamic> value) {
    final p = peers[id];
    if (p?.socket == null) return;
    p!.outgoing = p.outgoing
        .then((_) async {
          final encoded = await p.codec.encode(value);
          p.socket?.add(encoded);
        })
        .catchError((Object e) {
          GameLogger.event('send_failed');
        });
  }

  Future<void> broadcast() async {
    final s = state();
    for (final p in peers.values.where((p) => p.socket != null)) {
      send(p.id, {
        'type': 'roster',
        'players': roster,
        'successor': successor,
        'port': port,
      });
      if (s != null) {
        send(p.id, {
          'type': 'snapshot',
          'snapshot': Snapshot.encode(s, viewer: p.id),
        });
        if (p.id == successor) {
          send(p.id, {
            'type': 'backup',
            'snapshot': Snapshot.encode(s, migration: true),
            'peers': roster,
          });
        }
      }
    }
  }

  Future<void> dispose() async {
    for (final p in peers.values) {
      await p.socket?.close();
    }
    await server?.close(force: true);
  }
}
