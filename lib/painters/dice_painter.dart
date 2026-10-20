import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Procedural 3D-looking dice. A die is drawn as a pseudo-cube: a rounded
/// front face, a darkened top face and a side face, plus glowing pips.
class DicePainter extends CustomPainter {
  const DicePainter({
    required this.value,
    required this.color,
    this.tilt = 0.0,
    this.glow = 1.0,
  });

  final int value;
  final Color color;
  final double tilt;
  final double glow;

  @override
  void paint(Canvas canvas, Size size) {
    paintDie(
      canvas,
      Offset.zero & size,
      value,
      color,
      tilt: tilt,
      glow: glow,
    );
  }

  @override
  bool shouldRepaint(covariant DicePainter oldDelegate) =>
      oldDelegate.value != value ||
      oldDelegate.color != color ||
      oldDelegate.tilt != tilt ||
      oldDelegate.glow != glow;

  static void paintDie(
    Canvas canvas,
    Rect area,
    int value,
    Color color, {
    double tilt = 0.0,
    double glow = 1.0,
  }) {
    if (area.isEmpty) {
      return;
    }
    final int face = value.clamp(1, 6);
    final double size = math.min(area.width, area.height);
    final double depth = size * 0.13;

    canvas.save();
    canvas.translate(area.center.dx, area.center.dy);
    if (tilt != 0) {
      canvas.rotate(tilt);
    }

    final Rect front = Rect.fromCenter(
      center: Offset(-depth * 0.28, depth * 0.28),
      width: size * 0.82,
      height: size * 0.82,
    );
    final double radius = size * 0.15;
    final RRect frontR = RRect.fromRectAndRadius(
      front,
      Radius.circular(radius),
    );

    // Outer glow.
    if (glow > 0) {
      canvas.drawRRect(
        frontR.inflate(size * 0.03),
        Paint()
          ..color = color.withValues(alpha: 0.30 * glow)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, size * 0.13),
      );
    }

    // Top face.
    final Path topFace = Path()
      ..moveTo(front.left, front.top)
      ..lineTo(front.left + depth, front.top - depth)
      ..lineTo(front.right + depth, front.top - depth)
      ..lineTo(front.right, front.top)
      ..close();
    canvas.drawPath(
      topFace,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color.lerp(color, Colors.white, 0.75)!
                .withValues(alpha: 0.98),
            Color.lerp(color, Colors.white, 0.35)!
                .withValues(alpha: 0.95),
          ],
        ).createShader(Rect.fromLTWH(
          front.left,
          front.top - depth,
          front.width,
          depth,
        )),
    );

    // Side face.
    final Path sideFace = Path()
      ..moveTo(front.right, front.top)
      ..lineTo(front.right + depth, front.top - depth)
      ..lineTo(front.right + depth, front.bottom - depth)
      ..lineTo(front.right, front.bottom)
      ..close();
    canvas.drawPath(
      sideFace,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color.lerp(color, Colors.black, 0.35)!
                .withValues(alpha: 0.98),
            Color.lerp(color, Colors.black, 0.68)!
                .withValues(alpha: 0.98),
          ],
        ).createShader(front),
    );

    // Front face.
    canvas.drawRRect(
      frontR,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color.lerp(color, Colors.white, 0.16)!
                .withValues(alpha: 0.98),
            Color.lerp(color, Colors.black, 0.28)!
                .withValues(alpha: 0.99),
          ],
        ).createShader(front),
    );

    // Rim light.
    canvas.drawRRect(
      frontR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.0, size * 0.022)
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Colors.white.withValues(alpha: 0.85),
            color.withValues(alpha: 0.45),
            Colors.black.withValues(alpha: 0.55),
          ],
        ).createShader(front),
    );

    // Pips.
    final List<Offset> grid = _pipLayout(face);
    final double pipRadius = size * 0.072;
    final Paint pipPaint = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          const Color(0xFFFFFFFF),
          const Color(0xFFEAFBFF),
          const Color(0xFF9FD8E8),
        ],
        stops: const <double>[0.0, 0.55, 1.0],
      ).createShader(
        Rect.fromCircle(center: front.center, radius: pipRadius * 2),
      );
    final Paint pipShadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.45)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, pipRadius * 0.55);

    for (final Offset cell in grid) {
      final Offset pip = Offset(
        front.center.dx + cell.dx * front.width * 0.30,
        front.center.dy + cell.dy * front.height * 0.30,
      );
      canvas.drawCircle(pip + Offset(0, pipRadius * 0.35), pipRadius * 1.05,
          pipShadow);
      canvas.drawCircle(pip, pipRadius, pipPaint);
    }

    canvas.restore();
  }

  static List<Offset> _pipLayout(int face) {
    const Offset tl = Offset(-1, -1);
    const Offset tr = Offset(1, -1);
    const Offset ml = Offset(-1, 0);
    const Offset mc = Offset(0, 0);
    const Offset mr = Offset(1, 0);
    const Offset bl = Offset(-1, 1);
    const Offset br = Offset(1, 1);

    switch (face) {
      case 1:
        return const <Offset>[mc];
      case 2:
        return const <Offset>[tl, br];
      case 3:
        return const <Offset>[tl, mc, br];
      case 4:
        return const <Offset>[tl, tr, bl, br];
      case 5:
        return const <Offset>[tl, tr, mc, bl, br];
      default:
        return const <Offset>[tl, tr, ml, mr, bl, br];
    }
  }
}

/// A pair of dice with a roll-shake animation.
class DiceTray extends StatelessWidget {
  const DiceTray({
    super.key,
    required this.diceA,
    required this.diceB,
    this.rolling = false,
    this.size = 52,
  });

  final int diceA;
  final int diceB;
  final bool rolling;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _die(diceA, const Color(0xFF00E5FF), -0.12),
        const SizedBox(width: 12),
        _die(diceB, const Color(0xFFFF2D95), 0.10),
      ],
    );
  }

  Widget _die(int value, Color color, double tilt) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      builder: (BuildContext context, double t, Widget? child) {
        final double wobble = rolling ? math.sin(t * math.pi * 4) * 0.22 : tilt;
        return Transform.rotate(
          angle: wobble,
          child: CustomPaint(
            size: Size(size, size),
            painter: DicePainter(
              value: value,
              color: color,
              tilt: 0,
            ),
          ),
        );
      },
    );
  }
}
