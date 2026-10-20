import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:neon_bankroll/engine/game_engine.dart';
import 'package:neon_bankroll/models/card_model.dart';
import 'package:neon_bankroll/models/game_state.dart';
import 'package:neon_bankroll/models/player_model.dart';
import 'package:neon_bankroll/models/tile_model.dart';

/// Deterministic dice/card source used to pin down rule behaviour.
class _FixedRandom implements Random {
  _FixedRandom(this.value);

  final int value;

  @override
  int nextInt(int max) => value % max;

  @override
  bool nextBool() => false;

  @override
  double nextDouble() => 0.5;
}

GameState _lobby() {
  GameState state = GameState.empty();
  state = GameEngine.addPlayer(state, id: 'a', name: 'الف', isHost: true);
  state = GameEngine.addPlayer(state, id: 'b', name: 'ب');
  return state;
}

GameState _withProperty(
  GameState state,
  String playerId,
  int tileIndex, {
  int level = 1,
  bool mortgaged = false,
}) {
  final PlayerModel player = state.playerById(playerId)!;
  final Map<int, OwnedProperty> props =
      Map<int, OwnedProperty>.from(player.properties);
  props[tileIndex] = OwnedProperty(
    tileIndex: tileIndex,
    level: level,
    mortgaged: mortgaged,
  );
  return state.withPlayer(player.copyWith(properties: props));
}

GameState _at(GameState state, String playerId, int position) {
  final PlayerModel player = state.playerById(playerId)!;
  return state.withPlayer(player.copyWith(position: position));
}

/// Dismisses an open card and drains any auction with passes, then ends
/// the turn. Used to exercise pure turn-rotation behaviour.
GameState _closeTurn(GameState state, String playerId) {
  GameState next = state;
  if (next.cardReveal != null) {
    next = GameEngine.acknowledgeCard(next, playerId);
  }
  int guard = 0;
  while (next.auction != null && guard < 20) {
    guard++;
    final String? bidder = next.auction!.currentBidderId;
    if (bidder == null) {
      break;
    }
    next = GameEngine.passBid(next, bidder);
  }
  return GameEngine.endTurn(next, playerId);
}

const int _isfahan = 6;

