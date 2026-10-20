import 'card_model.dart';
import 'player_model.dart';
import 'tile_model.dart';

/// High level lifecycle of a match.
enum GamePhase {
  lobby,
  playing,

  /// The host froze the match because a client dropped.
  paused,
  gameOver,
}

extension GamePhaseX on GamePhase {
  String get labelFa {
    switch (this) {
      case GamePhase.lobby:
        return 'اتاق انتظار';
      case GamePhase.playing:
        return 'در حال بازی';
      case GamePhase.paused:
        return 'بازی متوقف شد';
      case GamePhase.gameOver:
        return 'پایان بازی';
    }
  }
}

/// Sequential (English) auction driven by the host.
class AuctionState {
  const AuctionState({
    required this.tileIndex,
    required this.order,
    required this.activeIds,
    required this.turnIndex,
    this.currentBid = 0,
    this.leaderId,
  });

  final int tileIndex;

  /// Initial bidding order, kept for display purposes.
  final List<String> order;
  final List<String> activeIds;
  final int turnIndex;
  final int currentBid;
  final String? leaderId;

  static const int minIncrement = 50;

  TileModel get tile => TileModel.byIndex(tileIndex);

  String? get currentBidderId =>
      (turnIndex >= 0 && turnIndex < activeIds.length)
          ? activeIds[turnIndex]
          : null;

  int get nextMinBid => leaderId == null ? 50 : currentBid + minIncrement;

  bool get isFinished {
    if (activeIds.isEmpty) {
      return true;
    }
    if (activeIds.length == 1 && leaderId == activeIds.single) {
      return true;
    }
    return false;
  }

  AuctionState copyWith({
    List<String>? activeIds,
    int? turnIndex,
    int? currentBid,
    String? leaderId,
    bool clearLeader = false,
  }) =>
      AuctionState(
        tileIndex: tileIndex,
        order: order,
        activeIds: activeIds ?? this.activeIds,
        turnIndex: turnIndex ?? this.turnIndex,
        currentBid: currentBid ?? this.currentBid,
        leaderId: clearLeader ? null : (leaderId ?? this.leaderId),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'tileIndex': tileIndex,
        'order': order,
        'activeIds': activeIds,
        'turnIndex': turnIndex,
        'currentBid': currentBid,
        'leaderId': leaderId,
      };

  factory AuctionState.fromJson(Map<String, dynamic> json) => AuctionState(
        tileIndex: (json['tileIndex'] as num?)?.toInt() ?? 0,
        order: _stringList(json['order']),
        activeIds: _stringList(json['activeIds']),
        turnIndex: (json['turnIndex'] as num?)?.toInt() ?? 0,
        currentBid: (json['currentBid'] as num?)?.toInt() ?? 0,
        leaderId: json['leaderId'] as String?,
      );
}

enum TradeStatus { pending, accepted, rejected, withdrawn }

/// A property-for-cash (or swap) proposal.
class TradeOffer {
  const TradeOffer({
    required this.id,
    required this.fromId,
    required this.toId,
    required this.offeredTiles,
    required this.requestedTiles,
    required this.offeredCash,
    required this.requestedCash,
    this.status = TradeStatus.pending,
  });

  final String id;
  final String fromId;
  final String toId;
  final List<int> offeredTiles;
  final List<int> requestedTiles;
  final int offeredCash;
  final int requestedCash;
  final TradeStatus status;

  bool get isPending => status == TradeStatus.pending;

  TradeOffer copyWith({TradeStatus? status}) => TradeOffer(
        id: id,
        fromId: fromId,
        toId: toId,
        offeredTiles: offeredTiles,
        requestedTiles: requestedTiles,
        offeredCash: offeredCash,
        requestedCash: requestedCash,
        status: status ?? this.status,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'fromId': fromId,
        'toId': toId,
        'offeredTiles': offeredTiles,
        'requestedTiles': requestedTiles,
        'offeredCash': offeredCash,
        'requestedCash': requestedCash,
        'status': status.name,
      };

