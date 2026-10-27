// [R21][R25][T07] Majority, two stages and tied ballots.
import 'package:flutter_test/flutter_test.dart';
import 'package:bankroll_plato/core/models/game_state.dart';
import 'package:bankroll_plato/core/rules/common_bank.dart';
import 'package:bankroll_plato/core/rules/law_engine.dart';
import 'test_helpers.dart';

void main() {
  test('bank tie saves reserve and group loan has a five round maturity', () {
    final s = fixture();
    expect(CommonBank.majority(['split', 'loan', 'save'], 3), BankChoice.save);
    final before = {for (final p in s.alive) p.id: p.cash};
    CommonBank.apply(s, BankChoice.loan);
    expect(s.bank, 0);
    expect(s.loans.length, 3);
    for (final p in s.alive) {
      expect(p.cash, before[p.id]! + 100);
      final loan = s.loans.firstWhere((l) => l.borrower == p.id);
      expect(loan.dueRound, s.round + 5);
      expect(loan.due, 100);
    }
  });
  test('three candidates reduce to two and majority passes a law', () {
    final s = fixture();
    LawEngine.start(s, 1000);
    final removed = s.vote!.candidates.first;
    for (final p in s.alive) {
      LawEngine.cast(s, p, removed, 'save', 1001);
    }
    LawEngine.advance(s, 1002);
    expect(s.vote!.stage, 1);
    expect(s.vote!.candidates.length, 2);
    expect(s.vote!.candidates, isNot(contains(removed)));
    final winner = s.vote!.candidates.first;
    for (final p in s.alive) {
      LawEngine.cast(s, p, winner, 'split', 1003);
    }
    LawEngine.advance(s, 1004);
    expect(s.vote, isNull);
    expect(s.laws, {winner});
    expect(s.bank, 0);
  });
  test('final tie leaves laws and reserve unchanged', () {
    final s = fixture(count: 2);
    LawEngine.start(s, 1000);
    LawEngine.advance(s, 16000);
    final choices = s.vote!.candidates.toList();
    LawEngine.cast(s, s.players[0], choices[0], 'split', 16001);
    LawEngine.cast(s, s.players[1], choices[1], 'save', 16001);
    LawEngine.advance(s, 16002);
    expect(s.vote, isNull);
    expect(s.laws, isEmpty);
    expect(s.bank, 300);
  });
}
