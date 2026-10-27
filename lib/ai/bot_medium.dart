// [B01][B10] Medium strategy using the shared command API.
import '../core/models/game_state.dart';
import 'bot_controller.dart';

class BotMedium {
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
    difficulty: Difficulty.medium,
    personality: personality,
  );
  static BotAction? decide(GameState s, Player p) {
    if (p.difficulty != Difficulty.medium) {
      throw ArgumentError('Difficulty mismatch');
    }
    return BotController.decide(s, p);
  }
}
