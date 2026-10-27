// [R23][R24][R26] Loans, breach penalties and policy expiry.
import 'package:flutter_test/flutter_test.dart';
import 'package:bankroll_plato/core/models/game_state.dart';
import 'package:bankroll_plato/core/rules/credit_system.dart';
import 'package:bankroll_plato/core/rules/contract_engine.dart';
import 'package:bankroll_plato/core/rules/insurance_engine.dart';
import 'test_helpers.dart';

void main() {
  test('credit tiers and loan settlement', () {
    expect([19, 20, 49, 50, 79, 80, 100].map(CreditSystem.limit), [
      0,
      200,
      200,
      500,
      500,
      1000,
      1000,
    ]);
    final s = fixture(), p = s.active;
    final initial = p.cash;
    CreditSystem.borrow(s, p, 500);
    expect(s.loans.single.due, 575);
    expect(s.loans.single.dueRound, 6);
    CreditSystem.repay(s, p, s.loans.single.id);
    expect(p.cash, initial - 75);
    expect(p.credit, 72);
  });
  test('default collateral and breach penalties', () {
    final s = fixture(), p = s.active;
    p.credit = 30;
    final q = s.properties.first;
    q.owner = p.id;
    CreditSystem.borrow(s, p, 200, collateral: q.id);
    p.cash = 0;
    s.round = 6;
    CreditSystem.mature(s);
    expect(p.credit, 10);
    expect(q.owner, null);
    expect(s.loans.single.defaulted, true);
    final c = ContractEngine.sign(
      s,
      p,
      s.players.last.id,
      ContractKind.nonAggression,
    );
    c.accepted = true;
    final cash = p.cash;
    ContractEngine.breakContract(s, p, c.id);
    expect(p.cash, cash - 400);
    expect(p.credit, 0);
  });
  test('insurance cap and expiry', () {
    final s = fixture(), p = s.active;
    InsuranceEngine.buy(s, p);
    InsuranceEngine.buy(s, p);
    expect(() => InsuranceEngine.buy(s, p), throwsStateError);
    expect(InsuranceEngine.covered(s, p.id), true);
    s.round = 4;
    expect(InsuranceEngine.covered(s, p.id), false);
  });
}
