import 'package:flutter_test/flutter_test.dart';
import 'package:bankroll_plato/core/models/game_state.dart';
import 'package:bankroll_plato/core/rules/credit_system.dart';
import 'package:bankroll_plato/core/rules/trade_engine.dart';
import 'package:bankroll_plato/core/rules/contract_engine.dart';
import 'package:bankroll_plato/core/rules/rent_calculator.dart';
import 'package:bankroll_plato/network/snapshot.dart';
import 'test_helpers.dart';

void main() {
  test('guarantor consent precedes disbursement and rejection cancels', () {
    final s = fixture(), borrower = s.player('p0'), guarantor = s.player('p1');
    final cash = borrower.cash;
    CreditSystem.borrow(s, borrower, 200, guarantor: guarantor.id);
    expect(borrower.cash, cash);
    expect(s.loans.single.pending, isTrue);
    CreditSystem.guarantee(s, guarantor, s.loans.single.id, false);
    expect(borrower.cash, cash);
    CreditSystem.borrow(s, borrower, 200, guarantor: guarantor.id);
    CreditSystem.guarantee(s, guarantor, s.loans.last.id, true);
    expect(borrower.cash, cash + 200);
    expect(Snapshot.decode(Snapshot.encode(s)).loans.last.pending, isFalse);
  });
  test('trade transfers only on acceptance and applies law 08 tax', () {
    final s = fixture(), seller = s.player('p0'), buyer = s.player('p1');
    final q = s.properties.first..owner = seller.id;
    s.laws.add('law_08');
    final sellerCash = seller.cash, buyerCash = buyer.cash, bank = s.bank;
    TradeEngine.offer(s, seller, buyer.id, q.id, 100);
    expect(q.owner, seller.id);
    final tax = (RentCalculator.value(s, q) + 100) * .05;
    TradeEngine.accept(s, buyer, s.trades.single['id']);
    expect(q.owner, buyer.id);
    expect(seller.cash, sellerCash + 100);
    expect(buyer.cash, closeTo(buyerCash - 100 - tax, .001));
    expect(s.bank, closeTo(bank + tax, .001));
    expect(s.trades, isEmpty);
  });
  test('informant reveals partner bid only after acceptance', () {
    final s = fixture();
    s.auction = Auction(s.properties.first.id, 'p2', 10000);
    s.auction!.bids.addAll({'p1': 240, 'p2': 390});
    final c = ContractEngine.sign(
      s,
      s.player('p0'),
      'p1',
      ContractKind.informant,
    );
    expect(
      Snapshot.decode(Snapshot.encode(s, viewer: 'p0')).auction!.bids,
      isEmpty,
    );
    c.accepted = true;
    expect(Snapshot.decode(Snapshot.encode(s, viewer: 'p0')).auction!.bids, {
      'p1': 240.0,
    });
    expect(Snapshot.decode(Snapshot.encode(s, viewer: 'p2')).auction!.bids, {
      'p2': 390.0,
    });
  });
}
