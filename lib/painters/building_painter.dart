import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Purely procedural pseudo-3D buildings.
///
/// Five levels are supported and they mirror the game's economy:
///  1. Plot       – flat neon-marked lot
///  2. House      – small box with a pitched roof
///  3. Apartment  – taller slab with a window grid
///  4. Mall       – wide block with a glowing retail band
///  5. Skyscraper – tall stepped tower with a lit antenna
///
/// No image assets are used anywhere; every pixel is a path, rect or gradient.
class BuildingPainter extends CustomPainter {
  const BuildingPainter({
    required this.level,
    required this.color,
    this.pulse = 0.0,
  });

  final int level;
  final Color color;
  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    drawBuilding(
      canvas,
      Offset.zero & size,
      level,
      color,
      pulse: pulse,
    );
  }

  @override
  bool shouldRepaint(covariant BuildingPainter oldDelegate) =>
      oldDelegate.level != level ||
      oldDelegate.color != color ||
      oldDelegate.pulse != pulse;

  static void drawBuilding(
    Canvas canvas,
    Rect area,
    int level,
    Color color, {
    double pulse = 0.0,
  }) {
    if (level <= 0 || area.isEmpty) {
      return;
    }
    final int clamped = level.clamp(1, 5);
    final Paint glow = Paint()
      ..color = color.withValues(alpha: 0.42 + 0.18 * pulse)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, area.width * 0.10);

    switch (clamped) {
      case 1:
        _plot(canvas, area, color, glow);
        break;
      case 2:
        _house(canvas, area, color, glow);
        break;
      case 3:
        _apartment(canvas, area, color, glow);
        break;
      case 4:
        _mall(canvas, area, color, glow);
        break;
      default:
        _skyscraper(canvas, area, color, glow, pulse: pulse);
        break;
    }
  }

  // ---------------------------------------------------------------- level 1

  static void _plot(Canvas canvas, Rect area, Color color, Paint glow) {
    final double w = area.width;
    final double h = area.height;
    final Offset center = Offset(area.center.dx, area.top + h * 0.72);
    final Path diamond = Path()
      ..moveTo(center.dx, center.dy - h * 0.16)
      ..lineTo(center.dx + w * 0.34, center.dy)
      ..lineTo(center.dx, center.dy + h * 0.16)
      ..lineTo(center.dx - w * 0.34, center.dy)
      ..close();

    canvas.drawPath(diamond, glow);
    canvas.drawPath(
      diamond,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            color.withValues(alpha: 0.55),
            color.withValues(alpha: 0.12),
          ],
        ).createShader(area),
    );
    canvas.drawPath(
      diamond,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.0, w * 0.018)
        ..color = color.withValues(alpha: 0.95),
    );

    // Corner survey pegs.
    final Paint peg = Paint()..color = color.withValues(alpha: 0.9);
    final double r = math.max(0.8, w * 0.016);
    canvas.drawCircle(
        Offset(center.dx, center.dy - h * 0.16), r, peg);
    canvas.drawCircle(
        Offset(center.dx + w * 0.34, center.dy), r, peg);
    canvas.drawCircle(
        Offset(center.dx, center.dy + h * 0.16), r, peg);
    canvas.drawCircle(
        Offset(center.dx - w * 0.34, center.dy), r, peg);
  }

  // ---------------------------------------------------------------- level 2

  static void _house(Canvas canvas, Rect area, Color color, Paint glow) {
    final double w = area.width;
    final double h = area.height;
    final double bw = w * 0.44;
    final double bh = h * 0.26;
    final double bx = area.center.dx - bw / 2;
    final double by = area.top + h * 0.58;

    final Rect body = Rect.fromLTWH(bx, by, bw, bh);
    canvas.drawRect(body.inflate(bw * 0.10), glow);

    final double dx = bw * 0.22;
    final double dy = bh * 0.42;
    _drawBox(canvas, body, dx, dy, color);

    // Pitched roof.
    final Path roof = Path()
      ..moveTo(bx - bw * 0.12, by)
      ..lineTo(bx + bw / 2, by - h * 0.16)
      ..lineTo(bx + bw * 1.12, by)
      ..close();
    canvas.drawPath(
      roof,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            color.withValues(alpha: 0.95),
            color.withValues(alpha: 0.45),
          ],
        ).createShader(Rect.fromLTWH(bx, by - h * 0.16, bw, h * 0.16)),
    );
    canvas.drawPath(
      roof,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.0, w * 0.014)
        ..color = Colors.white.withValues(alpha: 0.55),
    );

    // Lit door.
    canvas.drawRect(
      Rect.fromLTWH(
        bx + bw * 0.38,
        by + bh * 0.48,
        bw * 0.24,
        bh * 0.52,
      ),
      Paint()..color = const Color(0xFFFFE9A8).withValues(alpha: 0.9),
    );
  }

  // ---------------------------------------------------------------- level 3

  static void _apartment(Canvas canvas, Rect area, Color color, Paint glow) {
    final double w = area.width;
    final double h = area.height;
    final double bw = w * 0.40;
    final double bh = h * 0.46;
    final double bx = area.center.dx - bw / 2;
    final double by = area.top + h * 0.40;

    final Rect body = Rect.fromLTWH(bx, by, bw, bh);
    canvas.drawRect(body.inflate(bw * 0.08), glow);
    _drawBox(canvas, body, bw * 0.26, bh * 0.16, color);

    // Window grid.
    final Paint window = Paint()
      ..color = const Color(0xFFB8F6FF).withValues(alpha: 0.75);
    final Paint darkWindow = Paint()
      ..color = Colors.black.withValues(alpha: 0.35);
    const int cols = 3;
    const int rows = 4;
    final double padX = bw * 0.13;
    final double padY = bh * 0.10;
    final double cellW = (bw - padX * 2) / cols;
    final double cellH = (bh - padY * 2) / rows;
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final Rect cell = Rect.fromLTWH(
          bx + padX + c * cellW + cellW * 0.16,
          by + padY + r * cellH + cellH * 0.18,
          cellW * 0.68,
          cellH * 0.56,
        );
        canvas.drawRect(
          cell,
          ((r + c) % 3 == 0) ? window : darkWindow,
        );
      }
    }
  }

  // ---------------------------------------------------------------- level 4

  static void _mall(Canvas canvas, Rect area, Color color, Paint glow) {
    final double w = area.width;
    final double h = area.height;
    final double bw = w * 0.70;
    final double bh = h * 0.28;
    final double bx = area.center.dx - bw / 2;
    final double by = area.top + h * 0.54;

    final Rect body = Rect.fromLTWH(bx, by, bw, bh);
    canvas.drawRect(body.inflate(bw * 0.06), glow);

    // Side wings.
    final Rect leftWing =
        Rect.fromLTWH(bx - bw * 0.10, by + bh * 0.30, bw * 0.16, bh * 0.70);
    final Rect rightWing =
        Rect.fromLTWH(bx + bw * 0.94, by + bh * 0.30, bw * 0.16, bh * 0.70);
    _drawBox(canvas, leftWing, bw * 0.03, bh * 0.16, color);
    _drawBox(canvas, rightWing, bw * 0.03, bh * 0.16, color);

    _drawBox(canvas, body, bw * 0.10, bh * 0.30, color);

    // Glowing retail band.
    final Rect band = Rect.fromLTWH(bx, by + bh * 0.34, bw, bh * 0.20);
    canvas.drawRect(
      band,
      Paint()
        ..shader = LinearGradient(
          colors: <Color>[
            color.withValues(alpha: 0.15),
            color.withValues(alpha: 0.95),
            color.withValues(alpha: 0.15),
          ],
        ).createShader(band),
    );

    // Entrance canopy.
    final Rect canopy =
        Rect.fromLTWH(bx + bw * 0.34, by + bh * 0.58, bw * 0.32, bh * 0.42);
    canvas.drawRect(
      canopy,
      Paint()..color = const Color(0xFF0A0F1F).withValues(alpha: 0.85),
    );
    canvas.drawRect(
      canopy,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.0, w * 0.012)
        ..color = color.withValues(alpha: 0.95),
    );

    for (int i = 1; i < 4; i++) {
      final double x = canopy.left + canopy.width * i / 4;
      canvas.drawLine(
        Offset(x, canopy.top),
        Offset(x, canopy.bottom),
        Paint()
          ..strokeWidth = math.max(0.6, w * 0.008)
          ..color = color.withValues(alpha: 0.55),
      );
    }
  }

  // ---------------------------------------------------------------- level 5

  static void _skyscraper(
    Canvas canvas,
    Rect area,
    Color color,
    Paint glow, {
    double pulse = 0.0,
  }) {
    final double w = area.width;
    final double h = area.height;

    // Podium.
    final double pw = w * 0.62;
    final double ph = h * 0.16;
    final Rect podium = Rect.fromLTWH(
      area.center.dx - pw / 2,
      area.top + h * 0.74,
      pw,
      ph,
    );
    _drawBox(canvas, podium, pw * 0.12, ph * 0.30, color);

    // Main tower.
    final double tw = w * 0.34;
    final double th = h * 0.62;
    final Rect tower = Rect.fromLTWH(
      area.center.dx - tw / 2,
      area.top + h * 0.14,
      tw,
      th,
    );
    canvas.drawRect(tower.inflate(tw * 0.14), glow);
    _drawBox(canvas, tower, tw * 0.30, th * 0.10, color);

    // Vertical light strips.
    final Paint strip = Paint()
      ..color = const Color(0xFFD9FBFF).withValues(alpha: 0.85);
    for (int i = 0; i < 3; i++) {
      final double x = tower.left + tw * (0.20 + i * 0.26);
      final Rect slot = Rect.fromLTWH(x, tower.top + th * 0.10, tw * 0.09,
          th * 0.72);
      canvas.drawRect(slot, strip);
    }

    // Stepped crown.
    final double cw = tw * 0.62;
    final double ch = h * 0.10;
    final Rect crown = Rect.fromLTWH(
      area.center.dx - cw / 2,
      area.top + h * 0.05,
      cw,
      ch,
    );
    _drawBox(canvas, crown, cw * 0.24, ch * 0.42, color);

    // Antenna + beacon.
    final Offset top =
        Offset(area.center.dx, crown.top - ch * 0.42);
    final Offset antennaTop = Offset(top.dx, top.dy - h * 0.10);
    canvas.drawLine(
      top,
      antennaTop,
      Paint()
        ..strokeWidth = math.max(1.2, w * 0.018)
        ..color = color.withValues(alpha: 0.9),
    );
    canvas.drawCircle(
      antennaTop,
      math.max(1.6, w * 0.035),
      Paint()
        ..color = color.withValues(alpha: 0.35 + 0.4 * pulse)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.05),
    );
    canvas.drawCircle(
      antennaTop,
      math.max(1.2, w * 0.022),
      Paint()..color = const Color(0xFFEAFFFF),
    );
  }

  // ---------------------------------------------------------------- helpers

  /// Draws an extruded box: front face plus a top and a right side face.
  static void _drawBox(
    Canvas canvas,
    Rect front,
    double depthX,
    double depthY,
    Color color,
  ) {
    final Paint side = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          Color.lerp(color, Colors.black, 0.42)!.withValues(alpha: 0.95),
          Color.lerp(color, Colors.black, 0.70)!.withValues(alpha: 0.95),
        ],
      ).createShader(front);
    final Paint top = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          Color.lerp(color, Colors.white, 0.55)!.withValues(alpha: 0.98),
          Color.lerp(color, Colors.white, 0.18)!.withValues(alpha: 0.95),
        ],
      ).createShader(front);
    final Paint face = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          Color.lerp(color, Colors.white, 0.10)!.withValues(alpha: 0.92),
          Color.lerp(color, Colors.black, 0.45)!.withValues(alpha: 0.95),
        ],
      ).createShader(front);

    final Path topPath = Path()
      ..moveTo(front.left, front.top)
      ..lineTo(front.left + depthX, front.top - depthY)
      ..lineTo(front.right + depthX, front.top - depthY)
      ..lineTo(front.right, front.top)
      ..close();

    final Path sidePath = Path()
      ..moveTo(front.right, front.top)
      ..lineTo(front.right + depthX, front.top - depthY)
      ..lineTo(front.right + depthX, front.bottom - depthY)
      ..lineTo(front.right, front.bottom)
      ..close();

    canvas.drawPath(sidePath, side);
    canvas.drawPath(topPath, top);
    canvas.drawRect(front, face);

    final Paint edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.7, front.width * 0.035)
      ..color = Colors.white.withValues(alpha: 0.28);
    canvas.drawRect(front, edge);
    canvas.drawPath(topPath, edge);
    canvas.drawPath(sidePath, edge);
  }
}
