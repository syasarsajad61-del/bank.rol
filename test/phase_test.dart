// [R19] Exact Markov counts and reference multipliers.
import 'package:flutter_test/flutter_test.dart';
import 'package:bankroll_plato/core/models/game_state.dart';
import 'package:bankroll_plato/core/rules/phase_engine.dart';

void main() {
  test('all transition buckets match the locked table', () {
    final expected = [
      [40, 40, 20],
      [50, 20, 30],
      [50, 30, 20],
    ];
    for (final p in EconomicPhase.values) {
      final counts = [0, 0, 0];
      for (int i = 0; i < 100; i++) {
        counts[PhaseEngine.next(p, i).index]++;
      }
      expect(counts, expected[p.index]);
    }
  });
  test('phase interest salary and rent values', () {
    expect(PhaseEngine.rent(EconomicPhase.bull), 1.4);
    expect(PhaseEngine.buy(EconomicPhase.bear), .9);
    expect(PhaseEngine.salary(EconomicPhase.bull), 250);
    expect(PhaseEngine.interest(EconomicPhase.bear), .2);
  });
}
