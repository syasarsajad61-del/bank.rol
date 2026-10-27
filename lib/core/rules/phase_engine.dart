// [R19][T07] Locked Markov transitions and phase coefficients.
import '../models/game_state.dart';

class PhaseEngine {
  static double rent(EconomicPhase p) => switch (p) {
    EconomicPhase.stable => 1,
    EconomicPhase.bull => 1.4,
    EconomicPhase.bear => .7,
  };
  static double buy(EconomicPhase p) => switch (p) {
    EconomicPhase.stable => 1,
    EconomicPhase.bull => 1.15,
    EconomicPhase.bear => .9,
  };
  static double interest(EconomicPhase p) => switch (p) {
    EconomicPhase.stable => .15,
    EconomicPhase.bull => .1,
    EconomicPhase.bear => .2,
  };
  static double salary(EconomicPhase p) => switch (p) {
    EconomicPhase.stable => 200,
    EconomicPhase.bull => 250,
    EconomicPhase.bear => 150,
  };
  static EconomicPhase next(EconomicPhase p, int draw) => switch (p) {
    EconomicPhase.stable =>
      draw < 40
          ? EconomicPhase.bull
          : draw < 80
          ? EconomicPhase.stable
          : EconomicPhase.bear,
    EconomicPhase.bull =>
      draw < 50
          ? EconomicPhase.stable
          : draw < 80
          ? EconomicPhase.bear
          : EconomicPhase.bull,
    EconomicPhase.bear =>
      draw < 50
          ? EconomicPhase.stable
          : draw < 80
          ? EconomicPhase.bull
          : EconomicPhase.bear,
  };
  static String label(EconomicPhase p) => ['ثبات', 'رونق', 'رکود'][p.index];
}
