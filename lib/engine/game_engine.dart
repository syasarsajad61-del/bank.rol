import 'dart:math';

import '../models/action_request.dart';
import '../models/card_model.dart';
import '../models/game_state.dart';
import '../models/player_model.dart';
import '../models/tile_model.dart';

/// Thrown when a client asks for something the rules do not allow.
/// The host catches this and replies with an error toast.
class GameRuleException implements Exception {
  GameRuleException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Pure, host-side rules engine. Every function takes the current
/// [GameState] plus a validated intent and returns a brand new state.
///
/// Clients never call into this class: they only send [ActionRequest]s.
class GameEngine {
  GameEngine._();

  static Random random = Random();

  static const int _boardSize = 40;
  static const int jailIndex = 10;
  static const int jailFine = 150;
  static const int maxJailTurns = 3;

  // ---------------------------------------------------------------- roster

  static GameState addPlayer(
    GameState state, {
    required String id,
    required String name,
    bool isHost = false,
  }) {
    if (state.players.length >= GameState.maxPlayers) {
      throw GameRuleException('اتاق پر است؛ حداکثر ۶ بازیکن مجاز است.');
    }
    if (state.phase != GamePhase.lobby) {
      throw GameRuleException('بازی شروع شده است؛ ورود بازیکن جدید ممکن نیست.');
    }
    final Set<int> used = state.players
        .map((PlayerModel p) => p.colorIndex)
        .toSet();
    int color = 0;
    while (used.contains(color) && color < PlayerPalette.colors.length) {
      color++;
    }
    final String safeName = name.trim().isEmpty ? 'بازیکن' : name.trim();
    final PlayerModel fresh = PlayerModel(
      id: id,
      name: safeName,
      colorIndex: color,
      isHost: isHost,
      connected: true,
    );
    return state
        .copyWith(players: <PlayerModel>[...state.players, fresh])
        .logLine('«$safeName» به اتاق پیوست.')
        .bumpRevision();
  }

  static GameState setConnected(GameState state, String playerId, bool value) {
    final PlayerModel? player = state.playerById(playerId);
    if (player == null) {
      return state;
    }
    if (player.connected == value) {
      return state;
    }
    return state
        .withPlayer(player.copyWith(connected: value))
        .logLine(value
            ? '«${player.name}» دوباره متصل شد.'
            : '«${player.name}» قطع شد.')
        .bumpRevision();
  }

  static GameState removePlayer(GameState state, String playerId) {
    final PlayerModel? player = state.playerById(playerId);
    if (player == null) {
      return state;
    }
    final List<PlayerModel> remaining = state.players
        .where((PlayerModel p) => p.id != playerId)
        .toList(growable: false);
    int index = state.currentPlayerIndex;
    if (index >= remaining.length) {
      index = 0;
    }
    return state
        .copyWith(players: remaining, currentPlayerIndex: index)
        .logLine('«${player.name}» از اتاق خارج شد.')
        .bumpRevision();
  }

  static GameState renamePlayer(GameState state, String playerId, String name) {
    final PlayerModel? player = state.playerById(playerId);
    if (player == null || name.trim().isEmpty) {
      return state;
    }
    return state.withPlayer(player.copyWith(name: name.trim())).bumpRevision();
  }

  // ------------------------------------------------------------ lifecycle

  static GameState startGame(GameState state) {
    if (state.phase == GamePhase.playing) {
      throw GameRuleException('بازی در جریان است.');
    }
    if (state.players.length < 2) {
      throw GameRuleException('برای شروع بازی حداقل دو بازیکن لازم است.');
    }
    final List<PlayerModel> reset = state.players
        .map((PlayerModel p) => PlayerModel(
              id: p.id,
              name: p.name,
              colorIndex: p.colorIndex,
              isHost: p.isHost,
              connected: p.connected,
              cash: PlayerModel.startingCash,
              position: 0,
              getOutOfJailCards: 0,
            ))
        .toList(growable: false);
    final GameState started = GameState(
      phase: GamePhase.playing,
      players: reset,
      currentPlayerIndex: 0,
      round: 1,
      diceA: 1,
      diceB: 1,
      hasRolled: false,
      rollCount: 0,
      parkingPot: 0,
      revision: state.revision + 1,
      maxRounds: state.maxRounds,
      log: <String>[
        'بازی «نئون بانکرول» آغاز شد.',
        'هر بازیکن با ${_money(PlayerModel.startingCash)} شروع می‌کند.',
      ],
    );
    return _demoteDisconnected(started);
  }

  static GameState rematch(GameState state) => startGame(state);

  /// Freeze the match whenever a human device drops off the socket.
  static GameState pauseFor(GameState state, String playerId) {
    if (state.phase != GamePhase.playing) {
      return state;
    }
    final PlayerModel? player = state.playerById(playerId);
    if (player == null) {
      return state;
    }
    return state
        .copyWith(phase: GamePhase.paused, pausedForId: playerId)
        .logLine('بازی متوقف شد؛ در انتظار بازگشت «${player.name}».')
        .bumpRevision();
  }

  static GameState resumeFromPause(GameState state) {
    if (state.phase != GamePhase.paused) {
      return state;
    }
    return state
        .copyWith(phase: GamePhase.playing, clearPausedFor: true)
        .logLine('اتصال برقرار شد؛ بازی ادامه می‌یابد.')
        .bumpRevision();
  }

  static GameState _demoteDisconnected(GameState state) {
    final PlayerModel? current = state.currentPlayer;
    if (current == null || current.connected) {
      return state;
    }
    final int next = _nextActiveIndex(state, state.currentPlayerIndex);
    return state.copyWith(currentPlayerIndex: next);
  }

  // -------------------------------------------------------------- dispatch

