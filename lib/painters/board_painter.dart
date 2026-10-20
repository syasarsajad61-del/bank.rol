import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/tile_model.dart';
import '../theme.dart';
import 'building_painter.dart';
import 'dice_painter.dart';

/// Per-tile view model consumed by [BoardPainter].
class BoardTileView {
  const BoardTileView({
    this.ownerColor,
    this.level = 0,
    this.mortgaged = false,
    this.highlight = false,
  });

  final Color? ownerColor;
  final int level;
  final bool mortgaged;
  final bool highlight;
}

/// A player token on the board.
class PlayerMarker {
  const PlayerMarker({
    required this.position,
    required this.color,
    required this.isCurrent,
    this.initial = '',
    this.connected = true,
  });

  final int position;
  final Color color;
  final bool isCurrent;
  final String initial;
  final bool connected;
}

/// Shared board maths so the painter and any overlay widget agree
/// on exactly where a tile lives.
class BoardGeometry {
  BoardGeometry(this.size)
      : thickness = size * 0.150,
        cornerSize = size * 0.150;

  final double size;
  final double thickness;
  final double cornerSize;

  double get inner => size - thickness * 2;

  double get step => inner / 9.0;

  bool isCorner(int index) => index % 10 == 0;

  bool isBottomSide(int index) => index == 0 || (index >= 1 && index <= 10);

  bool isRightSide(int index) => index >= 10 && index <= 20;

  bool isTopSide(int index) => index >= 20 && index <= 30;

  bool isLeftSide(int index) => index >= 30 || index == 0;

  Rect tileRect(int index) {
    final int i = index % 40;
    if (i == 0) {
      return Rect.fromLTWH(0, size - cornerSize, cornerSize, cornerSize);
    }
    if (i == 10) {
      return Rect.fromLTWH(
          size - cornerSize, size - cornerSize, cornerSize, cornerSize);
    }
    if (i == 20) {
      return Rect.fromLTWH(size - cornerSize, 0, cornerSize, cornerSize);
    }
    if (i == 30) {
      return Rect.fromLTWH(0, 0, cornerSize, cornerSize);
    }
    if (i < 10) {
      final double x = cornerSize + (i - 1) * step;
      return Rect.fromLTWH(x, size - thickness, step, thickness);
    }
    if (i < 20) {
      final double y = size - cornerSize - (i - 10) * step;
      return Rect.fromLTWH(size - thickness, y, thickness, step);
    }
    if (i < 30) {
      final double x = size - cornerSize - (i - 20) * step;
      return Rect.fromLTWH(x, 0, step, thickness);
    }
    final double y = cornerSize + (i - 30) * step;
    return Rect.fromLTWH(0, y, thickness, step);
  }

  Offset tileCenter(int index) => tileRect(index).center;

  Rect get centerRect =>
      Rect.fromLTWH(thickness, thickness, inner, inner);

  int? tileAt(Offset point) {
    for (int i = 0; i < 40; i++) {
      if (tileRect(i).inflate(1).contains(point)) {
        return i;
      }
    }
    return null;
  }

  /// Which screen edge the tile's neon strip should hug.
  Alignment stripAlignment(int index) {
    final int i = index % 40;
    if (i == 0) {
      return const Alignment(1, 1);
    }
    if (i == 10) {
      return const Alignment(1, 1);
    }
    if (i == 20) {
      return const Alignment(1, -1);
    }
    if (i == 30) {
      return const Alignment(-1, -1);
    }
    if (i < 10) {
      return const Alignment(0, 1);
    }
    if (i < 20) {
      return const Alignment(1, 0);
    }
    if (i < 30) {
      return const Alignment(0, -1);
    }
    return const Alignment(-1, 0);
  }

  double textRotation(int index) {
    final int i = index % 40;
    if (i > 10 && i < 20) {
      return math.pi / 2;
    }
    if (i > 30) {
      return -math.pi / 2;
    }
    return 0;
  }
}

