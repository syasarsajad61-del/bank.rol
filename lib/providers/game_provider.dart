import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../engine/game_engine.dart';
import '../models/action_request.dart';
import '../models/game_state.dart';
import '../models/player_model.dart';
import '../network/client_socket.dart';
import '../network/host_server.dart';

/// Which side of the table this device is on.
enum PlayerRole { none, host, client }

extension PlayerRoleX on PlayerRole {
  String get labelFa {
    switch (this) {
      case PlayerRole.none:
        return 'تماشاگر';
      case PlayerRole.host:
        return 'میزبان';
      case PlayerRole.client:
        return 'بازیکن مهمان';
    }
  }
}

/// Everything the widget tree needs in one immutable object.
class SessionState {
  const SessionState({
    required this.game,
    required this.role,
    this.localPlayerId,
    this.link = LinkStatus.idle,
    this.localIp,
    this.port,
    this.banner,
    this.bannerSeq = 0,
    this.busy = false,
    this.savedSnapshot,
    this.joinHost,
  });

  final GameState game;
  final PlayerRole role;
  final String? localPlayerId;
  final LinkStatus link;
  final String? localIp;
  final int? port;
  final String? banner;
  final int bannerSeq;
  final bool busy;

  /// JSON snapshot captured when the host had to pause the match.
  final String? savedSnapshot;
  final String? joinHost;

  bool get isHost => role == PlayerRole.host;

  bool get isClient => role == PlayerRole.client;

  bool get inSession => role != PlayerRole.none;

  PlayerModel? get localPlayer => game.playerById(localPlayerId);

  bool get isMyTurn =>
      localPlayerId != null && game.currentPlayerId == localPlayerId;

  bool get connected => link == LinkStatus.connected;

  String? get address =>
      port == null ? null : '${localIp ?? "0.0.0.0"}:$port';

  SessionState copyWith({
    GameState? game,
    PlayerRole? role,
    String? localPlayerId,
    bool clearLocalPlayer = false,
    LinkStatus? link,
    String? localIp,
    int? port,
    String? banner,
    bool clearBanner = false,
    int? bannerSeq,
    bool? busy,
    String? savedSnapshot,
    bool clearSnapshot = false,
    String? joinHost,
  }) =>
      SessionState(
        game: game ?? this.game,
        role: role ?? this.role,
        localPlayerId:
            clearLocalPlayer ? null : (localPlayerId ?? this.localPlayerId),
        link: link ?? this.link,
        localIp: localIp ?? this.localIp,
        port: port ?? this.port,
        banner: clearBanner ? null : (banner ?? this.banner),
        bannerSeq: bannerSeq ?? this.bannerSeq,
        busy: busy ?? this.busy,
        savedSnapshot:
            clearSnapshot ? null : (savedSnapshot ?? this.savedSnapshot),
        joinHost: joinHost ?? this.joinHost,
      );

  static SessionState initial() => SessionState(
        game: GameState.empty(),
        role: PlayerRole.none,
      );
}

/// Bridges the rules engine and the sockets. The host is the only device
/// that ever calls into [GameEngine]; clients just mirror broadcast states.
class GameController extends Notifier<SessionState> {
  @override
  SessionState build() {
    ref.onDispose(() {
      _teardown();
    });
    return SessionState.initial();
  }

  static final Random _rng = Random();
  static const int defaultPort = 8080;

  HostServer? _server;
  ClientSocket? _client;
  final Map<String, String> _socketToPlayer = <String, String>{};
  String? _clientPlayerId;
  String _pendingName = 'بازیکن';
  int _bannerSeq = 0;

  // ------------------------------------------------------------- lifecycle

  String _newId([String prefix = 'p']) =>
      '$prefix${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}'
      '${_rng.nextInt(999)}';

  void _announce(String message) {
    _bannerSeq++;
    state = state.copyWith(banner: message, bannerSeq: _bannerSeq);
  }

  Future<void> _teardown() async {
    _socketToPlayer.clear();
    _clientPlayerId = null;
    final HostServer? server = _server;
    _server = null;
    if (server != null) {
      await server.stop();
    }
    final ClientSocket? client = _client;
    _client = null;
    if (client != null) {
      await client.dispose();
    }
    try {
      await WakelockPlus.disable();
    } catch (_) {
      // Platform without wakelock support.
    }
  }