  static GameState apply(GameState state, ActionRequest action) {
    switch (action.type) {
      case ActionType.startGame:
        return startGame(state);
      case ActionType.rematch:
        return rematch(state);
      case ActionType.rollDice:
        return rollDice(state, action.playerId);
      case ActionType.buyProperty:
        return buyProperty(state, action.playerId);
      case ActionType.declinePurchase:
        return declinePurchase(state, action.playerId);
      case ActionType.placeBid:
        return placeBid(state, action.playerId, action.intOf('amount'));
      case ActionType.passBid:
        return passBid(state, action.playerId);
      case ActionType.upgradeProperty:
        return upgradeProperty(state, action.playerId, action.intOf('tileIndex'));
      case ActionType.mortgageProperty:
        return mortgageProperty(
            state, action.playerId, action.intOf('tileIndex'));
      case ActionType.unmortgageProperty:
        return unmortgageProperty(
            state, action.playerId, action.intOf('tileIndex'));
      case ActionType.proposeTrade:
        return proposeTrade(
          state,
          action.playerId,
          toId: action.stringOf('toId'),
          offeredTiles: action.intListOf('offeredTiles'),
          requestedTiles: action.intListOf('requestedTiles'),
          offeredCash: action.intOf('offeredCash'),
          requestedCash: action.intOf('requestedCash'),
        );
      case ActionType.respondTrade:
        return respondTrade(state, action.playerId, action.boolOf('accept'));
      case ActionType.withdrawTrade:
        return withdrawTrade(state, action.playerId);
      case ActionType.acknowledgeCard:
        return acknowledgeCard(state, action.playerId);
      case ActionType.endTurn:
        return endTurn(state, action.playerId);
      case ActionType.declareBankrupt:
        return declareBankrupt(state, action.playerId);
      case ActionType.join:
        throw GameRuleException('درخواست ورود باید از طریق سوکت ارسال شود.');
    }
  }

  // ----------------------------------------------------------------- dice

  static GameState rollDice(GameState state, String playerId) {
    if (state.phase != GamePhase.playing) {
      throw GameRuleException('بازی در وضعیت بازی نیست.');
    }
    final PlayerModel? current = state.currentPlayer;
    if (current == null) {
      throw GameRuleException('بازیکن فعال یافت نشد.');
    }
    if (current.id != playerId) {
      throw GameRuleException('نوبت شما نیست.');
    }
    if (state.hasRolled) {
      throw GameRuleException('در این نوبت قبلاً تاس ریخته‌اید.');
    }
    if (state.pendingPurchase != null) {
      throw GameRuleException('ابتدا وضعیت خرید ملک را مشخص کنید.');
    }
    if (state.auction != null) {
      throw GameRuleException('حراج در جریان است.');
    }
    if (state.cardReveal != null) {
      throw GameRuleException('ابتدا کارت را تایید کنید.');
    }
    if (current.cash < 0) {
      throw GameRuleException('ابتدا بدهی خود را تسویه کنید.');
    }

    final int d1 = random.nextInt(6) + 1;
    final int d2 = random.nextInt(6) + 1;
    final int total = d1 + d2;

    GameState next = state.copyWith(
      diceA: d1,
      diceB: d2,
      hasRolled: true,
      rollCount: state.rollCount + 1,
    );

    PlayerModel player = next.playerById(playerId)!;

    if (player.inJail) {
      if (d1 == d2) {
        player = player.copyWith(inJail: false, jailTurns: 0);
        next = next
            .withPlayer(player)
            .logLine('«${player.name}» با دوبل ${_fa(d1)}-${_fa(d2)} آزاد شد.');
        next = _advanceAndResolve(next, playerId, total, 0);
        return next.bumpRevision();
      }
      final int turns = player.jailTurns + 1;
      if (turns >= maxJailTurns) {
        if (player.getOutOfJailCards > 0) {
          player = player.copyWith(
            inJail: false,
            jailTurns: 0,
            getOutOfJailCards: player.getOutOfJailCards - 1,
          );
          next = next
              .withPlayer(player)
              .logLine('«${player.name}» از کارت آزادی استفاده کرد.');
        } else {
          player = player.copyWith(inJail: false, jailTurns: 0, cash: player.cash - jailFine);
          next = next
              .withPlayer(player)
              .logLine('«${player.name}» جریمه ${_money(jailFine)} پرداخت و آزاد شد.');
        }
        next = _advanceAndResolve(next, playerId, total, 0);
        return _settle(next, playerId).bumpRevision();
      }
      next = next
          .withPlayer(player.copyWith(inJail: true, jailTurns: turns))
          .logLine(
              '«${player.name}» دوبل نیاورد؛ در بازداشتگاه ماند (تلاش ${_fa(turns)} از ${_fa(maxJailTurns)}).');
      return next.bumpRevision();
    }

    next = next.logLine(
        '«${player.name}» تاس ریخت: ${_fa(d1)} و ${_fa(d2)} (مجموع ${_fa(total)}).');
    next = _advanceAndResolve(next, playerId, total, 0);
    return _settle(next, playerId).bumpRevision();
  }

  static GameState _advanceAndResolve(
    GameState state,
    String playerId,
    int steps,
    int depth,
  ) {
    GameState next = state;
    PlayerModel player = next.playerById(playerId)!;

    final int raw = player.position + steps;
    int newPos = raw % _boardSize;
    if (newPos < 0) {
      newPos += _boardSize;
    }
    final bool passedGo = steps > 0 && raw >= _boardSize;

    int cash = player.cash;
    if (passedGo) {
      cash += GameState.goBonus;
      next = next.logLine(
          '«${player.name}» از خانه شروع گذشت و ${_money(GameState.goBonus)} گرفت.');
    }
    player = player.copyWith(position: newPos, cash: cash, inJail: false);
    next = next.withPlayer(player);

    if (newPos == jailIndex) {
      next = next.logLine('«${player.name}» فقط برای ملاقات در بازداشتگاه است.');
      return next;
    }
    return _resolveLanding(next, playerId, newPos, depth);
  }

  // ------------------------------------------------------------ landing

