// [R20][M13] Sealed bids and authoritative ten second deadline.
import '../models/game_state.dart';

class AuctionEngine {
  static void start(GameState s, String propertyId, String trigger, int now) {
    if (s.auction != null || s.property(propertyId).owner != null) {
      throw StateError('حراج ممکن نیست');
    }
    s.auction = Auction(propertyId, trigger, now + 10000);
    s.record('حراج مخفی آغاز شد');
  }

  static void bid(GameState s, Player p, double amount, int now) {
    final a = s.auction;
    if (a == null ||
        now >= a.deadline ||
        p.eliminated ||
        !amount.isFinite ||
        amount < 0 ||
        amount > p.cash) {
      throw StateError('پیشنهاد مجاز نیست');
    }
    a.bids[p.id] = amount;
  }

  static String? close(GameState s, int now) {
    final a = s.auction;
    if (a == null || now < a.deadline) return null;
    final bids =
        a.bids.entries
            .where(
              (e) =>
                  !s.player(e.key).eliminated &&
                  e.value > 0 &&
                  s.player(e.key).cash >= e.value,
            )
            .toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    String? winner;
    if (bids.isNotEmpty) {
      final highest = bids.first.value;
      final tied = bids.where((b) => b.value == highest).toList();
      final b = tied[s.nextRandom(tied.length)];
      winner = b.key;
      s.player(b.key).cash -= b.value;
      s.property(a.propertyId).owner = b.key;
      s.lastBought = a.propertyId;
      s.bank += b.value * .1;
      s.player(a.trigger).cash += b.value * .05;
      s.record('${s.player(b.key).name} برندهٔ حراج شد');
    } else {
      s.record('حراج بدون خریدار پایان یافت');
    }
    s.auction = null;
    return winner;
  }
}