  Future<void> _keepAwake() async {
    try {
      await WakelockPlus.enable();
    } catch (_) {
      // Platform without wakelock support.
    }
  }

  // ------------------------------------------------------------ host flow

  Future<void> hostGame(String hostName, {int port = defaultPort}) async {
    await _teardown();
    _pendingName = hostName;
    state = state.copyWith(
      role: PlayerRole.host,
      busy: true,
      link: LinkStatus.connecting,
      clearLocalPlayer: true,
      clearBanner: true,
      joinHost: null,
    );

    final HostServer server = HostServer(
      port: port,
      onPeerConnected: _onPeerConnected,
      onPeerDisconnected: _onPeerDisconnected,
      onMessage: _onHostMessage,
    );

    int boundPort;
    try {
      boundPort = await server.start();
    } catch (error) {
      state = state.copyWith(
        busy: false,
        link: LinkStatus.failed,
        banner: 'راه‌اندازی سرور ناموفق بود: $error',
        bannerSeq: ++_bannerSeq,
      );
      return;
    }

    _server = server;
    final String? ip = await HostServer.findLocalIpv4();
    final String hostId = _newId('h');
    GameState lobby = GameEngine.addPlayer(
      GameState.empty(),
      id: hostId,
      name: hostName.trim().isEmpty ? 'میزبان' : hostName.trim(),
      isHost: true,
    );

    state = state.copyWith(
      game: lobby,
      localPlayerId: hostId,
      localIp: ip ?? '127.0.0.1',
      port: boundPort,
      link: LinkStatus.connected,
      busy: false,
      banner: 'میز بازی روی پورت $boundPort فعال شد.',
      bannerSeq: ++_bannerSeq,
    );
    await _keepAwake();
  }

  void _onPeerConnected(String socketId) {
    // Wait for the `hello` handshake before binding a player.
  }

  void _onPeerDisconnected(String socketId) {
    final String? playerId = _socketToPlayer.remove(socketId);
    if (playerId == null) {
      return;
    }
    final PlayerModel? player = state.game.playerById(playerId);
    if (player == null) {
      return;
    }
    GameState game = state.game;
    if (game.phase == GamePhase.lobby) {
      _push(GameEngine.removePlayer(game, playerId));
      return;
    }
    game = GameEngine.setConnected(game, playerId, false);
    if (game.phase == GamePhase.playing && !player.bankrupt) {
      game = GameEngine.pauseFor(game, playerId);
      _announce('بازی متوقف شد؛ در انتظار بازگشت «${player.name}».');
    }
    _push(game, snapshot: true);
  }

  void _onHostMessage(String socketId, WireMessage message) {
    switch (message.type) {
      case WireMessage.hello:
        _handleHello(socketId, message.payload);
        break;
      case WireMessage.action:
        _handleClientAction(socketId, message.payload);
        break;
      default:
        break;
    }
  }

  void _handleHello(String socketId, Map<String, dynamic> payload) {
    final String requestedName =
        ((payload['name'] as String?) ?? 'مهمان').trim();
    final String? returningId = payload['playerId'] as String?;
    GameState game = state.game;

    if (returningId != null && game.playerById(returningId) != null) {
      _socketToPlayer[socketId] = returningId;
      game = GameEngine.setConnected(game, returningId, true);
      _push(game);
      _server?.send(
        socketId,
        WireMessage(WireMessage.welcome, <String, dynamic>{
          'playerId': returningId,
          'state': game.toJson(),
          'port': state.port,
          'reconnected': true,
        }),
      );
      if (game.phase == GamePhase.paused && game.pausedForId == returningId) {
        _push(GameEngine.resumeFromPause(game));
        _announce(
            '«${game.playerById(returningId)?.name}» بازگشت؛ بازی ادامه می‌یابد.');
      }
      return;
    }

    if (game.phase != GamePhase.lobby) {
      _sendError(socketId, 'بازی شروع شده است؛ ورود ممکن نیست.');
      return;
    }
    if (game.players.length >= GameState.maxPlayers) {
      _sendError(socketId, 'اتاق پر است؛ حداکثر ۶ بازیکن.');
      return;
    }

    final String newId = _newId('c');
    try {
      game = GameEngine.addPlayer(
        game,
        id: newId,
        name: requestedName.isEmpty ? 'مهمان' : requestedName,
      );
    } on GameRuleException catch (error) {
      _sendError(socketId, error.message);
      return;
    }

    _socketToPlayer[socketId] = newId;
    _push(game);
    _server?.send(
      socketId,
      WireMessage(WireMessage.welcome, <String, dynamic>{
        'playerId': newId,
        'state': game.toJson(),
        'port': state.port,
      }),
    );
  }