  static GameState _resolveLanding(
    GameState state,
    String playerId,
    int tileIndex,
    int depth,
  ) {
    final TileModel tile = TileModel.byIndex(tileIndex);
    GameState next = state;
    PlayerModel player = next.playerById(playerId)!;

    switch (tile.type) {
      case TileType.go:
        return next;

      case TileType.jail:
        return next;

      case TileType.freeParking:
        if (next.parkingPot > 0) {
          final int pot = next.parkingPot;
          player = player.copyWith(cash: player.cash + pot);
          next = next
              .withPlayer(player)
              .copyWith(parkingPot: 0)
              .logLine(
                  '«${player.name}» جایزه پارکینگ ${_money(pot)} را برداشت.');
        }
        return _settle(next, playerId);

      case TileType.goToJail:
        player = player.copyWith(position: jailIndex, inJail: true, jailTurns: 0);
        return next
            .withPlayer(player)
            .logLine('«${player.name}» به بازداشتگاه فرستاده شد.')
            .bumpRevision();

      case TileType.tax:
        final int amount = tile.taxAmount;
        player = player.copyWith(cash: player.cash - amount);
        return next
            .withPlayer(player)
            .copyWith(parkingPot: next.parkingPot + amount)
            .logLine(
                '«${player.name}» ${_money(amount)} ${tile.name} پرداخت کرد.')
            .bumpRevision();

      case TileType.chance:
      case TileType.community:
        if (depth > 0) {
          return next;
        }
        return _drawCard(next, playerId, tile.type);

      case TileType.city:
      case TileType.transport:
      case TileType.utility:
        final String? ownerId = next.ownerIdOf(tileIndex);
        if (ownerId == null) {
          if (player.cash >= tile.price) {
            return next
                .copyWith(
                  pendingPurchase: PendingPurchase(
                    tileIndex: tileIndex,
                    playerId: playerId,
                  ),
                )
                .logLine(
                    '«${player.name}» به «${tile.name}» رسید؛ ملک بدون مالک است.')
                .bumpRevision();
          }
          return next
              .logLine(
                  '«${player.name}» به «${tile.name}» رسید اما پول کافی برای خرید ندارد.')
              .bumpRevision();
        }
        if (ownerId == playerId) {
          return next
              .logLine('«${player.name}» روی ملک خودش ایستاد.')
              .bumpRevision();
        }
        final OwnedProperty owned = next.propertyOf(tileIndex)!;
        if (owned.mortgaged) {
          return next
              .logLine('«${tile.name}» در رهن است؛ اجاره‌ای پرداخت نشد.')
              .bumpRevision();
        }
        final int rent =
            computeRent(next, tile, owned, ownerId, next.diceTotal);
        final PlayerModel owner = next.playerById(ownerId)!;
        player = player.copyWith(cash: player.cash - rent);
        next = next
            .withPlayer(player)
            .withPlayer(owner.copyWith(cash: owner.cash + rent))
            .logLine(
                '«${player.name}» ${_money(rent)} اجاره «${tile.name}» به «${owner.name}» پرداخت کرد.')
            .bumpRevision();
        return _settle(next, playerId);
    }
  }

  static int computeRent(
    GameState state,
    TileModel tile,
    OwnedProperty owned,
    String ownerId,
    int diceTotal,
  ) {
    switch (tile.type) {
      case TileType.city:
        return tile.cityRent(
          owned.level,
          ownsGroup: state.ownsWholeGroup(ownerId, tile.groupId),
        );
      case TileType.transport:
        return tile.transportRent(state.transportCountOf(ownerId));
      case TileType.utility:
        return tile.utilityRent(
          diceTotal <= 0 ? 7 : diceTotal,
          state.utilityCountOf(ownerId),
        );
      default:
        return 0;
    }
  }

  // --------------------------------------------------------------- cards

  static GameState _drawCard(GameState state, String playerId, TileType type) {
    final CardDeck deck =
        type == TileType.chance ? CardDeck.chance : CardDeck.community;
    final List<GameCard> pile = GameCard.deckFor(deck);
    final GameCard card = pile[random.nextInt(pile.length)];
    final PlayerModel? player = state.playerById(playerId);
    if (player == null) {
      return state;
    }

    GameState next = state
        .logLine('«${player.name}» ${deck.labelFa} برداشت: ${card.title}')
        .copyWith(
          cardReveal: CardReveal(cardId: card.id, playerId: playerId, deck: deck),
        );
    next = _applyCardEffect(next, playerId, card, 0);
    return _settle(next, playerId).bumpRevision();
  }

