// [R16] Immutable drawn card model.
import '../data/chance_cards_data.dart';

class ChanceCard {
  final ChanceCardData data;
  final String playerId;
  final int round;
  const ChanceCard(this.data, this.playerId, this.round);
  Map<String, dynamic> toJson() => {
    'id': data.id,
    'playerId': playerId,
    'round': round,
  };
}
