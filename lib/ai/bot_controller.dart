// [B01-B10] Bots submit exactly the same commands as human players.
import '../core/models/game_state.dart';
import '../core/data/board_path_data.dart';
import '../core/rules/rent_calculator.dart';
import '../core/rules/credit_system.dart';
import '../core/rules/insurance_engine.dart';
import '../core/rules/turn_manager.dart';

class BotAction {
  final String type;
  final Map<String, dynamic> data;
  const BotAction(this.type, [this.data = const {}]);
}

class BotController {
  static BotAction? decide(GameState s, Player p) {
    final guarantees = s.loans
        .where((l) => l.pending && !l.settled && l.guarantor == p.id)
        .toList();
    if (guarantees.isNotEmpty) {
      final l = guarantees.first;
      return BotAction(
        p.difficulty != Difficulty.easy && p.cash > l.due + reserve(p)
            ? 'acceptGuarantee'
            : 'rejectGuarantee',
        {'loan': l.id},
      );
    }
    final trade = s.trades.where((t) => t['buyer'] == p.id).toList();
    if (trade.isNotEmpty) {
      return BotAction('rejectTrade', {'trade': trade.first['id']});
    }
    final offers = s.contracts
        .where(
          (c) =>
              !c.accepted &&
              !c.broken &&
              c.second == p.id &&
              c.expires > s.round,
        )
        .toList();
    if (offers.isNotEmpty) {
      return BotAction(
        p.difficulty == Difficulty.easy ? 'rejectContract' : 'acceptContract',
        {'contract': offers.first.id},
      );
    }
    final auction = s.auction;
    if (auction != null) {
      if (auction.bids.containsKey(p.id)) return null;
      final q = s.property(auction.propertyId);
      return BotAction('bid', {'amount': bid(s, p, q)});
    }
    final v = s.vote;
    if (v != null) {
      final already = v.stage == 0 ? v.elimination : v.ballots;
      if (already.containsKey(p.id)) return null;
      return BotAction('vote', {
        'law': vote(s, p, v.candidates, v.stage == 0),
        'bank': p.cash < 500
            ? 'split'
            : p.personality == Personality.conservative
            ? 'save'
            : 'loan',
      });
    }
    if (s.active.id != p.id) return null;
    if (s.pendingMove == p.id) {
      final choices = s.properties.where((q) => q.owner == null).toList()
        ..sort((a, b) => b.price.compareTo(a.price));
      final index = choices.isEmpty ? 0 : boardIndex(choices.first.id);
      return BotAction('move', {'index': index});
    }
    if (!s.rolled) {
      if (p.jailTurns > 0 && p.cash > 700 && p.difficulty != Difficulty.easy) {
        return const BotAction('bail');
      }
      return const BotAction('roll');
    }
    final q = TurnManager.landed(s, p);
    if (q != null && q.owner == null && shouldBuy(s, p, q)) {
      return const BotAction('buy');
    }
    for (final l in s.loans.where((l) => l.borrower == p.id && !l.settled)) {
      if (p.cash > l.due + 250) return BotAction('repay', {'loan': l.id});
    }
    if (p.cash < 100 && s.debt(p.id) == 0 && CreditSystem.limit(p.credit) > 0) {
      final own = s.properties.where((q) => q.owner == p.id).toList();
      if (p.credit >= 50 || own.isNotEmpty) {
        return BotAction('loan', {
          'amount': CreditSystem.limit(p.credit),
          'collateral': p.credit < 50 ? own.first.id : null,
        });
      }
    }
    if (p.cash < 0) {
      final own = s.properties.where((q) => q.owner == p.id).toList();
      if (own.isNotEmpty) {
        return BotAction(own.first.buildings > 0 ? 'sellBuilding' : 'sell', {
          'property': own.first.id,
        });
      }
    }
    if (p.difficulty != Difficulty.easy) {
      for (final q in s.properties.where(
        (q) => q.owner == p.id && !q.isPublic,
      )) {
        if (RentCalculator.fullBlock(s, q) &&
            q.buildings < (s.laws.contains('law_07') ? 2 : 3) &&
            p.cash > RentCalculator.buildingPrice(s, q) + reserve(p)) {
          return BotAction('build', {'property': q.id});
        }
      }
      if (!InsuranceEngine.covered(s, p.id) &&
          p.cash > 1200 &&
          p.cash > InsuranceEngine.premium(s, p) + reserve(p)) {
        return const BotAction('insurance');
      }
      final active = s.contracts
          .where((c) => c.includes(p.id) && c.expires > s.round && !c.broken)
          .toList();
      if (active.isEmpty &&
          s.round % 5 == 0 &&
          p.personality != Personality.aggressive) {
        final others = s.alive.where((o) => o.id != p.id).toList()
          ..sort((a, b) => b.cash.compareTo(a.cash));
        if (others.isNotEmpty) {
          return BotAction('contract', {
            'second': others.first.id,
            'kind': p.difficulty == Difficulty.hard
                ? 'rentShare'
                : 'nonAggression',
          });
        }
      }
      if (p.difficulty == Difficulty.hard && p.cash > 1000) {
        final betrays = active
            .where(
              (c) =>
                  c.accepted &&
                  c.kind == ContractKind.rentShare &&
                  s.netWorth(p.id) > s.netWorth(c.other(p.id)) * 2,
            )
            .toList();
        if (betrays.isNotEmpty) {
          return BotAction('breakContract', {'contract': betrays.first.id});
        }
      }
    }
    return const BotAction('end');
  }