  static GameState _applyCardEffect(
    GameState state,
    String playerId,
    GameCard card,
    int depth,
  ) {
    GameState next = state;
    PlayerModel player = next.playerById(playerId)!;

    switch (card.effect) {
      case CardEffect.collectCash:
        player = player.copyWith(cash: player.cash + card.amount);
        return next
            .withPlayer(player)
            .logLine(
                '«${player.name}» ${_money(card.amount)} دریافت کرد.');

      case CardEffect.payCash:
        player = player.copyWith(cash: player.cash - card.amount);
        return next
            .withPlayer(player)
            .copyWith(parkingPot: next.parkingPot + card.amount)
            .logLine('«${player.name}» ${_money(card.amount)} پرداخت کرد.');

      case CardEffect.moveToGo:
        player = player.copyWith(
          position: 0,
          cash: player.cash + GameState.goBonus,
        );
        return next
            .withPlayer(player)
            .logLine(
                '«${player.name}» به خانه شروع رفت و ${_money(GameState.goBonus)} گرفت.');

      case CardEffect.goToJail:
        player = player.copyWith(position: jailIndex, inJail: true, jailTurns: 0);
        return next
            .withPlayer(player)
            .logLine('«${player.name}» روانه بازداشتگاه شد.');

      case CardEffect.heist:
        final List<PlayerModel> others = next.players
            .where((PlayerModel p) => p.id != playerId && !p.bankrupt && p.cash > 0)
            .toList(growable: false);
        if (others.isEmpty) {
          return next.logLine('هیچ رقیبی موجودی نقدی نداشت؛ سرقت بی‌نتیجه ماند.');
        }
        others.sort((PlayerModel a, PlayerModel b) => b.cash.compareTo(a.cash));
        final PlayerModel victim = others.first;
        final int stolen = (victim.cash * card.ratio).floor().clamp(0, victim.cash);
        if (stolen <= 0) {
          return next.logLine('هدف نقدینگی کافی نداشت؛ سرقت بی‌نتیجه ماند.');
        }
        player = player.copyWith(cash: player.cash + stolen);
        return next
            .withPlayer(player)
            .withPlayer(victim.copyWith(cash: victim.cash - stolen))
            .logLine(
                'سرقت سایبری: «${player.name}» ${_money(stolen)} از «${victim.name}» دزدید.');

      case CardEffect.sabotage:
        final List<PlayerModel> rivals = next.players
            .where((PlayerModel p) => p.id != playerId && !p.bankrupt)
            .toList(growable: false);
        if (rivals.isEmpty) {
          return next.logLine('رقیبی برای خرابکاری وجود نداشت.');
        }
        rivals.shuffle(random);
        for (final PlayerModel rival in rivals) {
          final List<int> targets = rival.properties.values
              .where((OwnedProperty o) => o.level > 1 && !o.mortgaged)
              .map((OwnedProperty o) => o.tileIndex)
              .toList(growable: false);
          if (targets.isEmpty) {
            continue;
          }
          final int target = targets[random.nextInt(targets.length)];
          final OwnedProperty owned = rival.properties[target]!;
          final Map<int, OwnedProperty> updatedProperties =
              Map<int, OwnedProperty>.from(rival.properties);
          updatedProperties[target] = owned.copyWith(level: owned.level - 1);
          return next
              .withPlayer(rival.copyWith(properties: updatedProperties))
              .logLine(
                  'خرابکاری: «${TileModel.byIndex(target).name}» متعلق به «${rival.name}» یک سطح تنزل کرد.');
        }
        return next.logLine('هیچ ساختمان قابل تخریبی پیدا نشد.');

      case CardEffect.teleport:
        return _advanceAndResolve(next, playerId, _forwardSteps(
          player.position,
          card.targetTile,
        ), depth + 1);

      case CardEffect.moveBy:
        return _advanceAndResolve(next, playerId, card.amount, depth + 1);

      case CardEffect.advanceNearestTransport:
        final int target = _nearestTransport(player.position);
        return _advanceAndResolve(
          next,
          playerId,
          _forwardSteps(player.position, target),
          depth + 1,
        );

      case CardEffect.getOutOfJail:
        player = player.copyWith(
          getOutOfJailCards: player.getOutOfJailCards + 1,
          cash: player.cash + card.amount,
        );
        return next
            .withPlayer(player)
            .logLine(
                '«${player.name}» کارت آزادی${card.amount > 0 ? " و ${_money(card.amount)}" : ""} دریافت کرد.');

      case CardEffect.collectPerProperty:
        final int gain = player.propertyCount * card.amount;
        player = player.copyWith(cash: player.cash + gain);
        return next
            .withPlayer(player)
            .logLine(
                '«${player.name}» ${_money(gain)} اجاره معوقه گرفت.');

      case CardEffect.payPerBuilding:
        final int levels = player.properties.values
            .where((OwnedProperty o) => !o.mortgaged)
            .fold<int>(0, (int sum, OwnedProperty o) => sum + o.level);
        final int cost = levels * card.amount;
        player = player.copyWith(cash: player.cash - cost);
        return next
            .withPlayer(player)
            .copyWith(parkingPot: next.parkingPot + cost)
            .logLine(
                '«${player.name}» ${_money(cost)} جریمه ساختمان‌ها پرداخت کرد.');

      case CardEffect.freeUpgrade:
        int? cheapest;
        int cheapestCost = 1 << 30;
        for (final OwnedProperty owned in player.properties.values) {
          if (owned.mortgaged || !owned.tile.type.isCity || owned.level >= 5) {
            continue;
          }
          final int cost = owned.tile.upgradeCostFrom(owned.level);
          if (cost < cheapestCost) {
            cheapestCost = cost;
            cheapest = owned.tileIndex;
          }
        }
        if (cheapest == null) {
          return next.logLine('ملک قابل ارتقایی وجود نداشت.');
        }
        final Map<int, OwnedProperty> upgraded =
            Map<int, OwnedProperty>.from(player.properties);
        final OwnedProperty target = upgraded[cheapest]!;
        upgraded[cheapest] = target.copyWith(level: target.level + 1);
        return next
            .withPlayer(player.copyWith(properties: upgraded))
            .logLine(
                '«${TileModel.byIndex(cheapest).name}» به صورت رایگان ارتقا یافت.');

      case CardEffect.collectFromEach:
        GameState collect = next;
        int gained = 0;
        for (final PlayerModel other in next.players) {
          if (other.id == playerId || other.bankrupt) {
            continue;
          }
          final int give = min(card.amount, max(0, other.cash));
          gained += give;
          collect = collect.withPlayer(other.copyWith(cash: other.cash - give));
        }
        final PlayerModel richer =
            collect.playerById(playerId)!.copyWith(cash: player.cash + gained);
        return collect
            .withPlayer(richer)
            .logLine(
                '«${richer.name}» ${_money(gained)} از سایر بازیکنان گرفت.');

      case CardEffect.payEach:
        GameState pay = next;
        int paid = 0;
        final List<PlayerModel> others = next.players
            .where((PlayerModel p) => p.id != playerId && !p.bankrupt)
            .toList(growable: false);
        for (final PlayerModel other in others) {
          paid += card.amount;
          pay = pay.withPlayer(
              other.copyWith(cash: other.cash + card.amount));
        }
        final PlayerModel poorer =
            pay.playerById(playerId)!.copyWith(cash: player.cash - paid);
        return pay.withPlayer(poorer).logLine(
            '«${poorer.name}» ${_money(paid)} بین بازیکنان تقسیم کرد.');
    }
  }

