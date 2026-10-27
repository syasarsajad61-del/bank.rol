// [TH01][TH15] Text contrast and light-only theme.
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bankroll_plato/core/theme/app_theme.dart';
import 'package:bankroll_plato/core/theme/colors.dart';

void main() {
  test('light theme and primary text meet AA', () {
    expect(AppTheme.light.brightness, Brightness.light);
    double contrast(Color a, Color b) {
      final x = a.computeLuminance(), y = b.computeLuminance();
      return (max(x, y) + .05) / (min(x, y) + .05);
    }

    expect(contrast(AppColors.navy, AppColors.background), greaterThan(4.5));
    expect(
      contrast(AppColors.mutedOnCream, AppColors.background),
      greaterThan(4.5),
    );
  });
}