  void _handleClientAction(String socketId, Map<String, dynamic> payload) {
    final String? boundPlayer = _socketToPlayer[socketId];
    if (boundPlayer == null) {
      _sendError(socketId, 'ابتدا به بازی بپیوندید.');
      return;
    }
    final ActionRequest request = ActionRequest.fromJson(payload);
    if (request.playerId != boundPlayer) {
      _sendError(socketId, 'درخواست نامعتبر: هویت با سوکت مطابقت ندارد.');
      return;
    }
    try {
      _push(GameEngine.apply(state.game, request));
    } on GameRuleException catch (error) {
      _sendError(socketId, error.message);
    } catch (error) {
      _sendError(socketId, 'خطای غیرمنتظره: $error');
    }
  }

  void _sendError(String socketId, String message) {
    _server?.send(
      socketId,
      WireMessage(WireMessage.error, <String, dynamic>{'msg': message}),
    );
  }

  void _push(GameState game, {bool snapshot = false}) {
    state = state.copyWith(
      game: game,
      savedSnapshot: snapshot ? game.toJson().toString() : null,
    );
    _server?.broadcast(
      WireMessage(WireMessage.state, <String, dynamic>{'state': game.toJson()}),
    );
  }

  // ---------------------------------------------------------- client flow

  Future<void> joinGame({
    required String playerName,
    required String host,
    int port = defaultPort,
  }) async {
    await _teardown();
    _pendingName = playerName.trim().isEmpty ? 'مهمان' : playerName.trim();
    state = state.copyWith(
      role: PlayerRole.client,
      busy: true,
      link: LinkStatus.connecting,
      joinHost: host,
      port: port,
      clearLocalPlayer: true,
      clearBanner: true,
      game: GameState.empty(),
    );

    final ClientSocket client = ClientSocket(
      host: host,
      port: port,
      onMessage: _onClientMessage,
      onStatus: _onClientStatus,
    );
    _client = client;
    await client.connect();
  }

  void _onClientStatus(LinkStatus status) {
    final bool busy =
        status == LinkStatus.connecting || status == LinkStatus.reconnecting;
    state = state.copyWith(
      link: status,
      busy: busy,
      banner: status == LinkStatus.reconnecting
          ? 'اتصال قطع شد؛ تلاش مجدد برای اتصال...'
          : state.banner,
      bannerSeq: status == LinkStatus.reconnecting ? ++_bannerSeq : null,
    );
    if (status == LinkStatus.connected) {
      _client?.send(
        WireMessage(WireMessage.hello, <String, dynamic>{
          'name': _pendingName,
          if (_clientPlayerId != null) 'playerId': _clientPlayerId,
        }),
      );
    }
    if (status == LinkStatus.failed) {
      _announce('اتصال به میزبان برقرار نشد. آدرس و شبکه را بررسی کنید.');
    }
  }

  void _onClientMessage(WireMessage message) {
    switch (message.type) {
      case WireMessage.welcome:
        final String? id = message.payload['playerId'] as String?;
        _clientPlayerId = id;
        final GameState? game = _decodeState(message.payload['state']);
        state = state.copyWith(
          game: game ?? state.game,
          localPlayerId: id,
          link: LinkStatus.connected,
          busy: false,
          clearBanner: true,
        );
        break;
      case WireMessage.state:
        final GameState? game = _decodeState(message.payload['state']);
        if (game != null) {
          state = state.copyWith(game: game, busy: false);
        }
        break;
      case WireMessage.error:
        _announce((message.payload['msg'] as String?) ?? 'خطای نامشخص');
        state = state.copyWith(busy: false);
        break;
      case WireMessage.bye:
        _announce('میزبان اتصال را بست.');
        break;
      case WireMessage.info:
        state = state.copyWith(busy: false);
        break;
      default:
        break;
    }
  }

