// [G09] Identity always includes a name and a pattern, not color alone.
import 'package:flutter/material.dart';
import '../core/theme/colors.dart';

class IdentityTheme {
  static Color color(int identity) => AppColors.identities[identity % 6];
  static String pattern(int identity) =>
      ['مورب', 'نقطه', 'خط', 'شطرنجی', 'موج', 'ستاره'][identity % 6];
  static Widget badge(int i, {double size = 24}) => Semantics(
    label: pattern(i),
    child: Image.asset(
      'assets/images/icons/identity_${i % 6 + 1}.png',
      width: size,
      height: size,
    ),
  );
}
