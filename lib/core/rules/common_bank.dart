// [R07][R21] Majority decisions; tied results retain the reserve.
import '../models/game_state.dart';

class CommonBank {
  static BankChoice majority(Iterable<String> ballots, int eligible) {
    final counts = <String, int>{};
    for (final b in ballots) {
      counts[b] = (counts[b] ?? 0) + 1;
    }
    for (final e in counts.entries) {
      if (e.value > eligible / 2) {
        return BankChoice.values.firstWhere(
          (v) => v.name == e.key,
          orElse: () => BankChoice.save,
        );
      }
    }
    return BankChoice.save;
  }

  static void apply(GameState s, BankChoice choice) {
    if (s.alive.isEmpty || choice == BankChoice.save) return;
    final share = s.bank / s.alive.length;
    for (final p in s.alive) {
      p.cash += share;
      if (choice == BankChoice.loan) {
        s.loans.add(
          Loan(
            id: 'group_${s.round}_${p.id}',
            borrower: p.id,
            principal: share,
            due: share,
            dueRound: s.round + 5,
          ),
        );
      }
    }
    s.bank = 0;
    s.record(
      choice == BankChoice.split
          ? 'بانک بین بازیکنان تقسیم شد'
          : 'وام گروهی پرداخت شد',
    );
  }
}