  factory TradeOffer.fromJson(Map<String, dynamic> json) => TradeOffer(
        id: (json['id'] as String?) ?? '',
        fromId: (json['fromId'] as String?) ?? '',
        toId: (json['toId'] as String?) ?? '',
        offeredTiles: _intList(json['offeredTiles']),
        requestedTiles: _intList(json['requestedTiles']),
        offeredCash: (json['offeredCash'] as num?)?.toInt() ?? 0,
        requestedCash: (json['requestedCash'] as num?)?.toInt() ?? 0,
        status: TradeStatus.values.firstWhere(
          (TradeStatus s) => s.name == (json['status'] as String?),
          orElse: () => TradeStatus.pending,
        ),
      );
}

/// The currently revealed event card, shown to every device.
class CardReveal {
  const CardReveal({
    required this.cardId,
    required this.playerId,
    required this.deck,
  });

  final String cardId;
  final String playerId;
  final CardDeck deck;

  GameCard? get card => GameCard.byId(cardId);

  Map<String, dynamic> toJson() => <String, dynamic>{
        'cardId': cardId,
        'playerId': playerId,
        'deck': deck.name,
      };

  factory CardReveal.fromJson(Map<String, dynamic> json) => CardReveal(
        cardId: (json['cardId'] as String?) ?? '',
        playerId: (json['playerId'] as String?) ?? '',
        deck: CardDeck.values.firstWhere(
          (CardDeck d) => d.name == (json['deck'] as String?),
          orElse: () => CardDeck.chance,
        ),
      );
}

/// A player landed on an unowned property and must decide.
class PendingPurchase {
  const PendingPurchase({required this.tileIndex, required this.playerId});

  final int tileIndex;
  final String playerId;

  TileModel get tile => TileModel.byIndex(tileIndex);

  Map<String, dynamic> toJson() => <String, dynamic>{
        'tileIndex': tileIndex,
        'playerId': playerId,
      };

  factory PendingPurchase.fromJson(Map<String, dynamic> json) =>
      PendingPurchase(
        tileIndex: (json['tileIndex'] as num?)?.toInt() ?? 0,
        playerId: (json['playerId'] as String?) ?? '',
      );
}

List<String> _stringList(dynamic raw) {
  if (raw is List) {
    return raw.map((dynamic e) => '$e').toList(growable: false);
  }
  return const <String>[];
}

List<int> _intList(dynamic raw) {
  if (raw is List) {
    return raw
        .map((dynamic e) => e is num ? e.toInt() : int.tryParse('$e') ?? 0)
        .toList(growable: false);
  }
  return const <int>[];
}

/// The single source of truth. Only the host mutates it; clients render it.
class GameState {
  GameState({
    this.phase = GamePhase.lobby,
    List<PlayerModel>? players,
    this.currentPlayerIndex = 0,
    this.round = 1,
    this.diceA = 1,
    this.diceB = 1,
    this.hasRolled = false,
    this.rollCount = 0,
    this.parkingPot = 0,
    this.winnerId,
    this.auction,
    this.tradeOffer,
    this.cardReveal,
    this.pendingPurchase,
    this.pausedForId,
    this.revision = 0,
    List<String>? log,
    this.maxRounds = 40,
  })  : players = List<PlayerModel>.unmodifiable(
          players ?? const <PlayerModel>[],
        ),
        log = List<String>.unmodifiable(log ?? const <String>[]);

  final GamePhase phase;
  final List<PlayerModel> players;
  final int currentPlayerIndex;
  final int round;
  final int diceA;
  final int diceB;
  final bool hasRolled;
  final int rollCount;
  final int parkingPot;
  final String? winnerId;
  final AuctionState? auction;
  final TradeOffer? tradeOffer;
  final CardReveal? cardReveal;
  final PendingPurchase? pendingPurchase;
  final String? pausedForId;
  final int revision;
  final List<String> log;
  final int maxRounds;

  static const int goBonus = 500;
  static const int maxPlayers = 6;

  int get diceTotal => diceA + diceB;

  bool get isDiceDoubles => diceA == diceB;

  bool get isLobby => phase == GamePhase.lobby;

  bool get isOver => phase == GamePhase.gameOver;

  bool get isPaused => phase == GamePhase.paused;

  bool get hasPendingModal =>
      pendingPurchase != null || auction != null || tradeOffer != null;

  PlayerModel? get currentPlayer {
    if (players.isEmpty) {
      return null;
    }
    if (currentPlayerIndex < 0 || currentPlayerIndex >= players.length) {
      return players.first;
    }
    return players[currentPlayerIndex];
  }