/// Paints the whole 40 tile ring, the buildings on top of it and the
/// player tokens. Intended to be laid out in a square box and then
/// tilted with a Matrix4 transform by the host widget.
class BoardPainter extends CustomPainter {
  BoardPainter({
    required this.tileViews,
    required this.markers,
    required this.diceA,
    required this.diceB,
    required this.round,
    required this.pulse,
    required this.revision,
    this.showDice = true,
    this.titleFa = 'نئون بانکرول',
  });

  final Map<int, BoardTileView> tileViews;
  final List<PlayerMarker> markers;
  final int diceA;
  final int diceB;
  final int round;
  final double pulse;
  final int revision;
  final bool showDice;
  final String titleFa;

  @override
  void paint(Canvas canvas, Size size) {
    final double side = math.min(size.width, size.height);
    final BoardGeometry geo = BoardGeometry(side);
    canvas.save();
    canvas.translate(
      (size.width - side) / 2,
      (size.height - side) / 2,
    );

    _paintBackground(canvas, side, geo);
    for (int i = 0; i < 40; i++) {
      _paintTile(canvas, geo, i);
    }
    _paintCenter(canvas, geo);
    _paintMarkers(canvas, geo);

    canvas.restore();
  }

  // ------------------------------------------------------------ background

  void _paintBackground(Canvas canvas, double side, BoardGeometry geo) {
    final Rect full = Rect.fromLTWH(0, 0, side, side);
    final RRect rounded = RRect.fromRectAndRadius(
      full,
      Radius.circular(side * 0.035),
    );
    canvas.drawRRect(
      rounded,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFF070B18),
            Color(0xFF0A1430),
            Color(0xFF06070F),
          ],
        ).createShader(full),
    );

    // Inner board plate.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        geo.centerRect.inflate(side * 0.014),
        Radius.circular(side * 0.03),
      ),
      Paint()..color = const Color(0xFF08101F),
    );

    // Neon grid inside the plate.
    final Paint grid = Paint()
      ..color = NeonColors.cyan.withValues(alpha: 0.06 + 0.03 * pulse)
      ..strokeWidth = 0.8;
    const int lines = 10;
    for (int i = 1; i < lines; i++) {
      final double t = geo.centerRect.left +
          geo.centerRect.width * i / lines;
      final double u =
          geo.centerRect.top + geo.centerRect.height * i / lines;
      canvas.drawLine(
        Offset(t, geo.centerRect.top),
        Offset(t, geo.centerRect.bottom),
        grid,
      );
      canvas.drawLine(
        Offset(geo.centerRect.left, u),
        Offset(geo.centerRect.right, u),
        grid,
      );
    }

    // Outer rim glow.
    canvas.drawRRect(
      rounded,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.4, side * 0.006)
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            NeonColors.cyan,
            NeonColors.magenta,
            NeonColors.violet,
            NeonColors.cyan,
          ],
        ).createShader(full),
    );
  }

  // ----------------------------------------------------------------- tiles

  void _paintTile(Canvas canvas, BoardGeometry geo, int index) {
    final TileModel tile = TileModel.byIndex(index);
    final Rect rect = geo.tileRect(index);
    final BoardTileView view = tileViews[index] ?? const BoardTileView();
    final RRect rounded = RRect.fromRectAndRadius(
      rect.deflate(rect.shortestSide * 0.035),
      Radius.circular(rect.shortestSide * 0.12),
    );

    final bool owned = view.ownerColor != null;
    canvas.drawRRect(
      rounded,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            owned
                ? Color.alphaBlend(
                    view.ownerColor!.withValues(alpha: 0.18),
                    const Color(0xFF0B1526),
                  )
                : const Color(0xFF0B1526),
            owned
                ? Color.alphaBlend(
                    view.ownerColor!.withValues(alpha: 0.07),
                    const Color(0xFF070C17),
                  )
                : const Color(0xFF070C17),
          ],
        ).createShader(rect),
    );

    if (view.highlight) {
      canvas.drawRRect(
        rounded,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.6, rect.shortestSide * 0.06)
          ..color = NeonColors.amber.withValues(alpha: 0.85),
      );
    }

    canvas.drawRRect(
      rounded,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.7, rect.shortestSide * 0.022)
        ..color = owned
            ? view.ownerColor!.withValues(alpha: 0.75)
            : Colors.white.withValues(alpha: 0.13),
    );

    // Group / type colour strip.
    _paintStrip(canvas, geo, index, rect, tile, view);

    // Building sprite for owned cities.
    if (tile.type == TileType.city && view.level > 0) {
      final Rect sprite = Rect.fromCenter(
        center: Offset(
          rect.center.dx,
          rect.center.dy + rect.shortestSide * 0.02,
        ),
        width: rect.shortestSide * 0.86,
        height: rect.shortestSide * 0.86,
      );
      BuildingPainter.drawBuilding(
        canvas,
        sprite,
        view.level,
        view.ownerColor ?? tile.color,
        pulse: pulse,
      );
    }

    _paintTileLabel(canvas, geo, index, rect, tile, view);
  }

  void _paintStrip(
    Canvas canvas,
    BoardGeometry geo,
    int index,
    Rect rect,
    TileModel tile,
    BoardTileView view,
  ) {
    if (geo.isCorner(index)) {
      return;
    }
    final Color base = tile.type == TileType.city
        ? tile.color
        : (view.ownerColor ?? tile.color);
    final Alignment align = geo.stripAlignment(index);
    final bool horizontal = align.y.abs() > align.x.abs();
    final double thickness = rect.shortestSide * (tile.type == TileType.city ? 0.20 : 0.13);

    Rect strip;
    if (horizontal) {
      strip = Rect.fromLTWH(
        rect.left,
        align.y > 0 ? rect.bottom - thickness : rect.top,
        rect.width,
        thickness,
      );
    } else {
      strip = Rect.fromLTWH(
        align.x > 0 ? rect.right - thickness : rect.left,
        rect.top,
        thickness,
        rect.height,
      );
    }
    strip = strip.deflate(rect.shortestSide * 0.05);

    canvas.drawRRect(
      RRect.fromRectAndRadius(strip, Radius.circular(thickness * 0.4)),
      Paint()
        ..shader = LinearGradient(
          colors: <Color>[
            base.withValues(alpha: 0.35),
            base.withValues(alpha: 0.95),
            base.withValues(alpha: 0.35),
          ],
        ).createShader(strip),
    );
  }

  void _paintTileLabel(
    Canvas canvas,
    BoardGeometry geo,
    int index,
    Rect rect,
    TileModel tile,
    BoardTileView view,
  ) {
    final int i = index % 40;
    final double rotation = geo.textRotation(i);
    final bool vertical = rotation != 0;

    canvas.save();
    canvas.translate(rect.center.dx, rect.center.dy);
    if (rotation != 0) {
      canvas.rotate(rotation);
    }

    if (geo.isCorner(i)) {
      final TextPainter corner = _measure(
        _glyphFor(tile.type),
        neonText(
          size: rect.shortestSide * 0.15,
          weight: FontWeight.w900,
          color: tile.color,
        ),
        maxWidth: rect.shortestSide * 0.8,
      );
      corner.paint(canvas, Offset(-corner.width / 2, -corner.height / 2));
      canvas.restore();
      return;
    }

    final double maxWidth = (vertical ? rect.height : rect.width) - 4;
    final double bodyHeight = vertical ? rect.width : rect.height;
    final double nameSize = (maxWidth * 0.16).clamp(4.5, 11.0).toDouble();

    final bool showBuilding = tile.type == TileType.city && view.level > 0;
    final bool showPrice = tile.isPurchasable && !showBuilding;

    final TextPainter namePainter = _measure(
      tile.name,
      neonText(size: nameSize, weight: FontWeight.w700, color: Colors.white),
      maxWidth: maxWidth,
    );
    namePainter.paint(
      canvas,
      Offset(-namePainter.width / 2, -bodyHeight * 0.30 - namePainter.height / 2),
    );

    if (showPrice) {
      final TextPainter pricePainter = _measure(
        '\$${tile.price}',
        neonText(
          size: nameSize * 0.85,
          weight: FontWeight.w600,
          color: view.ownerColor ?? NeonColors.textDim,
        ),
        maxWidth: maxWidth,
      );
      pricePainter.paint(
        canvas,
        Offset(
          -pricePainter.width / 2,
          bodyHeight * 0.30 - pricePainter.height / 2,
        ),
      );
    } else if (!tile.isPurchasable) {
      final TextPainter glyph = _measure(
        _glyphFor(tile.type),
        neonText(
          size: nameSize * 1.3,
          weight: FontWeight.w800,
          color: tile.color,
        ),
        maxWidth: maxWidth,
      );
      glyph.paint(
        canvas,
        Offset(-glyph.width / 2, bodyHeight * 0.26 - glyph.height / 2),
      );
    }

    if (view.mortgaged) {
      canvas.drawLine(
        Offset(-maxWidth * 0.30, 0),
        Offset(maxWidth * 0.30, 0),
        Paint()
          ..strokeWidth = math.max(1.0, rect.shortestSide * 0.05)
          ..color = NeonColors.danger.withValues(alpha: 0.9),
      );
    }

    canvas.restore();
  }

  String _glyphFor(TileType type) {
    switch (type) {
      case TileType.chance:
        return '؟';
      case TileType.community:
        return '★';
      case TileType.tax:
        return '٪';
      case TileType.go:
        return 'GO';
      case TileType.jail:
        return 'JAIL';
      case TileType.freeParking:
        return 'P';
      case TileType.goToJail:
        return '→JAIL';
      case TileType.transport:
        return '✈';
      case TileType.utility:
        return '⚡';
      case TileType.city:
        return '';
    }
  }

  // ---------------------------------------------------------------- center

  void _paintCenter(Canvas canvas, BoardGeometry geo) {
    final Rect center = geo.centerRect;

    final Paint halo = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          NeonColors.cyan.withValues(alpha: 0.10 + 0.05 * pulse),
          Colors.transparent,
        ],
      ).createShader(center);
    canvas.drawRect(center, halo);

    final TextPainter title = _measure(
      titleFa,
      neonText(
        size: center.width * 0.10,
        weight: FontWeight.w900,
        color: NeonColors.cyan,
        shadows: <Shadow>[
          Shadow(
            color: NeonColors.cyan.withValues(alpha: 0.75),
            blurRadius: center.width * 0.04,
          ),
          Shadow(
            color: NeonColors.magenta.withValues(alpha: 0.35),
            blurRadius: center.width * 0.08,
          ),
        ],
      ),
      maxWidth: center.width * 0.86,
      maxLines: 1,
    );
    title.paint(
      canvas,
      Offset(
        center.center.dx - title.width / 2,
        center.center.dy - title.height * 1.6,
      ),
    );

    final TextPainter subtitle = _measure(
      'دور ${_fa(round)} — بانک‌داری نئونی',
      neonText(
        size: center.width * 0.036,
        weight: FontWeight.w600,
        color: NeonColors.textDim,
      ),
      maxWidth: center.width * 0.8,
      maxLines: 1,
    );
    subtitle.paint(
      canvas,
      Offset(
        center.center.dx - subtitle.width / 2,
        center.top + center.height * 0.20,
      ),
    );

    if (showDice) {
      final double dieSize = center.width * 0.16;
      final double gap = center.width * 0.05;
      DicePainter.paintDie(
        canvas,
        Rect.fromCenter(
          center: Offset(center.center.dx - dieSize / 2 - gap / 2,
              center.center.dy + center.height * 0.14),
          width: dieSize,
          height: dieSize,
        ),
        diceB,
        NeonColors.magenta,
        tilt: -0.14,
      );
      DicePainter.paintDie(
        canvas,
        Rect.fromCenter(
          center: Offset(center.center.dx + dieSize / 2 + gap / 2,
              center.center.dy + center.height * 0.14),
          width: dieSize,
          height: dieSize,
        ),
        diceA,
        NeonColors.cyan,
        tilt: 0.10,
      );
    }
  }

  // --------------------------------------------------------------- markers

  void _paintMarkers(Canvas canvas, BoardGeometry geo) {
    final Map<int, List<PlayerMarker>> grouped =
        <int, List<PlayerMarker>>{};
    for (final PlayerMarker marker in markers) {
      grouped.putIfAbsent(marker.position % 40, () => <PlayerMarker>[]).add(
            marker,
          );
    }

    grouped.forEach((int position, List<PlayerMarker> group) {
      final Rect rect = geo.tileRect(position);
      final double r = rect.shortestSide * 0.17;
      // Push tokens towards the inner edge of the tile so the building
      // sprite on top of the plot stays readable.
      final Alignment strip = geo.stripAlignment(position);
      final Offset anchor = Offset(
        rect.center.dx - strip.x * rect.shortestSide * 0.24,
        rect.center.dy - strip.y * rect.shortestSide * 0.24,
      );
      for (int i = 0; i < group.length; i++) {
        final PlayerMarker marker = group[i];
        final double angle = group.length == 1
            ? -math.pi / 2
            : (i / group.length) * math.pi * 2 - math.pi / 2;
        final double orbit = group.length == 1 ? 0 : r * 1.35;
        final Offset c = Offset(
          anchor.dx + math.cos(angle) * orbit,
          anchor.dy + math.sin(angle) * orbit,
        );

        if (marker.isCurrent) {
          canvas.drawCircle(
            c,
            r * 3.2,
            Paint()
              ..color = marker.color.withValues(alpha: 0.34 + 0.26 * pulse)
              ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 1.9),
          );
        }

        final Path hex = _hexagon(c, r);
        canvas.drawPath(
          hex,
          Paint()
            ..shader = RadialGradient(
              colors: <Color>[
                Color.lerp(marker.color, Colors.white, 0.65)!,
                marker.color,
                Color.lerp(marker.color, Colors.black, 0.55)!,
              ],
              stops: const <double>[0.0, 0.55, 1.0],
            ).createShader(Rect.fromCircle(center: c, radius: r)),
        );
        canvas.drawPath(
          hex,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = math.max(1.2, r * 0.20)
            ..color = Colors.white.withValues(alpha: 0.92),
        );
        if (!marker.connected) {
          canvas.drawPath(
            hex,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = math.max(1.4, r * 0.26)
              ..color = NeonColors.danger.withValues(alpha: 0.95),
          );
        }
      }
    });
  }

  Path _hexagon(Offset center, double radius) {
    final Path path = Path();
    for (int i = 0; i < 6; i++) {
      final double a = math.pi / 6 + i * math.pi / 3;
      final Offset p = Offset(
        center.dx + math.cos(a) * radius,
        center.dy + math.sin(a) * radius,
      );
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    return path;
  }

  // --------------------------------------------------------------- helpers

  TextPainter _measure(
    String text,
    TextStyle style, {
    required double maxWidth,
    int maxLines = 1,
  }) {
    final TextPainter painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.center,
      maxLines: maxLines,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth <= 0 ? 1 : maxWidth);
    return painter;
  }

  String _fa(int value) {
    const List<String> digits = <String>[
      '۰',
      '۱',
      '۲',
      '۳',
      '۴',
      '۵',
      '۶',
      '۷',
      '۸',
      '۹',
    ];
    final StringBuffer buffer = StringBuffer();
    for (final int unit in value.toString().codeUnits) {
      final int digit = unit - 0x30;
      if (digit >= 0 && digit <= 9) {
        buffer.write(digits[digit]);
      } else {
        buffer.writeCharCode(unit);
      }
    }
    return buffer.toString();
  }

  @override
  bool shouldRepaint(covariant BoardPainter oldDelegate) =>
      oldDelegate.revision != revision ||
      oldDelegate.pulse != pulse ||
      oldDelegate.diceA != diceA ||
      oldDelegate.diceB != diceB ||
      oldDelegate.round != round ||
      oldDelegate.markers.length != markers.length;
}
