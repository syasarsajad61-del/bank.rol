import 'package:flutter_test/flutter_test.dart';
import 'package:neon_bankroll/engine/game_engine.dart';
import 'package:neon_bankroll/models/game_state.dart';
import 'package:neon_bankroll/models/player_model.dart';
import 'package:neon_bankroll/models/tile_model.dart';

GameState _lobby() {
  GameState state = GameState.empty();
  state = GameEngine.addPlayer(state, id: 'a', name: 'الف', isHost: true);
  state = GameEngine.addPlayer(state, id: 'b', name: 'ب');
  return state;
}

void main() {
  test('board has exactly 40 tiles with the expected composition', () {
    expect(TileModel.board.length, 40);
    expect(
      TileModel.board.where((TileModel t) => t.type == TileType.city).length,
      22,
    );
    expect(
      TileModel.board
          .where((TileModel t) => t.type == TileType.transport)
          .length,
      4,
    );
    expect(
      TileModel.board
          .where((TileModel t) => t.type == TileType.utility)
          .length,
      2,
    );
    expect(
      TileModel.board.where((TileModel t) => t.type == TileType.chance).length,
      3,
    );
    expect(
      TileModel.board
          .where((TileModel t) => t.type == TileType.community)
          .length,
      3,
    );
  });

  test('rent scales exponentially with the building level', () {
    final TileModel city = TileModel.board.firstWhere(
      (TileModel t) => t.type == TileType.city,
    );
    expect(city.cityRent(1), city.baseRent);
    expect(city.cityRent(2), city.baseRent * 3);
    expect(city.cityRent(3), city.baseRent * 7);
    expect(city.cityRent(4), city.baseRent * 15);
    expect(city.cityRent(5), city.baseRent * 30);
    expect(city.cityRent(5, ownsGroup: true), city.baseRent * 60);
  });

  test('players get unique colours and cannot exceed the table size', () {
    GameState state = _lobby();
    expect(state.players.length, 2);
    expect(state.players[0].colorIndex, isNot(state.players[1].colorIndex));

    for (int i = 2; i < GameState.maxPlayers; i++) {
      state = GameEngine.addPlayer(state, id: 'p$i', name: 'بازیکن $i');
    }
    expect(state.players.length, 6);
    expect(
      () => GameEngine.addPlayer(state, id: 'overflow', name: 'اضافه'),
      throwsA(isA<GameRuleException>()),
    );
  });

  test('starting a match resets every player', () {
    final GameState started = GameEngine.startGame(_lobby());
    expect(started.phase, GamePhase.playing);
    expect(started.round, 1);
    expect(started.currentPlayerIndex, 0);
    for (final PlayerModel player in started.players) {
      expect(player.cash, PlayerModel.startingCash);
      expect(player.position, 0);
      expect(player.properties, isEmpty);
    }
  });

  test('a single player cannot start the match', () {
    final GameState solo =
        GameEngine.addPlayer(GameState.empty(), id: 'x', name: 'تنها');
    expect(() => GameEngine.startGame(solo), throwsA(isA<GameRuleException>()));
  });

  test('buying a property charges the price and transfers ownership', () {
    final GameState started = GameEngine.startGame(_lobby());
    final TileModel city = TileModel.board.firstWhere(
      (TileModel t) => t.type == TileType.city,
    );
    final GameState pending = started.copyWith(
      pendingPurchase: PendingPurchase(tileIndex: city.index, playerId: 'a'),
    );
    final GameState bought = GameEngine.buyProperty(pending, 'a');

    expect(bought.ownerIdOf(city.index), 'a');
    expect(bought.playerById('a')!.cash, PlayerModel.startingCash - city.price);
    expect(bought.pendingPurchase, isNull);
  });

  test('declining a purchase starts an auction', () {
    final GameState started = GameEngine.startGame(_lobby());
    final TileModel city = TileModel.board.firstWhere(
      (TileModel t) => t.type == TileType.city,
    );
    final GameState pending = started.copyWith(
      pendingPurchase: PendingPurchase(tileIndex: city.index, playerId: 'a'),
    );
    final GameState auctioned = GameEngine.declinePurchase(pending, 'a');
    expect(auctioned.auction, isNotNull);
    expect(auctioned.auction!.tileIndex, city.index);
  });

  test('upgrading requires ownership and enough cash', () {
    final GameState started = GameEngine.startGame(_lobby());
    final TileModel city = TileModel.board.firstWhere(
      (TileModel t) => t.type == TileType.city,
    );
    final GameState pending = started.copyWith(
      pendingPurchase: PendingPurchase(tileIndex: city.index, playerId: 'a'),
    );
    final GameState bought = GameEngine.buyProperty(pending, 'a');
    final GameState upgraded =
        GameEngine.upgradeProperty(bought, 'a', city.index);
    expect(upgraded.playerById('a')!.properties[city.index]!.level, 2);
    expect(
      upgraded.playerById('a')!.cash,
      PlayerModel.startingCash - city.price - city.upgradeCostFrom(1),
    );
    expect(
      () => GameEngine.upgradeProperty(upgraded, 'b', city.index),
      throwsA(isA<GameRuleException>()),
    );
  });

  test('game state survives a JSON round trip', () {
    final GameState started = GameEngine.startGame(_lobby());
    final GameState decoded = GameState.fromJson(started.toJson());
    expect(decoded.phase, started.phase);
    expect(decoded.players.length, started.players.length);
    expect(decoded.players.first.cash, started.players.first.cash);
    expect(decoded.round, started.round);
  });
}