  String? get currentPlayerId => currentPlayer?.id;

  PlayerModel? playerById(String? id) {
    if (id == null) {
      return null;
    }
    for (final PlayerModel p in players) {
      if (p.id == id) {
        return p;
      }
    }
    return null;
  }

  int get activePlayerCount =>
      players.where((PlayerModel p) => !p.bankrupt).length;

  List<PlayerModel> get activePlayers =>
      players.where((PlayerModel p) => !p.bankrupt).toList(growable: false);

  String? ownerIdOf(int tileIndex) {
    for (final PlayerModel p in players) {
      if (p.properties.containsKey(tileIndex)) {
        return p.id;
      }
    }
    return null;
  }

  OwnedProperty? propertyOf(int tileIndex) {
    for (final PlayerModel p in players) {
      final OwnedProperty? owned = p.properties[tileIndex];
      if (owned != null) {
        return owned;
      }
    }
    return null;
  }

  PlayerModel? ownerOf(int tileIndex) => playerById(ownerIdOf(tileIndex));

  bool ownsWholeGroup(String playerId, int groupId) {
    if (groupId < 0) {
      return false;
    }
    final List<TileModel> group = TileModel.board
        .where((TileModel t) => t.groupId == groupId)
        .toList(growable: false);
    if (group.isEmpty) {
      return false;
    }
    for (final TileModel t in group) {
      if (ownerIdOf(t.index) != playerId) {
        return false;
      }
    }
    return true;
  }

  int countOwnedInGroup(String playerId, int groupId) => TileModel.board
      .where((TileModel t) => t.groupId == groupId && ownerIdOf(t.index) == playerId)
      .length;

  int transportCountOf(String playerId) => TileModel.board
      .where((TileModel t) =>
          t.type == TileType.transport && ownerIdOf(t.index) == playerId)
      .length;

  int utilityCountOf(String playerId) => TileModel.board
      .where((TileModel t) =>
          t.type == TileType.utility && ownerIdOf(t.index) == playerId)
      .length;

  int netWorthOf(String playerId) {
    final PlayerModel? p = playerById(playerId);
    return p?.netWorth() ?? 0;
  }

  /// Highest net worth first.
  List<PlayerModel> get ranking {
    final List<PlayerModel> sorted = List<PlayerModel>.from(players);
    sorted.sort((PlayerModel a, PlayerModel b) {
      final int byWorth = b.netWorth().compareTo(a.netWorth());
      if (byWorth != 0) {
        return byWorth;
      }
      return b.propertyCount.compareTo(a.propertyCount);
    });
    return sorted;
  }

  PlayerModel? get winner {
    final PlayerModel? fromId = playerById(winnerId);
    if (fromId != null) {
      return fromId;
    }
    if (activePlayerCount == 1) {
      return activePlayers.first;
    }
    return null;
  }

  GameState copyWith({
    GamePhase? phase,
    List<PlayerModel>? players,
    int? currentPlayerIndex,
    int? round,
    int? diceA,
    int? diceB,
    bool? hasRolled,
    int? rollCount,
    int? parkingPot,
    String? winnerId,
    bool clearWinner = false,
    AuctionState? auction,
    bool clearAuction = false,
    TradeOffer? tradeOffer,
    bool clearTrade = false,
    CardReveal? cardReveal,
    bool clearCard = false,
    PendingPurchase? pendingPurchase,
    bool clearPendingPurchase = false,
    String? pausedForId,
    bool clearPausedFor = false,
    int? revision,
    List<String>? log,
    int? maxRounds,
  }) =>
      GameState(
        phase: phase ?? this.phase,
        players: players ?? this.players,
        currentPlayerIndex: currentPlayerIndex ?? this.currentPlayerIndex,
        round: round ?? this.round,
        diceA: diceA ?? this.diceA,
        diceB: diceB ?? this.diceB,
        hasRolled: hasRolled ?? this.hasRolled,
        rollCount: rollCount ?? this.rollCount,
        parkingPot: parkingPot ?? this.parkingPot,
        winnerId: clearWinner ? null : (winnerId ?? this.winnerId),
        auction: clearAuction ? null : (auction ?? this.auction),
        tradeOffer: clearTrade ? null : (tradeOffer ?? this.tradeOffer),
        cardReveal: clearCard ? null : (cardReveal ?? this.cardReveal),
        pendingPurchase:
            clearPendingPurchase ? null : (pendingPurchase ?? this.pendingPurchase),
        pausedForId: clearPausedFor ? null : (pausedForId ?? this.pausedForId),
        revision: revision ?? this.revision,
        log: log ?? this.log,
        maxRounds: maxRounds ?? this.maxRounds,
      );

