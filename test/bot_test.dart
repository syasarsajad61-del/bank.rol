// [B01-B10][R04] Automated games exercise every action through the human API.
import 'package:flutter_test/flutter_test.dart';
import 'package:bankroll_plato/core/models/game_state.dart';
import 'package:bankroll_plato/core/rules/turn_manager.dart';
import 'package:bankroll_plato/ai/bot_controller.dart';

void main() {
  test('bots finish seeded games without illegal decisions', () {
    for (final difficulty in Difficulty.values) {
      for (int seed = 1; seed <= 4; seed++) {
        final s = TurnManager.create(
          List.generate(
            4,
            (i) => Player(
              id: 'p$i',
              name: 'ربات $i',
              identity: i,
              bot: true,
              difficulty: difficulty,
              personality: Personality.values[i % 3],
            ),
          ),
          target: 7000,
          rounds: 30,
          seed: seed,
        );
        int now = DateTime.now().millisecondsSinceEpoch;
        int actions = 0;
        while (!s.ended && actions < 6000) {
          TurnManager.tick(s, now);
          if (s.ended) break;
          bool acted = false;
          for (final p in s.alive) {
            final a = BotController.decide(s, p);
            if (a != null) {
              TurnManager.apply(s, p.id, a.type, a.data, now);
              acted = true;
              actions++;
              break;
            }
          }
          if (!acted) {
            now += 16000;
          } else {
            now += 100;
          }
          expect(s.players.every((p) => p.cash.isFinite), true);
        }
        expect(
          s.ended,
          true,
          reason:
              'difficulty=$difficulty seed=$seed actions=$actions round=${s.round}',
        );
      }
    }
  });
}
