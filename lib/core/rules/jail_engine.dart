// [R08][R15] Jail occupies three turns, or one under the short-jail law.
import '../models/game_state.dart';

class JailEngine {
  static void send(GameState s, Player p) {
    p.position = 8;
    p.jailTurns = s.laws.contains('law_04') ? 1 : 3;
    p.sixes = 0;
    s.extraRoll = false;
    s.record('${p.name} به زندان رفت');
  }

  static void bail(GameState s, Player p) {
    if (p.jailTurns == 0 || p.cash < 150) {
      throw StateError('آزادی با وثیقه ممکن نیست');
    }
    p.cash -= 150;
    s.bank += 150;
    p.jailTurns = 0;
  }
}
