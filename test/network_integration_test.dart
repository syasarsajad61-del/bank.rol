import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';
import 'package:bankroll_plato/core/models/game_state.dart';
import 'package:bankroll_plato/core/rules/turn_manager.dart';
import 'package:bankroll_plato/network/host_server.dart';
import 'package:bankroll_plato/network/client_connection.dart';

void main() {
  test(
    'migrated host admits a snapshot player and rejects an unknown player',
    () async {
      final hostId = const Uuid().v4(), id = const Uuid().v4();
      final state = TurnManager.create([
        Player(id: hostId, name: 'میزبان', identity: 0),
        Player(id: id, name: 'مهمان', identity: 1),
      ]);
      final received = Completer<void>();
      final server = HostServer(
        hostId: hostId,
        hostName: 'میزبان',
        pin: '12345678',
        port: 0,
        state: () => state,
        onRoster: () {},
        onAction: (actor, type, data, now) {
          expect(actor, id);
          expect(type, 'bid');
          received.complete();
        },
      );
      await server.start();
      addTearDown(server.dispose);
      final client = ClientConnection(
        id: id,
        name: 'مهمان',
        pin: '12345678',
        onMessage: (_) {},
        onDisconnected: () {},
      );
      addTearDown(client.dispose);
      await client.connect('127.0.0.1', server.server!.port);
      client.send('bid', {'amount': 12}, state.revision);
      await received.future.timeout(const Duration(seconds: 5));
      await client.dispose();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final rejoined = ClientConnection(
        id: id,
        name: 'مهمان',
        pin: '12345678',
        onMessage: (_) {},
        onDisconnected: () {},
      );
      addTearDown(rejoined.dispose);
      await rejoined.connect('127.0.0.1', server.server!.port);
      final outsider = ClientConnection(
        id: const Uuid().v4(),
        name: 'ناشناس',
        pin: '12345678',
        onMessage: (_) {},
        onDisconnected: () {},
      );
      addTearDown(outsider.dispose);
      await expectLater(
        outsider.connect('127.0.0.1', server.server!.port),
        throwsStateError,
      );
    },
    timeout: const Timeout(Duration(seconds: 25)),
  );
}
