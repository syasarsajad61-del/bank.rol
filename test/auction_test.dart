// [R20] Hidden bids, deadline, solvency and payout conservation.
import 'package:flutter_test/flutter_test.dart';
import 'package:bankroll_plato/core/rules/auction_engine.dart';
import 'test_helpers.dart';

void main() {
  test('auction settles only after deadline with 10 and 5 percent', () {
    final s = fixture(), p = s.players[0], trigger = s.players[1];
    final cash = p.cash, t = trigger.cash, bank = s.bank;
    AuctionEngine.start(s, s.properties.first.id, trigger.id, 100);
    AuctionEngine.bid(s, p, 200, 101);
    expect(s.auction!.toJson(private: false).containsKey('bids'), false);
    expect(AuctionEngine.close(s, 10099), null);
    AuctionEngine.close(s, 10100);
    expect(s.properties.first.owner, p.id);
    expect(p.cash, cash - 200);
    expect(trigger.cash, t + 10);
    expect(s.bank, bank + 20);
  });
  test('reject late negative and overbudget bids', () {
    final s = fixture();
    AuctionEngine.start(s, s.properties.first.id, s.active.id, 0);
    for (final amount in [-1.0, 100000.0, double.nan]) {
      expect(() => AuctionEngine.bid(s, s.active, amount, 1), throwsStateError);
    }
    expect(() => AuctionEngine.bid(s, s.active, 1, 10000), throwsStateError);
  });
}
