// [R01-R27][B10][M01] Single action API for humans, bots and network clients.
import '../models/game_state.dart';
import '../data/properties_data.dart';
import 'phase_engine.dart';
import 'rent_calculator.dart';
import 'dice_engine.dart';
import 'jail_engine.dart';
import 'chance_engine.dart';
import 'auction_engine.dart';
import 'law_engine.dart';
import 'credit_system.dart';
import 'contract_engine.dart';
import 'insurance_engine.dart';
import 'bankruptcy.dart';
import 'trade_engine.dart';

class TurnManager {
  static GameState create(
    List<Player> players, {
    int target = 5000,
    int rounds = 30,
    int seed = 42,
  }) {
    if (players.length < 2 ||
        players.length > 6 ||
        !{3000, 5000, 7000}.contains(target) ||
        !{0, 30, 50}.contains(rounds)) {
      throw ArgumentError('تنظیمات بازی معتبر نیست');
    }
    final s = GameState(
      players: players,
      properties: [
        for (final p in CITY_PROPERTIES)
          Property(
            id: p.id,
            name: p.name,
            price: p.price,
            baseRent: p.baseRent,
            buildingCost: p.buildingCost,
            block: p.block,
          ),
        for (final p in PUBLIC_PROPERTIES)
          Property(
            id: p.id,
            name: p.name,
            price: p.price,
            baseRent: p.baseRent,
          ),
      ],
      target: target,
      roundLimit: rounds,
      rng: seed,
    );
    for (int i = 0; i < players.length; i++) {
      players[i].cash = 1500.0 + i * 100;
    }
    for (int i = players.length - 1; i > 0; i--) {
      final j = s.nextRandom(i + 1), p = players[i];
      players[i] = players[j];
      players[j] = p;
    }
    s.initialMoney = players.fold<double>(300, (v, p) => v + p.cash);
    s.record('به محله‌های زاهدان خوش آمدید');
    return s;
  }

