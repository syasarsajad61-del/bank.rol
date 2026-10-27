// [G03][A06] Private participant-only red links and seal shake.
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/models/game_state.dart';

class SecretContractLayer extends StatelessWidget {
  final GameState state;
  final String viewer;
  final List<Offset> positions;
  const SecretContractLayer({
    super.key,
    required this.state,
    required this.viewer,
    required this.positions,
  });
  @override
  Widget build(BuildContext c) {
    final private = state.contracts
        .where(
          (x) => x.includes(viewer) && x.accepted && x.expires > state.round,
        )
        .toList();
    return IgnorePointer(
      child: Stack(
        children: [
          CustomPaint(
            size: Size.infinite,
            painter: _Links(state, private, positions),
          ),
          for (final x in private)
            Positioned(
              left:
                  (positions[state.player(x.first).position].dx +
                          positions[state.player(x.second).position].dx) /
                      2 -
                  12,
              top:
                  (positions[state.player(x.first).position].dy +
                          positions[state.player(x.second).position].dy) /
                      2 -
                  12,
              child: TweenAnimationBuilder<double>(
                key: ValueKey('${x.id}_${x.broken}'),
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 500),
                builder: (c, t, w) => Transform.translate(
                  offset: Offset(
                    x.broken ? math.sin(t * 50) * (1 - t) * 12 : 0,
                    0,
                  ),
                  child: Opacity(opacity: x.broken ? (1 - t) : 1, child: w),
                ),
                child: Image.asset(
                  'assets/images/contract_seal.png',
                  width: 24,
                  height: 24,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Links extends CustomPainter {
  final GameState state;
  final List<Contract> contracts;
  final List<Offset> positions;
  _Links(this.state, this.contracts, this.positions);
  @override
  void paint(Canvas c, Size s) {
    for (final x in contracts.where((x) => !x.broken)) {
      final a = positions[state.player(x.first).position],
          b = positions[state.player(x.second).position];
      c.drawLine(
        a,
        b,
        Paint()
          ..color = const Color(0x88E74C3C)
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _Links old) => true;
}
