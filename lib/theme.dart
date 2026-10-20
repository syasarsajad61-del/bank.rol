import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Central neon palette used by every screen and painter.
class NeonColors {
  const NeonColors._();

  static const Color bg = Color(0xFF05060E);
  static const Color bgDeep = Color(0xFF02030A);
  static const Color panel = Color(0xFF0B1024);
  static const Color panelAlt = Color(0xFF11182F);
  static const Color cyan = Color(0xFF00E5FF);
  static const Color magenta = Color(0xFFFF2D95);
  static const Color lime = Color(0xFF39FF88);
  static const Color amber = Color(0xFFFFE54B);
  static const Color violet = Color(0xFFB14BFF);
  static const Color danger = Color(0xFFFF3B3B);
  static const Color orange = Color(0xFFFF9F1C);
  static const Color blue = Color(0xFF2D7BFF);
  static const Color text = Color(0xFFE8F6FF);
  static const Color textDim = Color(0xFF8FA3BF);
  static const Color glassTint = Color(0x14FFFFFF);
  static const Color glassBorder = Color(0x33FFFFFF);

  static const List<Color> neonSpectrum = <Color>[
    cyan,
    magenta,
    lime,
    amber,
    violet,
    orange,
  ];

  static Color forPlayer(int index) =>
      neonSpectrum[index % neonSpectrum.length];
}

/// Persian-friendly font fallback chain. Flutter still falls back to the
/// platform Arabic shaping engine, we only widen the candidate list.
const List<String> kPersianFontFallback = <String>[
  'Vazirmatn',
  'Noto Naskh Arabic',
  'Noto Sans Arabic',
  'Iranian Sans',
  'Tahoma',
  'Arial',
];

const String kPersianCurrency = '\$';

TextStyle neonText({
  double size = 14,
  FontWeight weight = FontWeight.w500,
  Color color = NeonColors.text,
  double letterSpacing = 0.2,
  double? height,
  List<Shadow>? shadows,
}) =>
    TextStyle(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
      fontFamilyFallback: kPersianFontFallback,
      shadows: shadows,
    );

TextStyle glowText({
  double size = 16,
  FontWeight weight = FontWeight.w800,
  Color color = NeonColors.cyan,
  double blur = 12,
}) =>
    neonText(
      size: size,
      weight: weight,
      color: color,
      shadows: <Shadow>[
        Shadow(color: color.withValues(alpha: 0.75), blurRadius: blur),
        Shadow(color: color.withValues(alpha: 0.35), blurRadius: blur * 2.2),
      ],
    );

ThemeData buildNeonTheme() {
  final ColorScheme scheme = const ColorScheme.dark(
    primary: NeonColors.cyan,
    onPrimary: NeonColors.bgDeep,
    secondary: NeonColors.magenta,
    onSecondary: NeonColors.bgDeep,
    surface: NeonColors.panel,
    onSurface: NeonColors.text,
    error: NeonColors.danger,
    onError: NeonColors.text,
  );

  final TextTheme textTheme = TextTheme(
    displayLarge: glowText(size: 40, blur: 18),
    displayMedium: glowText(size: 32, blur: 16),
    headlineLarge: glowText(size: 26, blur: 14),
    headlineMedium: glowText(size: 22, color: NeonColors.text, blur: 10),
    titleLarge: neonText(size: 20, weight: FontWeight.w700),
    titleMedium: neonText(size: 16, weight: FontWeight.w700),
    bodyLarge: neonText(size: 15),
    bodyMedium: neonText(size: 13.5),
    bodySmall: neonText(size: 12, color: NeonColors.textDim),
    labelLarge: neonText(size: 14, weight: FontWeight.w700),
    labelSmall: neonText(size: 11, color: NeonColors.textDim),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: NeonColors.bg,
    canvasColor: NeonColors.bg,
    textTheme: textTheme,
    primaryTextTheme: textTheme,
    fontFamilyFallback: kPersianFontFallback,
    dividerColor: NeonColors.glassBorder,
    splashFactory: InkSparkle.splashFactory,
    snackBarTheme: SnackBarThemeData(
      backgroundColor: NeonColors.panelAlt,
      contentTextStyle: neonText(size: 13),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: NeonColors.glassBorder),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: NeonColors.panel,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: NeonColors.cyan.withValues(alpha: 0.35)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: NeonColors.panelAlt.withValues(alpha: 0.75),
      labelStyle: neonText(size: 13, color: NeonColors.textDim),
      hintStyle: neonText(size: 13, color: NeonColors.textDim),
      prefixIconColor: NeonColors.cyan,
      suffixIconColor: NeonColors.cyan,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: NeonColors.glassBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: NeonColors.glassBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: NeonColors.cyan, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: NeonColors.danger),
      ),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: NeonColors.cyan,
      thumbColor: NeonColors.cyan,
      inactiveTrackColor: Color(0x33FFFFFF),
      overlayColor: Color(0x2200E5FF),
    ),
    progressIndicatorTheme:
        const ProgressIndicatorThemeData(color: NeonColors.cyan),
  );
}

/// Forces the whole app into a dark, immersive presentation.
class SystemChromeSetup {
  const SystemChromeSetup._();

  static void apply() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: NeonColors.bgDeep,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations(
      <DeviceOrientation>[
        DeviceOrientation.portraitUp,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ],
    );
  }
}
