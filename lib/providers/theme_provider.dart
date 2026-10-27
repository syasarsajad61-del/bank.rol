// [G04][TH01] Two economic overlays on the same light theme.
import 'package:flutter/material.dart';
import '../core/models/game_state.dart';
import '../core/theme/colors.dart';

class ThemeProvider extends ChangeNotifier {
  EconomicPhase phase = EconomicPhase.stable;
  Color get accent => switch (phase) {
    EconomicPhase.stable => AppColors.turquoise,
    EconomicPhase.bull => AppColors.green,
    EconomicPhase.bear => const Color(0xFFC56820),
  };
  void setPhase(EconomicPhase value) {
    if (value != phase) {
      phase = value;
      notifyListeners();
    }
  }
}
