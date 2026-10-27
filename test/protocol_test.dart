// [A02][A03][M10] Authentication, replay and snapshot privacy.
import 'package:flutter_test/flutter_test.dart';
import 'package:bankroll_plato/network/protocol.dart';
import 'package:bankroll_plato/network/snapshot.dart';
import 'package:bankroll_plato/core/models/game_state.dart';
import 'test_helpers.dart';

void main() {
  test('encrypt authenticate and reject replay or wrong session key', () async {
    final a = await SecureProtocol.derive('12345678', 'session', 'id'),
        b = await SecureProtocol.derive('12345678', 'session', 'id'),
        wrong = await SecureProtocol.derive('87654321', 'session', 'id');
    final raw = await a.encode({'bid': 250});
    expect(raw.contains('250'), false);
    expect(await b.decode(raw), {'bid': 250});
    await expectLater(b.decode(raw), throwsFormatException);
    await expectLater(wrong.decode(raw), throwsA(anything));
  });
  test('snapshot hides third party contracts and detects tampering', () {
    final s = fixture();
    s.contracts.add(
      Contract(
        id: 'secret',
        first: s.players[0].id,
        second: s.players[1].id,
        kind: ContractKind.informant,
        expires: 5,
      ),
    );
    final view = Snapshot.encode(s, viewer: s.players[2].id);
    expect(Snapshot.decode(view).contracts, isEmpty);
    final full = Snapshot.encode(s, migration: true);
    expect(Snapshot.decode(full).contracts.length, 1);
    (full['state'] as Map)['bank'] = 999;
    expect(() => Snapshot.decode(full), throwsFormatException);
  });
}