  static void apply(
    GameState s,
    String actor,
    String type,
    Map<String, dynamic> data,
    int now,
  ) {
    if (s.ended) throw StateError('بازی تمام شده است');
    final p = s.player(actor);
    if (p.eliminated) throw StateError('بازیکن حذف شده است');
    final concurrent = {
      'bid',
      'vote',
      'acceptContract',
      'rejectContract',
      'acceptGuarantee',
      'rejectGuarantee',
      'acceptTrade',
      'rejectTrade',
    };
    if (!concurrent.contains(type) &&
        (s.active.id != actor || s.auction != null || s.vote != null)) {
      throw StateError('اکنون نوبت این عمل نیست');
    }
    switch (type) {
      case 'roll':
        roll(s, p);
      case 'end':
        if (!s.rolled || s.pendingMove != null) {
          throw StateError('ابتدا حرکت را کامل کنید');
        }
        if (s.extraRoll) {
          s.rolled = false;
          s.extraRoll = false;
        } else {
          advance(s, now);
        }
      case 'buy':
        buy(s, p);
      case 'auction':
        final q = landed(s, p);
        if (q == null || q.owner != null || !s.rolled) {
          throw StateError('ملک آزاد زیر مهره نیست');
        }
        AuctionEngine.start(s, q.id, p.id, now);
      case 'build':
        final q = owned(s, p, data['property']);
        if (q.isPublic ||
            !RentCalculator.fullBlock(s, q) ||
            q.buildings >= (s.laws.contains('law_07') ? 2 : 3)) {
          throw StateError('بلوک کامل یا ظرفیت ساخت ندارید');
        }
        final cost = RentCalculator.buildingPrice(s, q);
        pay(p, cost);
        q.buildings++;
        s.record('${p.name} در ${q.name} ساخت‌وساز کرد');
      case 'sellBuilding':
        final q = owned(s, p, data['property']);
        if (q.buildings == 0) throw StateError('ساختمانی وجود ندارد');
        q.buildings--;
        p.cash += RentCalculator.buildingPrice(s, q) * .6;
      case 'sell':
        final q = owned(s, p, data['property']);
        if (s.loans.any((l) => !l.settled && l.collateral == q.id)) {
          throw StateError('ملک در وثیقه است');
        }
        p.cash +=
            RentCalculator.value(s, q) * .8 +
            q.buildings * RentCalculator.buildingPrice(s, q) * .6;
        q.owner = null;
        q.buildings = 0;
        s.record('${p.name} ملک فروخت');
      case 'insurance':
        InsuranceEngine.buy(s, p);
      case 'loan':
        CreditSystem.borrow(
          s,
          p,
          (data['amount'] as num).toDouble(),
          guarantor: data['guarantor'],
          collateral: data['collateral'],
        );
      case 'repay':
        CreditSystem.repay(s, p, data['loan']);
      case 'acceptGuarantee':
        CreditSystem.guarantee(s, p, data['loan'], true);
      case 'rejectGuarantee':
        CreditSystem.guarantee(s, p, data['loan'], false);
      case 'trade':
        TradeEngine.offer(
          s,
          p,
          data['buyer'],
          data['property'],
          (data['price'] as num).toDouble(),
          requested: data['requested'],
        );
      case 'acceptTrade':
        TradeEngine.accept(s, p, data['trade']);
      case 'rejectTrade':
        s.trades.removeWhere(
          (t) => t['id'] == data['trade'] && t['buyer'] == p.id,
        );
      case 'bail':
        JailEngine.bail(s, p);
      case 'bid':
        AuctionEngine.bid(s, p, (data['amount'] as num).toDouble(), now);
      case 'vote':
        LawEngine.cast(s, p, data['law'], data['bank'] ?? 'save', now);
      case 'contract':
        ContractEngine.sign(
          s,
          p,
          data['second'],
          ContractKind.values.byName(data['kind']),
        );
      case 'acceptContract':
        final c = s.contracts.firstWhere(
          (c) =>
              c.id == data['contract'] &&
              c.second == actor &&
              !c.broken &&
              c.expires > s.round,
        );
        c.accepted = true;
      case 'rejectContract':
        final c = s.contracts.firstWhere(
          (c) => c.id == data['contract'] && c.second == actor && !c.accepted,
        );
        s.contracts.remove(c);
      case 'breakContract':
        ContractEngine.breakContract(s, p, data['contract']);
      case 'move':
        if (s.pendingMove != actor ||
            data['index'] is! int ||
            (data['index'] as int) < 0 ||
            (data['index'] as int) >= 32) {
          throw StateError('مقصد مجاز نیست');
        }
        p.position = data['index'];
        s.pendingMove = null;
        resolve(s, p, allowChance: false);
      default:
        throw StateError('فرمان ناشناخته');
    }
    s.revision++;
    Bankruptcy.check(s);
    finish(s);
  }

  static void pay(Player p, double amount) {
    if (p.cash < amount) throw StateError('نقد کافی نیست');
    p.cash -= amount;
  }

  static Property owned(GameState s, Player p, String id) {
    final q = s.property(id);
    if (q.owner != p.id) throw StateError('این ملک متعلق به شما نیست');
    return q;
  }

  static Property? landed(GameState s, Player p) {
    final id = BOARD[p.position].propertyId;
    return id == null ? null : s.property(id);
  }

  static void buy(GameState s, Player p) {
    final q = landed(s, p);
    if (!s.rolled || q == null || q.owner != null) {
      throw StateError('خرید این خانه مجاز نیست');
    }
    final price = RentCalculator.value(s, q) * (p.discount ? 0.5 : 1);
    pay(p, price);
    q.owner = p.id;
    p.discount = false;
    s.lastBought = q.id;
    s.record('${p.name} ${q.name} را خرید');
  }

  static void roll(GameState s, Player p) {
    if (s.rolled) throw StateError('تاس قبلاً ریخته شده است');
    s.rolled = true;
    p.inactiveTurns = 0;
    s.lastChance = null;
    if (p.jailTurns > 0) {
      p.jailTurns--;
      s.lastDice = 0;
      s.record('${p.name} یک نوبت در زندان ماند');
      return;
    }
    final dice = DiceEngine.roll(s);
    s.lastDice = dice;
    if (dice == 6) {
      p.sixes++;
      if (p.sixes == 3) {
        JailEngine.send(s, p);
        return;
      }
      s.extraRoll = true;
    } else {
      p.sixes = 0;
      s.extraRoll = false;
    }
    final end = p.position + dice;
    if (end >= 32) {
      p.cash += s.laws.contains('law_03') ? 250 : PhaseEngine.salary(s.phase);
    }
    p.position = end % 32;
    s.record('${p.name} تاس $dice آورد');
    resolve(s, p);
  }

