// [BL01][BL03] Double-stroke serpentine path with cubic row joins.
import 'package:flutter/material.dart';

class PathPainter extends CustomPainter {
  final List<Offset> points;
  const PathPainter(this.points);
  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      final a = points[i - 1], b = points[i];
      if ((a.dy - b.dy).abs() < 1) {
        path.lineTo(b.dx, b.dy);
      } else {
        final direction = a.dx > size.width / 2 ? 1.0 : -1.0;
        path.cubicTo(
          a.dx + 60 * direction,
          a.dy,
          b.dx + 60 * direction,
          b.dy,
          b.dx,
          b.dy,
        );
      }
    }
    canvas.drawPath(
      path.shift(const Offset(0, 8)),
      Paint()
        ..color = const Color(0xFFD4C8A8)
        ..strokeWidth = 32
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFF5F0E8)
        ..strokeWidth = 28
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant PathPainter old) => old.points != points;
}
