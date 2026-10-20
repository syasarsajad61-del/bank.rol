import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neon_bankroll/models/game_state.dart';
import 'package:neon_bankroll/models/player_model.dart';
import 'package:neon_bankroll/network/client_socket.dart';
import 'package:neon_bankroll/providers/game_provider.dart';
import 'package:neon_bankroll/screens/game_screen.dart';
import 'package:neon_bankroll/theme.dart';

/// Feeds a fixed session into the real controller so the live game screen
/// can be rendered without a socket.
class _DemoController extends GameController {
  _DemoController(this.demo);

  final SessionState demo;

  @override
  SessionState build() => demo;
}

SessionState _demoSession({int currentPlayerIndex = 0}) {
  final List<PlayerModel> players = <PlayerModel>[
    PlayerModel(
      id: 'p1',
      name: 'آرش',
      colorIndex: 0,
      cash: 6200,
      position: 6,
      properties: <int, OwnedProperty>{
        1: const OwnedProperty(tileIndex: 1, level: 2),
        3: const OwnedProperty(tileIndex: 3, level: 1),
      },
    ),
    PlayerModel(
      id: 'p2',
      name: 'سارا',
      colorIndex: 1,
      cash: 3400,
      position: 14,
      properties: <int, OwnedProperty>{
        6: const OwnedProperty(tileIndex: 6, level: 3),
        8: const OwnedProperty(tileIndex: 8, level: 4),
      },
    ),
    PlayerModel(
      id: 'p3',
      name: 'نیما',
      colorIndex: 2,
      cash: 900,
      position: 24,
      properties: <int, OwnedProperty>{
        21: const OwnedProperty(tileIndex: 21, level: 5),
      },
    ),
  ];
  return SessionState(
    game: GameState(
      phase: GamePhase.playing,
      players: players,
      currentPlayerIndex: currentPlayerIndex,
      round: 7,
      diceA: 4,
      diceB: 2,
      hasRolled: false,
      parkingPot: 350,
      log: <String>[
        'بازی «نئون بانکرول» آغاز شد.',
        'نوبت به «آرش» رسید.',
      ],
    ),
    role: PlayerRole.host,
    localPlayerId: 'p1',
    link: LinkStatus.connected,
    localIp: '192.168.1.20',
    port: 8080,
  );
}

Future<void> _pump(WidgetTester tester, SessionState session) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        gameProvider.overrideWith(() => _DemoController(session)),
      ],
      child: MaterialApp(
        theme: buildNeonTheme(),
        debugShowCheckedModeBanner: false,
        home: const GameScreen(),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  testWidgets('the live game screen renders a mid-game state', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await _pump(tester, _demoSession());

    expect(find.byType(GameScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
    // The action bar offers the dice roll on the local player's turn.
    expect(find.text('تاس بریز'), findsOneWidget);
    expect(find.textContaining('نقد شما'), findsOneWidget);
  });

  testWidgets('the action bar waits for the other player', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await _pump(tester, _demoSession(currentPlayerIndex: 1));

    expect(tester.takeException(), isNull);
    expect(find.textContaining('در انتظار'), findsWidgets);
    expect(find.text('تاس بریز'), findsNothing);
  });

  testWidgets('a paused match shows the reconnect overlay', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    final SessionState base = _demoSession();
    await _pump(
      tester,
      base.copyWith(
        game: base.game.copyWith(
          phase: GamePhase.paused,
          pausedForId: 'p2',
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('بازی متوقف است'), findsOneWidget);
    expect(find.textContaining('سارا'), findsWidgets);
  });
}
