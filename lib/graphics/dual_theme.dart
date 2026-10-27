// [G04] Economic color crossfade retains the cream light foundation.
import 'package:flutter/material.dart';
import '../core/models/game_state.dart';

class DualTheme extends StatelessWidget {
  final EconomicPhase phase;
  final Widget child;
  const DualTheme({super.key, required this.phase, required this.child});
  @override
  Widget build(BuildContext c) => AnimatedContainer(
    duration: const Duration(seconds: 2),
    curve: Curves.easeInOutCubic,
    color: switch (phase) {
      EconomicPhase.bull => const Color(0xFFF0F7EB),
      EconomicPhase.bear => const Color(0xFFFBF1E7),
      EconomicPhase.stable => const Color(0xFFFAF6EE),
    },
    child: child,
  );
}
