// [R24] Loans, collateral, guarantees and settlement.
import '../models/game_state.dart';
import 'phase_engine.dart';

class CreditSystem {
  static int limit(int credit) => credit >= 80
      ? 1000
      : credit >= 50
      ? 500
      : credit >= 20
      ? 200
      : 0;
  static void borrow(
    GameState s,
    Player p,
    double amount, {
    String? guarantor,
    String? collateral,
  }) {
    if (!amount.isFinite ||
        amount <= 0 ||
        amount > limit(p.credit) ||
        s.loans.any((l) => l.borrower == p.id && !l.settled)) {
      throw StateError('مبلغ وام یا اعتبار مجاز نیست');
    }
    if (guarantor != null &&
        (guarantor == p.id || s.player(guarantor).eliminated)) {
      throw StateError('ضامن معتبر نیست');
    }
    if (collateral != null &&
        (s.property(collateral).owner != p.id ||
            s.loans.any((l) => !l.settled && l.collateral == collateral))) {
      throw StateError('وثیقه آزاد نیست');
    }
    if (p.credit < 50 && guarantor == null && collateral == null) {
      throw StateError('این اعتبار به وثیقه یا ضامن نیاز دارد');
    }
    s.loans.add(
      Loan(
        id: 'loan_${s.revision}_${s.loans.length}',
        borrower: p.id,
        principal: amount,
        due: amount * (1 + PhaseEngine.interest(s.phase)),
        dueRound: s.round + 5,
        guarantor: guarantor,
        collateral: collateral,
        pending: guarantor != null,
      ),
    );
    if (guarantor == null) {
      p.cash += amount;
      s.record('${p.name} وام گرفت');
    } else {
      s.record('${p.name} درخواست ضمانت فرستاد');
    }
  }

  static void guarantee(GameState s, Player guarantor, String id, bool accept) {
    final loan = s.loans.firstWhere(
      (l) =>
          l.id == id && l.guarantor == guarantor.id && l.pending && !l.settled,
    );
    final borrower = s.player(loan.borrower);
    if (!accept) {
      loan.settled = true;
      loan.pending = false;
      return;
    }
    if (borrower.eliminated || loan.principal > limit(borrower.credit)) {
      throw StateError('درخواست وام دیگر معتبر نیست');
    }
    loan.pending = false;
    borrower.cash += loan.principal;
    s.record('${guarantor.name} ضمانت وام را پذیرفت');
  }

  static void repay(GameState s, Player p, String id) {
    final l = s.loans.firstWhere(
      (l) => l.id == id && l.borrower == p.id && !l.settled && !l.pending,
    );
    if (p.cash < l.due) throw StateError('نقد کافی نیست');
    p.cash -= l.due;
    l.settled = true;
    p.credit = (p.credit + 2).clamp(0, 100);
    s.record('${p.name} وام را تسویه کرد');
  }

  static void mature(GameState s) {
    for (final l in s.loans.where((l) => !l.settled && l.dueRound <= s.round)) {
      if (l.pending) {
        l.pending = false;
        l.settled = true;
        continue;
      }
      final p = s.player(l.borrower);
      if (p.cash >= l.due) {
        repay(s, p, l.id);
        continue;
      }
      l.defaulted = true;
      l.settled = true;
      p.credit = (p.credit - 20).clamp(0, 100);
      double left = l.due;
      if (l.collateral != null) {
        final q = s.property(l.collateral!);
        if (q.owner == p.id) {
          q.owner = null;
          q.buildings = 0;
          left = (left - q.price).clamp(0, l.due);
        }
      }
      if (l.guarantor != null) {
        final g = s.player(l.guarantor!);
        g.cash -= left;
      } else {
        p.cash -= left;
      }
      s.record('${p.name} نکول کرد؛ اعتبار ۲۰ واحد کم شد');
    }
  }
}
