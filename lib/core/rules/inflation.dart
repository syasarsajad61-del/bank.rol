// [R22][T07] Inflation is bounded before applying the half factor.
import '../models/game_state.dart';

class Inflation {
  static double calculate(double total, double initial) =>
      initial <= 0 ? 0 : ((total / initial) - 1).clamp(-.3, .4) * .5;
  static double of(GameState s) => calculate(
    s.alive.fold<double>(s.bank, (v, p) => v + p.cash),
    s.initialMoney,
  );
}