  /// Replace one player by id.
  GameState withPlayer(PlayerModel updated) => copyWith(
        players: players
            .map((PlayerModel p) => p.id == updated.id ? updated : p)
            .toList(growable: false),
      );

  /// Append a log line, keeping the newest 120 entries.
  GameState logLine(String message) {
    final List<String> next = <String>[...log, message];
    if (next.length > 120) {
      next.removeRange(0, next.length - 120);
    }
    return copyWith(log: next);
  }

  GameState bumpRevision() => copyWith(revision: revision + 1);

  Map<String, dynamic> toJson() => <String, dynamic>{
        'phase': phase.name,
        'players': players.map((PlayerModel p) => p.toJson()).toList(),
        'currentPlayerIndex': currentPlayerIndex,
        'round': round,
        'diceA': diceA,
        'diceB': diceB,
        'hasRolled': hasRolled,
        'rollCount': rollCount,
        'parkingPot': parkingPot,
        'winnerId': winnerId,
        'auction': auction?.toJson(),
        'tradeOffer': tradeOffer?.toJson(),
        'cardReveal': cardReveal?.toJson(),
        'pendingPurchase': pendingPurchase?.toJson(),
        'pausedForId': pausedForId,
        'revision': revision,
        'log': log,
        'maxRounds': maxRounds,
      };

  factory GameState.fromJson(Map<String, dynamic> json) {
    final List<PlayerModel> parsedPlayers = <PlayerModel>[];
    final dynamic rawPlayers = json['players'];
    if (rawPlayers is List) {
      for (final dynamic entry in rawPlayers) {
        if (entry is Map<String, dynamic>) {
          parsedPlayers.add(PlayerModel.fromJson(entry));
        } else if (entry is Map) {
          parsedPlayers.add(
            PlayerModel.fromJson(Map<String, dynamic>.from(entry)),
          );
        }
      }
    }
    return GameState(
      phase: GamePhase.values.firstWhere(
        (GamePhase p) => p.name == (json['phase'] as String?),
        orElse: () => GamePhase.lobby,
      ),
      players: parsedPlayers,
      currentPlayerIndex: (json['currentPlayerIndex'] as num?)?.toInt() ?? 0,
      round: (json['round'] as num?)?.toInt() ?? 1,
      diceA: (json['diceA'] as num?)?.toInt() ?? 1,
      diceB: (json['diceB'] as num?)?.toInt() ?? 1,
      hasRolled: (json['hasRolled'] as bool?) ?? false,
      rollCount: (json['rollCount'] as num?)?.toInt() ?? 0,
      parkingPot: (json['parkingPot'] as num?)?.toInt() ?? 0,
      winnerId: json['winnerId'] as String?,
      auction: json['auction'] is Map
          ? AuctionState.fromJson(
              Map<String, dynamic>.from(json['auction'] as Map),
            )
          : null,
      tradeOffer: json['tradeOffer'] is Map
          ? TradeOffer.fromJson(
              Map<String, dynamic>.from(json['tradeOffer'] as Map),
            )
          : null,
      cardReveal: json['cardReveal'] is Map
          ? CardReveal.fromJson(
              Map<String, dynamic>.from(json['cardReveal'] as Map),
            )
          : null,
      pendingPurchase: json['pendingPurchase'] is Map
          ? PendingPurchase.fromJson(
              Map<String, dynamic>.from(json['pendingPurchase'] as Map),
            )
          : null,
      pausedForId: json['pausedForId'] as String?,
      revision: (json['revision'] as num?)?.toInt() ?? 0,
      log: _stringList(json['log']),
      maxRounds: (json['maxRounds'] as num?)?.toInt() ?? 40,
    );
  }

  static GameState empty() => GameState();
}
