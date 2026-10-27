// [R11][R12][R13][R27] Multiplicative rent formula.
import '../models/game_state.dart';
import '../data/properties_data.dart';
import 'phase_engine.dart';
import 'inflation.dart';

class RentCalculator {
  static bool fullBlock(GameState s, Property p) =>
      p.block != null &&
      p.owner != null &&
      s.properties
          .where((q) => q.block == p.block)
          .every((q) => q.owner == p.owner);
  static double calculate({
    required double base,
    double phaseMult = 1,
    double inflation = 0,
    double blockMult = 1,
    double publicMult = 1,
    double insuranceMult = 1,
    double lawMult = 1,
    double buildingMult = 1,
  }) =>
      base *
      phaseMult *
      (1 + inflation) *
      blockMult *
      publicMult *
      insuranceMult *
      lawMult *
      buildingMult;
  static double of(GameState s, Property p, Player visitor) => calculate(
    base: p.baseRent.toDouble(),
    phaseMult: PhaseEngine.rent(s.phase),
    inflation: Inflation.of(s),
    blockMult: fullBlock(s, p) ? BLOCK_BONUS_MULTIPLIER : 1,
    publicMult: p.isPublic
        ? (s.laws.contains('law_09')
              ? 2
              : s.properties
                    .where((q) => q.isPublic && q.owner == p.owner)
                    .length
                    .toDouble())
        : 1,
    insuranceMult:
        s.policies.any(
          (i) =>
              i.owner == visitor.id &&
              i.expires > s.round &&
              (i.propertyId == null || i.propertyId == p.id),
        )
        ? 0.5
        : 1,
    lawMult: s.laws.contains('law_01') ? 1.2 : 1,
    buildingMult: BUILDING_RENT_MULTIPLIER[p.buildings]!,
  );
  static double value(GameState s, Property p) =>
      p.price * PhaseEngine.buy(s.phase) * (1 + Inflation.of(s));
  static double buildingPrice(GameState s, Property p) =>
      p.buildingCost *
      PhaseEngine.buy(s.phase) *
      (1 + Inflation.of(s)) *
      (s.laws.contains('law_05') ? 1.3 : 1);
}