  static int _forwardSteps(int from, int to) {
    int steps = to - from;
    if (steps <= 0) {
      steps += _boardSize;
    }
    return steps;
  }

  static int _nearestTransport(int from) {
    for (int i = 1; i <= _boardSize; i++) {
      final int idx = (from + i) % _boardSize;
      if (TileModel.byIndex(idx).type == TileType.transport) {
        return idx;
      }
    }
    return 5;
  }

  static GameState acknowledgeCard(GameState state, String playerId) {
    if (state.cardReveal == null) {
      return state;
    }
    return state.copyWith(clearCard: true).bumpRevision();
  }

  // ------------------------------------------------------------ purchases

  static GameState buyProperty(GameState state, String playerId) {
    final PendingPurchase? pending = state.pendingPurchase;
    if (pending == null || pending.playerId != playerId) {
      throw GameRuleException('درخواست خرید معتبر نیست.');
    }
    if (state.currentPlayerId != playerId) {
      throw GameRuleException('نوبت شما نیست.');
    }
    final PlayerModel player = state.playerById(playerId)!;
    final TileModel tile = pending.tile;
    if (player.cash < tile.price) {
      throw GameRuleException('موجودی کافی برای خرید این ملک را ندارید.');
    }
    final Map<int, OwnedProperty> properties =
        Map<int, OwnedProperty>.from(player.properties);
    properties[tile.index] = OwnedProperty(tileIndex: tile.index);

    GameState next = state
        .withPlayer(
          player.copyWith(cash: player.cash - tile.price, properties: properties),
        )
        .copyWith(clearPendingPurchase: true)
        .logLine(
            '«${player.name}» «${tile.name}» را به ${_money(tile.price)} خرید.')
        .bumpRevision();
    next = _settle(next, playerId);
    return next;
  }

  static GameState declinePurchase(GameState state, String playerId) {
    final PendingPurchase? pending = state.pendingPurchase;
    if (pending == null || pending.playerId != playerId) {
      throw GameRuleException('درخواست انصراف معتبر نیست.');
    }
    GameState next = state
        .copyWith(clearPendingPurchase: true)
        .logLine('«${state.playerById(playerId)?.name ?? "بازیکن"}» از خرید «${pending.tile.name}» انصراف داد.');
    return _startAuction(next, pending.tileIndex).bumpRevision();
  }

  // -------------------------------------------------------------- auction

  static GameState _startAuction(GameState state, int tileIndex) {
    final List<String> eligible = state.players
        .where((PlayerModel p) => !p.bankrupt && p.connected && p.cash > 0)
        .map((PlayerModel p) => p.id)
        .toList(growable: false);
    if (eligible.isEmpty) {
      return state.logLine('کسی برای شرکت در حراج واجد شرایط نبود.');
    }
    return state
        .copyWith(
          auction: AuctionState(
            tileIndex: tileIndex,
            order: eligible,
            activeIds: eligible,
            turnIndex: 0,
          ),
        )
        .logLine(
            'حراج «${TileModel.byIndex(tileIndex).name}» آغاز شد. حداقل پیشنهاد ${_money(AuctionState.minIncrement)}.')
        .bumpRevision();
  }

  static GameState placeBid(GameState state, String playerId, int amount) {
    final AuctionState? auction = state.auction;
    if (auction == null) {
      throw GameRuleException('حراجی در جریان نیست.');
    }
    if (auction.currentBidderId != playerId) {
      throw GameRuleException('نوبت پیشنهاد شما نیست.');
    }
    final PlayerModel player = state.playerById(playerId)!;
    if (amount < auction.nextMinBid) {
      throw GameRuleException(
          'حداقل پیشنهاد ${_money(auction.nextMinBid)} است.');
    }
    if (amount > player.cash) {
      throw GameRuleException('پیشنهاد شما از موجودی نقدی بیشتر است.');
    }
    final AuctionState updated =
        auction.copyWith(currentBid: amount, leaderId: playerId);
    final GameState next = state
        .copyWith(auction: updated)
        .logLine('«${player.name}» در حراج ${_money(amount)} پیشنهاد داد.')
        .bumpRevision();
    if (updated.isFinished) {
      return _finalizeAuction(next);
    }
    return next.copyWith(auction: _nextBidder(updated));
  }

  static GameState passBid(GameState state, String playerId) {
    final AuctionState? auction = state.auction;
    if (auction == null) {
      throw GameRuleException('حراجی در جریان نیست.');
    }
    if (auction.currentBidderId != playerId) {
      throw GameRuleException('نوبت شما نیست.');
    }
    if (auction.leaderId == playerId) {
      throw GameRuleException('شما بالاترین پیشنهاد را دارید و نمی‌توانید رد کنید.');
    }
    final PlayerModel player = state.playerById(playerId)!;
    final List<String> active = List<String>.from(auction.activeIds)
      ..remove(playerId);

    AuctionState updated = auction.copyWith(activeIds: active);

    if (active.isEmpty) {
      return _finalizeAuction(
        state.copyWith(auction: updated),
      ).logLine('«${player.name}» از حراج کنار رفت.');
    }

    // After removal the element at the same index is the next bidder.
    int index = auction.turnIndex;
    if (index >= active.length) {
      index = 0;
    }
    updated = updated.copyWith(turnIndex: index);

    GameState next = state
        .copyWith(auction: updated)
        .logLine('«${player.name}» از حراج کنار رفت.')
        .bumpRevision();

    if (updated.isFinished) {
      return _finalizeAuction(next);
    }
    return next;
  }

  static AuctionState _nextBidder(AuctionState auction) {
    if (auction.activeIds.isEmpty) {
      return auction;
    }
    final int next = (auction.turnIndex + 1) % auction.activeIds.length;
    return auction.copyWith(turnIndex: next);
  }

