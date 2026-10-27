// [R25] Consensual property swaps make trade taxation executable.
import '../models/game_state.dart';
import 'rent_calculator.dart';

class TradeEngine {
  static void validate(GameState s, Property q, String owner) {
    if (q.owner != owner ||
        q.buildings > 0 ||
        s.loans.any((l) => !l.settled && l.collateral == q.id)) {
      throw StateError(
        'ملک باید متعلق به شما، بدون ساختمان و آزاد از وثیقه باشد',
      );
    }
  }

  static void offer(
    GameState s,
    Player seller,
    String buyer,
    String property,
    double price, {
    String? requested,
  }) {
    final other = s.player(buyer);
    if (other.id == seller.id ||
        other.eliminated ||
        !price.isFinite ||
        price < 0) {
      throw StateError('پیشنهاد معاوضه معتبر نیست');
    }
    validate(s, s.property(property), seller.id);
    if (requested != null) validate(s, s.property(requested), buyer);
    s.trades.removeWhere(
      (t) => t['seller'] == seller.id && t['property'] == property,
    );
    s.trades.add({
      'id': 'trade_${s.revision}',
      'seller': seller.id,
      'buyer': buyer,
      'property': property,
      'requested': requested,
      'price': price,
      'expires': s.round + 2,
    });
  }

  static void accept(GameState s, Player buyer, String id) {
    final t = s.trades.firstWhere(
      (t) =>
          t['id'] == id &&
          t['buyer'] == buyer.id &&
          (t['expires'] as int) > s.round,
    );
    final seller = s.player(t['seller']);
    if (seller.eliminated) throw StateError('فروشنده حذف شده است');
    final q = s.property(t['property']);
    validate(s, q, seller.id);
    final other = t['requested'] == null ? null : s.property(t['requested']);
    if (other != null) validate(s, other, buyer.id);
    final price = (t['price'] as num).toDouble();
    final tax = s.laws.contains('law_08')
        ? (RentCalculator.value(s, q) +
                  (other == null ? 0 : RentCalculator.value(s, other)) +
                  price) *
              .05
        : 0.0;
    if (buyer.cash < price + tax) {
      throw StateError('نقد کافی برای معاوضه و مالیات ندارید');
    }
    buyer.cash -= price + tax;
    seller.cash += price;
    s.bank += tax;
    q.owner = buyer.id;
    if (other != null) other.owner = seller.id;
    s.trades.remove(t);
    s.record('${buyer.name} و ${seller.name} معامله کردند');
  }
}
