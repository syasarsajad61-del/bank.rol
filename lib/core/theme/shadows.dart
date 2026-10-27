// [TH09] Warm, low opacity navy shadows.
import 'package:flutter/material.dart';

class AppShadows {
  static const small = BoxShadow(
    color: Color(0x0F1E3A5F),
    blurRadius: 4,
    offset: Offset(0, 2),
  );
  static const medium = BoxShadow(
    color: Color(0x141E3A5F),
    blurRadius: 8,
    offset: Offset(0, 4),
  );
  static const large = BoxShadow(
    color: Color(0x1A1E3A5F),
    blurRadius: 16,
    offset: Offset(0, 8),
  );
}