  static double reserve(Player p) => switch (p.personality) {
    Personality.conservative => 500,
    Personality.aggressive => 150,
    Personality.balanced => 300,
  };
  static bool shouldBuy(GameState s, Player p, Property q) {
    final cost = RentCalculator.value(s, q) * (p.discount ? 0.5 : 1);
    if (cost > p.cash) return false;
    if (p.difficulty == Difficulty.easy) return s.nextRandom(100) < 60;
    final near =
        q.block != null &&
        s.properties.any((o) => o.block == q.block && o.owner == p.id);
    return p.cash - cost >
            reserve(p) * (near && p.difficulty == Difficulty.hard ? 0.5 : 1) &&
        (near || q.baseRent / q.price >= .055 || q.isPublic);
  }

  static double bid(GameState s, Player p, Property q) {
    final price = RentCalculator.value(s, q);
    final cap = (p.cash - reserve(p)).clamp(0, p.cash);
    if (p.difficulty == Difficulty.easy) {
      return (price * .25).clamp(0, cap).toDouble();
    }
    final near =
        q.block != null &&
        s.properties.any((o) => o.block == q.block && o.owner == p.id);
    final factor = p.difficulty == Difficulty.hard
        ? (near ? 1.6 : 1.05) + s.nextRandom(20) / 100
        : .8;
    return (price * factor).roundToDouble().clamp(0, cap).toDouble();
  }

  static String vote(GameState s, Player p, List<String> ids, bool eliminate) {
    double score(String id) => switch (id) {
      'law_01' => s.properties.where((q) => q.owner == p.id).length * 10.0,
      'law_02' => p.cash > 1000 ? -10 : 10,
      'law_03' => 20,
      'law_04' => p.jailTurns > 0 ? 30 : 0,
      'law_05' => -10,
      'law_06' =>
        s.alive.every((o) => s.netWorth(o.id) >= s.netWorth(p.id)) ? 50 : -10,
      'law_07' => -20,
      'law_08' => -5,
      'law_09' =>
        s.properties.any((q) => q.owner == p.id && q.isPublic) ? 20 : -10,
      'law_10' => 15,
      _ => 0,
    };
    if (p.difficulty == Difficulty.easy) return ids[s.nextRandom(ids.length)];
    final sorted = ids.toList()..sort((a, b) => score(a).compareTo(score(b)));
    return eliminate ? sorted.first : sorted.last;
  }

  static int boardIndex(String id) => boardIndexOf(id);
}
