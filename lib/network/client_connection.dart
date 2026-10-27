// [M04][M07][M11][A02][A08] Encrypted client transport; never calculates rules.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'protocol.dart';

class ClientConnection {
  final String id, name, pin;
  final void Function(Map<String, dynamic>) onMessage;
  final void Function() onDisconnected;
  WebSocket? socket;
  SecureProtocol? codec;
  Future<void> outgoing = Future.value(), incoming = Future.value();
  bool closed = false;
  ClientConnection({
    required this.id,
    required this.name,
    required this.pin,
    required this.onMessage,
    required this.onDisconnected,
  });
  Future<void> connect(String address, int port) async {
    socket = await WebSocket.connect(
      'ws://$address:$port',
    ).timeout(const Duration(seconds: 5));
    socket!.pingInterval = const Duration(seconds: 10);
    final ready = Completer<void>();
    socket!.listen(
      (raw) {
        incoming = incoming.then((_) async {
          try {
            if (codec == null) {
              final j = jsonDecode(raw as String);
              if (j['type'] != 'hello') throw const FormatException('No hello');
              codec = await SecureProtocol.derive(pin, j['session'], id);
              socket!.add(
                jsonEncode({
                  'clientId': id,
                  'join': await codec!.encode({
                    'type': 'join',
                    'id': id,
                    'name': name,
                  }),
                }),
              );
            } else {
              final j = await codec!.decode(raw as String);
              if (j['type'] == 'welcome' && !ready.isCompleted) {
                ready.complete();
              }
              onMessage(j);
            }
          } catch (e) {
            if (!ready.isCompleted) ready.completeError(e);
            await socket?.close();
          }
        });
      },
      onDone: () {
        if (!ready.isCompleted) {
          ready.completeError(StateError('اتصال رد شد؛ کد اتاق را بررسی کنید'));
        }
        if (!closed) onDisconnected();
      },
      onError: (Object e) {
        if (!ready.isCompleted) ready.completeError(e);
        if (!closed) onDisconnected();
      },
    );
    await ready.future.timeout(const Duration(seconds: 12));
  }

  void send(String action, Map<String, dynamic> data, int revision) {
    if (codec == null || socket == null) throw StateError('اتصال برقرار نیست');
    outgoing = outgoing.then((_) async {
      socket!.add(
        await codec!.encode({
          'type': 'action',
          'action': action,
          'data': data,
          'revision': revision,
        }),
      );
    });
  }

  Future<void> dispose() async {
    closed = true;
    await socket?.close();
  }
}