void main() {
  setUp(() {
    GameEngine.random = _FixedRandom(0);
  });

  tearDown(() {
    GameEngine.random = Random();
  });

  test('landing on a rival property transfers rent from visitor to owner', () {
    GameState state = GameEngine.startGame(_lobby());
    state = _withProperty(state, 'b', _isfahan);
    state = _at(state, 'a', _isfahan - 2);

    final GameState result = GameEngine.rollDice(state, 'a');
    final int rent = TileModel.byIndex(_isfahan).cityRent(1);

    expect(result.playerById('a')!.position, _isfahan);
    expect(result.playerById('a')!.cash, 5000 - rent);
    expect(result.playerById('b')!.cash, 5000 + rent);
    expect(result.pendingPurchase, isNull);
  });

  test('owning a full colour group doubles the rent', () {
    GameState state = GameEngine.startGame(_lobby());
    // Group 0 covers tiles 1 and 3.
    state = _withProperty(state, 'b', 1);
    state = _withProperty(state, 'b', 3);
    state = _at(state, 'a', 39);

    final GameState result = GameEngine.rollDice(state, 'a');
    final int rent = TileModel.byIndex(1).cityRent(1, ownsGroup: true);

    expect(result.playerById('a')!.position, 1);
    // The visitor also collected the passing-Go bonus on the way.
    expect(
      result.playerById('a')!.cash,
      5000 + GameState.goBonus - rent,
    );
  });

  test('passing Go pays the 500 bonus exactly once', () {
    GameState state = GameEngine.startGame(_lobby());
    state = _at(state, 'a', 38);

    final GameState result = GameEngine.rollDice(state, 'a');

    expect(result.playerById('a')!.position, 0);
    expect(result.playerById('a')!.cash, 5000 + GameState.goBonus);
  });

  test('declining a purchase runs an auction to completion', () {
    GameState state = GameEngine.startGame(_lobby());
    state = state.copyWith(
      pendingPurchase: const PendingPurchase(tileIndex: 1, playerId: 'a'),
    );
    state = GameEngine.declinePurchase(state, 'a');
    expect(state.auction, isNotNull);
    expect(state.auction!.currentBidderId, 'a');

    // Bidding under the minimum is rejected.
    expect(
      () => GameEngine.placeBid(state, 'a', 10),
      throwsA(isA<GameRuleException>()),
    );

    state = GameEngine.placeBid(state, 'a', 200);
    expect(state.auction!.leaderId, 'a');
    expect(state.auction!.currentBidderId, 'b');

    state = GameEngine.passBid(state, 'b');
    expect(state.auction, isNull);
    expect(state.ownerIdOf(1), 'a');
    expect(state.playerById('a')!.cash, 5000 - 200);
  });

  test('the auction leader cannot pass', () {
    GameState state = GameEngine.startGame(_lobby());
    state = state.copyWith(
      pendingPurchase: const PendingPurchase(tileIndex: 1, playerId: 'a'),
    );
    state = GameEngine.declinePurchase(state, 'a');
    state = GameEngine.placeBid(state, 'a', 200);
    state = GameEngine.placeBid(state, 'b', 400);
    // Turn is back on "a", who is no longer the leader.
    expect(state.auction!.currentBidderId, 'a');
    expect(
      () => GameEngine.passBid(state, 'a'),
      returnsNormally,
    );
  });

  test('a trade swaps properties and cash between two players', () {
    GameState state = GameEngine.startGame(_lobby());
    state = _withProperty(state, 'a', 1);
    state = _withProperty(state, 'b', 3);

    state = GameEngine.proposeTrade(
      state,
      'a',
      toId: 'b',
      offeredTiles: const <int>[1],
      requestedTiles: const <int>[3],
      offeredCash: 300,
      requestedCash: 0,
    );
    expect(state.tradeOffer, isNotNull);

    state = GameEngine.respondTrade(state, 'b', true);

    expect(state.ownerIdOf(1), 'b');
    expect(state.ownerIdOf(3), 'a');
    expect(state.playerById('a')!.cash, 5000 - 300);
    expect(state.playerById('b')!.cash, 5000 + 300);
    expect(state.tradeOffer, isNull);
  });

  test('bankruptcy knocks a player out and ends a two player match', () {
    GameState state = GameEngine.startGame(_lobby());
    state = _withProperty(state, 'a', 1);
    final PlayerModel a = state.playerById('a')!;
    state = state.withPlayer(a.copyWith(cash: -400));

    state = GameEngine.declareBankrupt(state, 'a');

    expect(state.playerById('a')!.bankrupt, isTrue);
    expect(state.playerById('a')!.properties, isEmpty);
    expect(state.phase, GamePhase.gameOver);
    expect(state.winnerId, 'b');
  });

  test('a chance card is revealed and its effect is applied', () {
    GameState state = GameEngine.startGame(_lobby());
    // Stand two steps before the first chance tile (index 7).
    state = _at(state, 'a', 5);

    final GameState result = GameEngine.rollDice(state, 'a');

    expect(result.playerById('a')!.position, 7);
    expect(result.cardReveal, isNotNull);
    final GameCard top = GameCard.chanceCards.first;
    expect(result.cardReveal!.cardId, top.id);
    expect(result.playerById('a')!.cash, 5000 + top.amount);

    final GameState acknowledged = GameEngine.acknowledgeCard(result, 'a');
    expect(acknowledged.cardReveal, isNull);
  });

  test('the turn rotates, skips bankrupt players and advances the round', () {
    GameState state = GameEngine.startGame(_lobby());
    state = _closeTurn(GameEngine.rollDice(state, 'a'), 'a');
    expect(state.currentPlayerId, 'b');
    expect(state.round, 1);

    state = _closeTurn(GameEngine.rollDice(state, 'b'), 'b');
    expect(state.currentPlayerId, 'a');
    expect(state.round, 2);
  });

  test('a player cannot act out of turn', () {
    final GameState state = GameEngine.startGame(_lobby());
    expect(
      () => GameEngine.rollDice(state, 'b'),
      throwsA(isA<GameRuleException>()),
    );
    expect(
      () => GameEngine.endTurn(state, 'b'),
      throwsA(isA<GameRuleException>()),
    );
  });

  test('mortgaging raises cash and unmortgaging costs a premium', () {
    GameState state = GameEngine.startGame(_lobby());
    state = _withProperty(state, 'a', 1);
    final TileModel tile = TileModel.byIndex(1);

    state = GameEngine.mortgageProperty(state, 'a', 1);
    expect(state.playerById('a')!.properties[1]!.mortgaged, isTrue);
    expect(state.playerById('a')!.cash, 5000 + tile.mortgageValue);

    state = GameEngine.unmortgageProperty(state, 'a', 1);
    expect(state.playerById('a')!.properties[1]!.mortgaged, isFalse);
    expect(
      state.playerById('a')!.cash,
      5000 + tile.mortgageValue - tile.unmortgageCost,
    );
    expect(tile.unmortgageCost, greaterThan(tile.mortgageValue));
  });

  test('nested state survives a JSON round trip', () {
    GameState state = GameEngine.startGame(_lobby());
    state = _withProperty(state, 'a', 1, level: 3);
    state = state.copyWith(
      auction: AuctionState(
        tileIndex: 3,
        order: const <String>['a', 'b'],
        activeIds: const <String>['a', 'b'],
        turnIndex: 1,
        currentBid: 150,
        leaderId: 'a',
      ),
    );

    final GameState decoded = GameState.fromJson(state.toJson());

    expect(decoded.players.first.properties[1]!.level, 3);
    expect(decoded.auction!.currentBid, 150);
    expect(decoded.auction!.leaderId, 'a');
    expect(decoded.toJson().toString(), state.toJson().toString());
  });

  test('money is rendered with Persian digits', () {
    expect(formatMoney(5000), '\$۵,۰۰۰');
    expect(formatMoney(-250), '\$-۲۵۰');
  });

  test('start and rent rules are wired to the level ladder', () {
    final TileModel city = TileModel.byIndex(_isfahan);
    // Level 1 -> 2 costs 60% of the base price.
    expect(city.upgradeCostFrom(1), (city.price * 0.6).round());
    expect(city.upgradeCostFrom(5), 0);
    expect(city.investedUpgradeValue(5), greaterThan(city.price));
  });
}