  static GameState _finalizeAuction(GameState state) {
    final AuctionState? auction = state.auction;
    if (auction == null) {
      return state;
    }
    if (auction.leaderId == null || auction.currentBid <= 0) {
      return state
          .copyWith(clearAuction: true)
          .logLine('حراج «${auction.tile.name}» بدون خریدار پایان یافت.')
          .bumpRevision();
    }
    final PlayerModel? winner = state.playerById(auction.leaderId);
    if (winner == null) {
      return state.copyWith(clearAuction: true).bumpRevision();
    }
    final Map<int, OwnedProperty> properties =
        Map<int, OwnedProperty>.from(winner.properties);
    properties[auction.tileIndex] = OwnedProperty(tileIndex: auction.tileIndex);
    return state
        .copyWith(clearAuction: true)
        .withPlayer(
          winner.copyWith(
            cash: winner.cash - auction.currentBid,
            properties: properties,
          ),
        )
        .logLine(
            'حراج: «${winner.name}» «${auction.tile.name}» را به ${_money(auction.currentBid)} برد.')
        .bumpRevision();
  }

  // ------------------------------------------------------------ buildings

  static GameState upgradeProperty(
    GameState state,
    String playerId,
    int tileIndex,
  ) {
    if (state.currentPlayerId != playerId) {
      throw GameRuleException('فقط در نوبت خودتان می‌توانید ارتقا دهید.');
    }
    final PlayerModel player = state.playerById(playerId)!;
    final OwnedProperty? owned = player.properties[tileIndex];
    if (owned == null) {
      throw GameRuleException('این ملک متعلق به شما نیست.');
    }
    if (owned.mortgaged) {
      throw GameRuleException('ملک در رهن است؛ ابتدا آزادسازی کنید.');
    }
    if (!owned.tile.type.isCity) {
      throw GameRuleException('فقط شهرها قابل ارتقا هستند.');
    }
    if (owned.level >= 5) {
      throw GameRuleException('این ملک در بالاترین سطح است.');
    }
    final int cost = owned.tile.upgradeCostFrom(owned.level);
    if (player.cash < cost) {
      throw GameRuleException('موجودی کافی برای ارتقا ندارید (${_money(cost)}).');
    }
    final Map<int, OwnedProperty> properties =
        Map<int, OwnedProperty>.from(player.properties);
    properties[tileIndex] = owned.copyWith(level: owned.level + 1);
    return state
        .withPlayer(
          player.copyWith(cash: player.cash - cost, properties: properties),
        )
        .logLine(
            '«${owned.tile.name}» به سطح ${_fa(owned.level + 1)} (${TileModel.levelNamesFa[owned.level + 1]}) ارتقا یافت.')
        .bumpRevision();
  }

  static GameState mortgageProperty(
    GameState state,
    String playerId,
    int tileIndex,
  ) {
    final PlayerModel player = state.playerById(playerId)!;
    final OwnedProperty? owned = player.properties[tileIndex];
    if (owned == null) {
      throw GameRuleException('این ملک متعلق به شما نیست.');
    }
    if (owned.mortgaged) {
      throw GameRuleException('این ملک از قبل در رهن است.');
    }
    if (state.currentPlayerId != playerId && player.cash >= 0) {
      throw GameRuleException('رهن کردن ملک فقط در نوبت خودتان ممکن است.');
    }
    final Map<int, OwnedProperty> properties =
        Map<int, OwnedProperty>.from(player.properties);
    properties[tileIndex] = owned.copyWith(mortgaged: true, level: 1);
    final int gain = owned.tile.mortgageValue;
    return state
        .withPlayer(
          player.copyWith(cash: player.cash + gain, properties: properties),
        )
        .logLine(
            '«${owned.tile.name}» رهن رفت و ${_money(gain)} آزاد شد.')
        .bumpRevision();
  }

  static GameState unmortgageProperty(
    GameState state,
    String playerId,
    int tileIndex,
  ) {
    final PlayerModel player = state.playerById(playerId)!;
    final OwnedProperty? owned = player.properties[tileIndex];
    if (owned == null) {
      throw GameRuleException('این ملک متعلق به شما نیست.');
    }
    if (!owned.mortgaged) {
      throw GameRuleException('این ملک در رهن نیست.');
    }
    final int cost = owned.tile.unmortgageCost;
    if (player.cash < cost) {
      throw GameRuleException('برای آزادسازی ${_money(cost)} لازم است.');
    }
    final Map<int, OwnedProperty> properties =
        Map<int, OwnedProperty>.from(player.properties);
    properties[tileIndex] = owned.copyWith(mortgaged: false);
    return state
        .withPlayer(
          player.copyWith(cash: player.cash - cost, properties: properties),
        )
        .logLine(
            '«${owned.tile.name}» با پرداخت ${_money(cost)} از رهن آزاد شد.')
        .bumpRevision();
  }

  // ---------------------------------------------------------------- trade

