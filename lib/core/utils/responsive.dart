// [BL12] Responsive sizes shared by board and dialogs.
import 'package:flutter/widgets.dart';

class Responsive {
  static bool landscape(BuildContext c) =>
      MediaQuery.sizeOf(c).width > MediaQuery.sizeOf(c).height;
  static bool small(BuildContext c) => MediaQuery.sizeOf(c).width < 360;
  static double boardWidth(BuildContext c) =>
      MediaQuery.sizeOf(c).width.clamp(320, 1080);
}
