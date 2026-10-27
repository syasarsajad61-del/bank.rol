// [TH10] Bundled font; runtime font downloads are disabled.
import 'package:flutter/material.dart';
import 'colors.dart';

class AppTypography {
  static const family = 'Vazirmatn';
  static const textTheme = TextTheme(
    displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w700),
    headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
    titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
    bodyMedium: TextStyle(fontSize: 14),
    labelSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
  );
}
