// [F05][TH15][BL12] Real screens at phone, small phone and landscape sizes.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bankroll_plato/core/models/game_state.dart';
import 'package:bankroll_plato/core/theme/app_theme.dart';
import 'package:bankroll_plato/providers/game_provider.dart';
import 'package:bankroll_plato/providers/network_provider.dart';
import 'package:bankroll_plato/providers/settings_provider.dart';
import 'package:bankroll_plato/ui/screens/screens.dart';

void main() {
  for (final size in [
    const Size(390, 844),
    const Size(320, 640),
    const Size(844, 390),
  ]) {
    testWidgets('board has no layout exceptions at $size', (tester) async {
      final fonts = FontLoader('Vazirmatn')
        ..addFont(rootBundle.load('assets/fonts/Vazirmatn-Regular.ttf'));
      await fonts.load();
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
      final previousError = FlutterError.onError;
      FlutterError.onError = (details) {
        FlutterError.dumpErrorToConsole(details, forceReport: true);
        previousError?.call(details);
      };
      addTearDown(() => FlutterError.onError = previousError);
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final g = GameProvider()..localId = 'p0';
      g.start([
        Player(id: 'p0', name: 'شما', identity: 0),
        Player(id: 'p1', name: 'آرمان', identity: 1, bot: true),
      ], isHost: false);
      final n = NetworkProvider(g),
          settings = SettingsProvider()
            ..sound = false
            ..reducedMotion = true;
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: g),
            ChangeNotifierProvider.value(value: n),
            ChangeNotifierProvider.value(value: settings),
          ],
          child: MaterialApp(
            locale: const Locale('fa'),
            supportedLocales: const [Locale('fa')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            theme: AppTheme.light,
            home: const GameBoardScreen(),
          ),
        ),
      );
      await tester.runAsync(() async {
        final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
        final context = tester.element(find.byType(GameBoardScreen));
        await Future.wait(
          manifest
              .listAssets()
              .where((p) => p.endsWith('.png'))
              .map((p) => precacheImage(AssetImage(p), context)),
        );
      });
      await tester.pump(const Duration(milliseconds: 900));
      expect(find.text('محله‌های زاهدان'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(GameBoardScreen),
        matchesGoldenFile(
          'goldens/board_${size.width.toInt()}x${size.height.toInt()}.png',
        ),
      );
      await tester.pumpWidget(const SizedBox());
      g.dispose();
      n.dispose();
      settings.dispose();
    });
  }
}