  GameState? _decodeState(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      try {
        return GameState.fromJson(raw);
      } catch (_) {
        return null;
      }
    }
    if (raw is Map) {
      try {
        return GameState.fromJson(Map<String, dynamic>.from(raw));
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  // --------------------------------------------------------------- action

  /// The single entry point the UI uses for every rule interaction.
  void sendAction(ActionType type, [Map<String, dynamic> data = const <String, dynamic>{}]) {
    final String? localId = state.localPlayerId;
    if (localId == null) {
      _announce('شما در این بازی بازیکن نیستید.');
      return;
    }
    final ActionRequest request =
        ActionRequest(type: type, playerId: localId, data: data);

    if (state.isHost) {
      try {
        _push(GameEngine.apply(state.game, request));
      } on GameRuleException catch (error) {
        _announce(error.message);
      } catch (error) {
        _announce('خطای غیرمنتظره: $error');
      }
      return;
    }
    _client?.send(WireMessage(WireMessage.action, request.toJson()));
  }

  // ------------------------------------------------------------ shortcuts

  void startMatch() => sendAction(ActionType.startGame);

  void rematch() => sendAction(ActionType.rematch);

  void rollDice() => sendAction(ActionType.rollDice);

  void buyPending() => sendAction(ActionType.buyProperty);

  void declinePending() => sendAction(ActionType.declinePurchase);

  void endTurn() => sendAction(ActionType.endTurn);

  void acknowledgeCard() => sendAction(ActionType.acknowledgeCard);

  void placeBid(int amount) =>
      sendAction(ActionType.placeBid, <String, dynamic>{'amount': amount});

  void passBid() => sendAction(ActionType.passBid);

  void upgrade(int tileIndex) => sendAction(
        ActionType.upgradeProperty,
        <String, dynamic>{'tileIndex': tileIndex},
      );

  void mortgage(int tileIndex) => sendAction(
        ActionType.mortgageProperty,
        <String, dynamic>{'tileIndex': tileIndex},
      );

  void unmortgage(int tileIndex) => sendAction(
        ActionType.unmortgageProperty,
        <String, dynamic>{'tileIndex': tileIndex},
      );

  void declareBankrupt() => sendAction(ActionType.declareBankrupt);

  void respondTrade(bool accept) => sendAction(
        ActionType.respondTrade,
        <String, dynamic>{'accept': accept},
      );

  void withdrawTrade() => sendAction(ActionType.withdrawTrade);

  void proposeTrade({
    required String toId,
    required List<int> offeredTiles,
    required List<int> requestedTiles,
    required int offeredCash,
    required int requestedCash,
  }) =>
      sendAction(ActionType.proposeTrade, <String, dynamic>{
        'toId': toId,
        'offeredTiles': offeredTiles,
        'requestedTiles': requestedTiles,
        'offeredCash': offeredCash,
        'requestedCash': requestedCash,
      });

  void dismissBanner() {
    if (state.banner != null) {
      state = state.copyWith(clearBanner: true);
    }
  }

  Future<void> leaveSession() async {
    await _teardown();
    state = SessionState.initial();
  }
}

/// Provider exported to the widget tree.
final NotifierProvider<GameController, SessionState> gameProvider =
    NotifierProvider<GameController, SessionState>(GameController.new);

/// Convenience selector: the match currently in flight.
final Provider<GameState> gameStateProvider = Provider<GameState>((ref) {
  return ref.watch(gameProvider).game;
});

/// Convenience selector: the device's own player record.
final Provider<PlayerModel?> localPlayerProvider =
    Provider<PlayerModel?>((ref) {
  return ref.watch(gameProvider).localPlayer;
});
