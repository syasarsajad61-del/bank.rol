// [B01][B10] Easy strategy using the shared command API.
import '../core/models/game_state.dart';
import 'bot_controller.dart';

class BotEasy {
  static Player create(
    String id,
    String name,
    int identity, {
    Personality personality = Personality.balanced,
  }) => Player(
    id: id,
    name: name,
    identity: identity,
    bot: true,
    difficulty: Difficulty.easy,
    personality: personality,
  );
  static BotAction? decide(GameState s, Player p) {
    if (p.difficulty != Difficulty.easy) {
      throw ArgumentError('Difficulty mismatch');
    }
    return BotController.decide(s, p);
  }
}