  static GameState proposeTrade(
    GameState state,
    String playerId, {
    required String toId,
    required List<int> offeredTiles,
    required List<int> requestedTiles,
    required int offeredCash,
    required int requestedCash,
  }) {
    if (state.tradeOffer?.isPending ?? false) {
      throw GameRuleException('یک پیشنهاد معامله در انتظار پاسخ است.');
    }
    if (playerId == toId) {
      throw GameRuleException('امکان معامله با خودتان وجود ندارد.');
    }
    final PlayerModel? from = state.playerById(playerId);
    final PlayerModel? to = state.playerById(toId);
    if (from == null || to == null || to.bankrupt || from.bankrupt) {
      throw GameRuleException('طرفین معامله معتبر نیستند.');
    }
    if (offeredCash < 0 || requestedCash < 0) {
      throw GameRuleException('مبلغ نقدی نمی‌تواند منفی باشد.');
    }
    if (offeredCash > from.cash) {
      throw GameRuleException('پیشنهاد نقدی از موجودی شما بیشتر است.');
    }
    if (requestedCash > to.cash) {
      throw GameRuleException('طرف مقابل این مقدار پول ندارد.');
    }
    for (final int index in offeredTiles) {
      if (from.properties[index]?.mortgaged ?? true) {
        throw GameRuleException(
            'ملک «${TileModel.byIndex(index).name}» قابل معامله نیست.');
      }
    }
    for (final int index in requestedTiles) {
      if (to.properties[index]?.mortgaged ?? true) {
        throw GameRuleException(
            'ملک «${TileModel.byIndex(index).name}» قابل معامله نیست.');
      }
    }
    if (offeredTiles.isEmpty &&
        requestedTiles.isEmpty &&
        offeredCash == 0 &&
        requestedCash == 0) {
      throw GameRuleException('پیشنهاد معامله خالی است.');
    }
    final String offerId = 'T${DateTime.now().microsecondsSinceEpoch}';
    return state
        .copyWith(
          tradeOffer: TradeOffer(
            id: offerId,
            fromId: playerId,
            toId: toId,
            offeredTiles: List<int>.unmodifiable(offeredTiles),
            requestedTiles: List<int>.unmodifiable(requestedTiles),
            offeredCash: offeredCash,
            requestedCash: requestedCash,
          ),
        )
        .logLine(
            '«${from.name}» به «${to.name}» پیشنهاد معامله داد.')
        .bumpRevision();
  }

  static GameState respondTrade(
    GameState state,
    String playerId,
    bool accept,
  ) {
    final TradeOffer? offer = state.tradeOffer;
    if (offer == null || !offer.isPending) {
      throw GameRuleException('پیشنهاد معامله‌ای موجود نیست.');
    }
    if (offer.toId != playerId) {
      throw GameRuleException('این پیشنهاد خطاب به شما نیست.');
    }
    PlayerModel from = state.playerById(offer.fromId)!;
    PlayerModel to = state.playerById(offer.toId)!;

    if (!accept) {
      return state
          .copyWith(clearTrade: true)
          .logLine('«${to.name}» پیشنهاد معامله را رد کرد.')
          .bumpRevision();
    }

    if (from.cash < offer.offeredCash || to.cash < offer.requestedCash) {
      throw GameRuleException('موجودی یکی از طرفین کافی نیست.');
    }

    final Map<int, OwnedProperty> fromProperties =
        Map<int, OwnedProperty>.from(from.properties);
    final Map<int, OwnedProperty> toProperties =
        Map<int, OwnedProperty>.from(to.properties);

    for (final int index in offer.offeredTiles) {
      if (!fromProperties.containsKey(index)) {
        throw GameRuleException('ملک پیشنهادی دیگر در اختیار پیشنهاددهنده نیست.');
      }
    }
    for (final int index in offer.requestedTiles) {
      if (!toProperties.containsKey(index)) {
        throw GameRuleException('ملک درخواستی دیگر در اختیار شما نیست.');
      }
    }

    for (final int index in offer.offeredTiles) {
      final OwnedProperty property = fromProperties.remove(index)!;
      toProperties[index] = property;
    }
    for (final int index in offer.requestedTiles) {
      final OwnedProperty property = toProperties.remove(index)!;
      fromProperties[index] = property;
    }

    from = from.copyWith(
      cash: from.cash - offer.offeredCash + offer.requestedCash,
      properties: fromProperties,
      dealsCompleted: from.dealsCompleted + 1,
    );
    to = to.copyWith(
      cash: to.cash + offer.offeredCash - offer.requestedCash,
      properties: toProperties,
      dealsCompleted: to.dealsCompleted + 1,
    );

    return state
        .copyWith(clearTrade: true)
        .withPlayer(from)
        .withPlayer(to)
        .logLine('معامله بین «${from.name}» و «${to.name}» انجام شد.')
        .bumpRevision();
  }

  static GameState withdrawTrade(GameState state, String playerId) {
    final TradeOffer? offer = state.tradeOffer;
    if (offer == null) {
      return state;
    }
    if (offer.fromId != playerId) {
      throw GameRuleException('فقط پیشنهاددهنده می‌تواند معامله را لغو کند.');
    }
    return state
        .copyWith(clearTrade: true)
        .logLine('پیشنهاد معامله لغو شد.')
        .bumpRevision();
  }

  // ------------------------------------------------------------ turn flow

  static GameState endTurn(GameState state, String playerId) {
    if (state.phase != GamePhase.playing) {
      throw GameRuleException('بازی در وضعیت بازی نیست.');
    }
    if (state.currentPlayerId != playerId) {
      throw GameRuleException('نوبت شما نیست.');
    }
    if (state.auction != null) {
      throw GameRuleException('حراج در جریان است.');
    }
    if (state.pendingPurchase != null) {
      throw GameRuleException('ابتدا تکلیف خرید ملک را مشخص کنید.');
    }
    if (state.cardReveal != null) {
      throw GameRuleException('ابتدا کارت را تایید کنید.');
    }
    final PlayerModel player = state.playerById(playerId)!;
    if (player.cash < 0) {
      throw GameRuleException('ابتدا بدهی خود را با رهن ملک تسویه کنید.');
    }
    if (!state.hasRolled) {
      throw GameRuleException('ابتدا تاس بریزید.');
    }

    GameState next = state.copyWith(clearTrade: true);
    final int fromIndex = next.currentPlayerIndex;
    final int nextIndex = _nextActiveIndex(next, fromIndex);
    int round = next.round;
    if (nextIndex <= fromIndex) {
      round += 1;
    }
    next = next
        .copyWith(
          currentPlayerIndex: nextIndex,
          hasRolled: false,
          round: round,
        )
        .logLine('نوبت به «${next.currentPlayer?.name ?? "-"}» رسید.')
        .bumpRevision();
    return _maybeFinish(next);
  }

  static int _nextActiveIndex(GameState state, int from) {
    final int count = state.players.length;
    for (int i = 1; i <= count; i++) {
      final int idx = (from + i) % count;
      if (!state.players[idx].bankrupt) {
        return idx;
      }
    }
    return from;
  }

