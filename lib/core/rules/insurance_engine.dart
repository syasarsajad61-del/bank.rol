// [R26] Policies last three rounds and are capped at two.
import '../models/game_state.dart';

class InsuranceEngine {
  static bool covered(GameState s, String id) =>
      s.policies.any((p) => p.owner == id && p.expires > s.round);
  static double premium(GameState s, Player p) =>
      s.netWorth(p.id).clamp(0, double.infinity) *
      .1 *
      (s.laws.contains('law_10') ? 0.5 : 1);
  static void buy(GameState s, Player p) {
    if (s.policies
            .where((i) => i.owner == p.id && i.expires > s.round)
            .length >=
        2) {
      throw StateError('حداکثر دو بیمه');
    }
    final cost = premium(s, p);
    if (p.cash < cost) throw StateError('نقد کافی نیست');
    p.cash -= cost;
    s.policies.add(Insurance(p.id, s.round + 3));
    s.record('${p.name} بیمه خرید');
  }
}
