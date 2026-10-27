// [R17][R18] Liquidate ownership when a player leaves the game.
import '../models/game_state.dart';

class Bankruptcy {
  static bool failed(GameState s, Player p) =>
      s.netWorth(p.id) <= 0 || p.cash < -500 || p.inactiveTurns >= 3;
  static void check(GameState s) {
    for (final p in s.alive) {
      if (failed(s, p)) {
        p.eliminated = true;
        for (final q in s.properties.where((q) => q.owner == p.id)) {
          q.owner = null;
          q.buildings = 0;
        }
        s.contracts.removeWhere((c) => c.includes(p.id));
        s.record('${p.name} از بازی خارج شد');
      }
    }
  }
}
