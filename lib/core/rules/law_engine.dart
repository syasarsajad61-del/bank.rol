// [R25] Three candidates, eliminate one, then majority approval.
import '../models/game_state.dart';
import '../data/laws_data.dart';
import 'common_bank.dart';

class LawEngine {
  static void start(GameState s, int now) {
    final pool = LAWS.map((l) => l.id).toList();
    final candidates = <String>[];
    while (candidates.length < 3) {
      candidates.add(pool.removeAt(s.nextRandom(pool.length)));
    }
    s.vote = Vote(candidates, now + 15000);
  }

  static void cast(GameState s, Player p, String law, String bank, int now) {
    final v = s.vote;
    if (v == null || now >= v.deadline || !v.candidates.contains(law)) {
      throw StateError('رأی مجاز نیست');
    }
    if (v.stage == 0) {
      v.elimination[p.id] = law;
    } else {
      v.ballots[p.id] = law;
      if (!BankChoice.values.any((b) => b.name == bank)) {
        throw StateError('رأی بانک نامعتبر');
      }
      v.bankBallots[p.id] = bank;
    }
  }

  static void advance(GameState s, int now) {
    final v = s.vote;
    if (v == null) return;
    final ballots = v.stage == 0 ? v.elimination : v.ballots;
    if (now < v.deadline && ballots.length < s.alive.length) return;
    if (v.stage == 0) {
      final counts = {
        for (final c in v.candidates)
          c: v.elimination.values.where((b) => b == c).length,
      };
      final sorted = v.candidates.toList()
        ..sort((a, b) => counts[b]!.compareTo(counts[a]!));
      v.candidates.remove(sorted.first);
      v.stage = 1;
      v.deadline = now + 15000;
      return;
    }
    String? approved;
    for (final id in v.candidates) {
      if (v.ballots.values.where((b) => b == id).length > s.alive.length / 2) {
        approved = id;
      }
    }
    if (approved != null) {
      s.laws
        ..clear()
        ..add(approved);
      s.record(
        'قانون تصویب شد: ${LAWS.firstWhere((l) => l.id == approved).title}',
      );
      if (approved == 'law_06') {
        final poor = s.alive.toList()
          ..sort((a, b) => s.netWorth(a.id).compareTo(s.netWorth(b.id)));
        poor.first.cash += 300;
      }
    } else {
      s.record('رأی قانون به اکثریت نرسید');
    }
    CommonBank.apply(
      s,
      CommonBank.majority(v.bankBallots.values, s.alive.length),
    );
    s.vote = null;
  }
}