  static GameState _maybeFinish(GameState state) {
    if (state.players.isEmpty) {
      return state;
    }
    if (state.activePlayerCount <= 1) {
      final String? winnerId =
          state.activePlayers.isEmpty ? null : state.activePlayers.first.id;
      return state
          .copyWith(
            phase: GamePhase.gameOver,
            winnerId: winnerId,
            clearAuction: true,
            clearTrade: true,
            clearPendingPurchase: true,
            clearPausedFor: true,
          )
          .logLine(
              winnerId == null
                  ? 'بازی بدون برنده پایان یافت.'
                  : 'پایان بازی! «${state.playerById(winnerId)?.name}» برنده شد.')
          .bumpRevision();
    }
    if (state.round > state.maxRounds) {
      final PlayerModel best = state.ranking.first;
      return state
          .copyWith(
            phase: GamePhase.gameOver,
            winnerId: best.id,
            clearAuction: true,
            clearTrade: true,
            clearPendingPurchase: true,
            clearPausedFor: true,
          )
          .logLine(
              'سقف ${_fa(state.maxRounds)} دور تکمیل شد؛ «${best.name}» با دارایی ${_money(best.netWorth())} برنده است.')
          .bumpRevision();
    }
    return state;
  }

  // ---------------------------------------------------------- bankruptcy

  static GameState declareBankrupt(GameState state, String playerId) {
    final PlayerModel? player = state.playerById(playerId);
    if (player == null || player.bankrupt) {
      throw GameRuleException('بازیکن معتبر نیست.');
    }
    if (state.currentPlayerId != playerId && player.cash >= 0) {
      throw GameRuleException('در حال حاضر امکان اعلام ورشکستگی نیست.');
    }
    GameState next = state
        .withPlayer(player.copyWith(
          bankrupt: true,
          cash: 0,
          properties: const <int, OwnedProperty>{},
          inJail: false,
          jailTurns: 0,
        ))
        .copyWith(clearTrade: true)
        .logLine('«${player.name}» ورشکست شد و از بازی خارج شد.')
        .bumpRevision();

    if (next.pendingPurchase?.playerId == playerId) {
      next = next.copyWith(clearPendingPurchase: true);
    }

    final AuctionState? auction = next.auction;
    if (auction != null) {
      final List<String> remaining = auction.activeIds
          .where((String id) => id != playerId)
          .toList(growable: false);
      AuctionState patch = auction.copyWith(
        activeIds: remaining,
        turnIndex: remaining.isEmpty
            ? 0
            : auction.turnIndex.clamp(0, remaining.length - 1),
      );
      if (auction.leaderId == playerId) {
        patch = patch.copyWith(clearLeader: true, currentBid: 0);
      }
      next = next.copyWith(auction: patch);
      if (patch.isFinished) {
        next = _finalizeAuction(next);
      }
    }

    GameState advanced = next;
    if (advanced.activePlayerCount <= 1 || advanced.currentPlayerId == playerId) {
      if (advanced.activePlayerCount >= 2) {
        final int nextIdx = _nextActiveIndex(advanced, advanced.currentPlayerIndex);
        advanced = advanced
            .copyWith(currentPlayerIndex: nextIdx, hasRolled: false)
            .logLine('نوبت به «${advanced.currentPlayer?.name ?? "-"}» رسید.');
      }
    }
    return _maybeFinish(advanced);
  }

  /// Applies the "cash must not stay negative" rules.
  static GameState _settle(GameState state, String playerId) {
    final PlayerModel? player = state.playerById(playerId);
    if (player == null || player.bankrupt) {
      return state;
    }
    if (player.cash >= 0) {
      return state;
    }
    final bool canRaise = player.properties.values
        .any((OwnedProperty o) => !o.mortgaged && o.tile.price > 0);
    if (player.netWorth() < 0 || !canRaise) {
      return declareBankrupt(state, playerId);
    }
    return state.logLine(
        '«${player.name}» بدهکار است؛ باید ملک رهن کند یا ورشکستگی اعلام کند.');
  }

  // ------------------------------------------------------------- helpers

  static String _money(int value) => '\$$value';

  static String _fa(int value) => _toPersianDigits(value.toString());

  static String _toPersianDigits(String input) {
    const List<String> digits = <String>[
      '۰',
      '۱',
      '۲',
      '۳',
      '۴',
      '۵',
      '۶',
      '۷',
      '۸',
      '۹',
    ];
    final StringBuffer buffer = StringBuffer();
    for (final int codeUnit in input.codeUnits) {
      final int digit = codeUnit - 0x30;
      if (digit >= 0 && digit <= 9) {
        buffer.write(digits[digit]);
      } else {
        buffer.writeCharCode(codeUnit);
      }
    }
    return buffer.toString();
  }
}

/// Formats an amount with Persian digits and thousand separators.
String formatMoney(int value, {bool withDollar = true}) {
  final bool negative = value < 0;
  final String digits = value.abs().toString();
  final StringBuffer buffer = StringBuffer();
  for (int i = 0; i < digits.length; i++) {
    final int remaining = digits.length - i;
    buffer.write(digits[i]);
    if (remaining > 1 && remaining % 3 == 1) {
      buffer.write(',');
    }
  }
  final String latin = '${negative ? "-" : ""}${buffer.toString()}';
  const List<String> persian = <String>[
    '۰',
    '۱',
    '۲',
    '۳',
    '۴',
    '۵',
    '۶',
    '۷',
    '۸',
    '۹',
  ];
  final StringBuffer out = StringBuffer();
  for (final int codeUnit in latin.codeUnits) {
    final int digit = codeUnit - 0x30;
    if (digit >= 0 && digit <= 9) {
      out.write(persian[digit]);
    } else {
      out.writeCharCode(codeUnit);
    }
  }
  return withDollar ? '\$${out.toString()}' : out.toString();
}