  static void resolve(GameState s, Player p, {bool allowChance = true}) {
    final space = BOARD[p.position];
    switch (space.type) {
      case BoardSpaceType.city:
      case BoardSpaceType.publicProperty:
        final q = s.property(space.propertyId!);
        if (q.owner != null && q.owner != p.id) {
          final owner = s.player(q.owner!);
          final rent = ContractEngine.adjustRent(
            s,
            p,
            owner,
            RentCalculator.of(s, q, p),
          );
          p.cash -= rent;
          owner.cash += rent;
          ContractEngine.share(s, owner, rent);
          if (rent > 300 && s.laws.contains('law_02')) {
            owner.cash -= rent * .1;
            s.bank += rent * .1;
          }
          s.record('${p.name} ${rent.round()} دلار اجاره پرداخت');
        }
      case BoardSpaceType.chance:
        if (allowChance) {
          final previous = p.position;
          ChanceEngine.draw(s, p);
          if (p.position != previous &&
              BOARD[p.position].type != BoardSpaceType.chance) {
            resolve(s, p, allowChance: false);
          }
        }
      case BoardSpaceType.tax:
        final fee = space.taxAmount!.toDouble();
        p.cash -= fee;
        s.bank += fee;
      case BoardSpaceType.goToJail:
        JailEngine.send(s, p);
      case BoardSpaceType.freeParking:
        p.cash += space.bonusAmount ?? 0;
      case BoardSpaceType.bankPool:
        final bonus = s.bank.clamp(0, 100);
        s.bank -= bonus;
        p.cash += bonus;
      case BoardSpaceType.auction:
        final free = s.properties.where((q) => q.owner == null).toList();
        if (free.isNotEmpty) {
          AuctionEngine.start(
            s,
            free[s.nextRandom(free.length)].id,
            p.id,
            DateTime.now().millisecondsSinceEpoch,
          );
        }
      case BoardSpaceType.start:
      case BoardSpaceType.jail:
        break;
    }
  }

  static void advance(GameState s, int now) {
    s.rolled = false;
    s.extraRoll = false;
    s.active.sixes = 0;
    int next = s.turn;
    do {
      next = (next + 1) % s.players.length;
      if (next == 0) {
        s.round++;
        s.policies.removeWhere((p) => p.expires <= s.round);
        s.trades.removeWhere((t) => (t['expires'] as int) <= s.round);
        CreditSystem.mature(s);
        if ((s.round - 1) % 4 == 0) {
          s.phase = PhaseEngine.next(s.phase, s.nextRandom(100));
          s.record('فاز اقتصاد: ${PhaseEngine.label(s.phase)}');
          LawEngine.start(s, now);
        }
      }
    } while (s.players[next].eliminated && next != s.turn);
    s.turn = next;
  }

  static void timeout(GameState s, int now) {
    if (s.ended) return;
    s.active.inactiveTurns++;
    s.record('${s.active.name} نوبت را از دست داد');
    Bankruptcy.check(s);
    advance(s, now);
    s.revision++;
    finish(s);
  }

  static void tick(GameState s, int now) {
    final before = s.auction;
    if (before != null && now >= before.deadline) {
      AuctionEngine.close(s, now);
      s.revision++;
    }
    final vote = s.vote;
    if (vote != null) {
      final stage = vote.stage;
      LawEngine.advance(s, now);
      if (s.vote == null || s.vote!.stage != stage) s.revision++;
    }
    Bankruptcy.check(s);
    finish(s);
  }

  static void finish(GameState s) {
    if (s.ended) return;
    final alive = s.alive;
    final target = alive.where((p) => s.netWorth(p.id) >= s.target).toList();
    if (alive.length <= 1 ||
        target.isNotEmpty ||
        (s.roundLimit > 0 && s.round > s.roundLimit)) {
      final ranked = alive.toList()
        ..sort((a, b) => s.netWorth(b.id).compareTo(s.netWorth(a.id)));
      s.winner = ranked.isEmpty ? null : ranked.first.id;
      s.ended = true;
      s.record('بازی پایان یافت');
    }
  }
}
