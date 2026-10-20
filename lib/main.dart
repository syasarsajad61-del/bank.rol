import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/game_state.dart';
import 'providers/game_provider.dart';
import 'screens/game_screen.dart';
import 'screens/lobby_screen.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChromeSetup.apply();
  runApp(const ProviderScope(child: NeonBankrollApp()));
}

class NeonBankrollApp extends StatelessWidget {
  const NeonBankrollApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'نئون بانکرول',
      debugShowCheckedModeBanner: false,
      theme: buildNeonTheme(),
      darkTheme: buildNeonTheme(),
      themeMode: ThemeMode.dark,
      locale: const Locale('fa', 'IR'),
      supportedLocales: const <Locale>[
        Locale('fa', 'IR'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const _RootGateway(),
    );
  }
}

/// Switches between the pairing lobby and the live match.
class _RootGateway extends ConsumerWidget {
  const _RootGateway();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SessionState session = ref.watch(gameProvider);
    final bool inMatch =
        session.inSession && session.game.phase != GamePhase.lobby;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: inMatch
          ? const GameScreen(key: ValueKey<String>('game-screen'))
          : const LobbyScreen(key: ValueKey<String>('lobby-screen')),
    );
  }
}
