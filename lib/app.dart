// [F01][TH01][TH10] Persian-first application and provider ownership.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'providers/settings_provider.dart';
import 'providers/game_provider.dart';
import 'providers/network_provider.dart';
import 'providers/theme_provider.dart';
import 'ui/screens/screens.dart';

class BankrollApp extends StatelessWidget {
  const BankrollApp({super.key});
  @override
  Widget build(BuildContext c) => MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ChangeNotifierProvider(create: (_) => GameProvider()),
      ChangeNotifierProvider(
        create: (c) => NetworkProvider(c.read<GameProvider>()),
      ),
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
    ],
    child: MaterialApp(
      title: 'بانک‌رول پلاتو+',
      debugShowCheckedModeBanner: false,
      locale: const Locale('fa'),
      supportedLocales: const [Locale('fa')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: AppTheme.light,
      home: const SplashScreen(),
    ),
  );
}
