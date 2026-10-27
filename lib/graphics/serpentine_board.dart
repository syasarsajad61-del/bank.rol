// [G06][BL01-BL04][BL09][BL11][BL12] A river-like path through the city.
import 'package:flutter/material.dart';
import '../core/models/game_state.dart';
import '../core/data/properties_data.dart';
import '../core/rules/path_calculator.dart';
import '../ui/widgets/components.dart';
import 'path_painter.dart';
import 'neighborhood_background.dart';
import 'director_camera.dart';
import 'secret_contract_layer.dart';

class SerpentineBoard extends StatelessWidget {
  final GameState state;
  final String viewer;
  final bool reducedMotion;
  final void Function(BoardSpace) onSpace;
  const SerpentineBoard({
    super.key,
    required this.state,
    required this.viewer,
    required this.onSpace,
    this.reducedMotion = false,
  });
  @override
  Widget build(BuildContext c) => LayoutBuilder(
    builder: (c, b) {
      final landscape =
          MediaQuery.sizeOf(c).width > MediaQuery.sizeOf(c).height;
      final cols = landscape ? 4 : 8, rows = 32 ~/ cols;
      final small = MediaQuery.sizeOf(c).width < 360;
      final tileW = small ? 70.0 : 88.0, tileH = small ? 110.0 : 132.0;
      const gapX = 16.0, gapY = 80.0;
      final width = cols * (tileW + gapX) + 96,
          height = rows * (tileH + gapY) + 64;
      final points = PathCalculator.points(landscape: landscape)
          .map(
            (p) => Offset(
              48 + tileW / 2 + p.x * (cols - 1) * (tileW + gapX),
              32 + tileH / 2 + p.y * (rows - 1) * (tileH + gapY),
            ),
          )
          .toList();
      final focus = state.auction != null
          ? points[BOARD
                .firstWhere((s) => s.propertyId == state.auction!.propertyId)
                .index]
          : points[state.active.position];
      return Stack(
        children: [
          DirectorCamera(
            focus: focus,
            overviewEvent: state.phase,
            event:
                '${state.active.id}_${state.active.position}_${state.auction?.propertyId}_${state.phase}',
            reducedMotion: reducedMotion,
            child: SizedBox(
              width: width,
              height: height,
              child: Stack(
                children: [
                  const Positioned.fill(child: NeighborhoodBackground()),
                  Positioned.fill(
                    child: CustomPaint(painter: PathPainter(points)),
                  ),
                  for (final s in BOARD)
                    Positioned(
                      left: points[s.index].dx - tileW / 2,
                      top: points[s.index].dy - tileH / 2,
                      width: tileW,
                      height: tileH,
                      child: SpaceWidget(
                        space: s,
                        state: state,
                        onTap: () => onSpace(s),
                      ),
                    ),
                  Positioned.fill(
                    child: SecretContractLayer(
                      state: state,
                      viewer: viewer,
                      positions: points,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 8,
            left: 12,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .85),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'برای جابه‌جایی بکشید • برای زوم دو انگشت',
                  style: TextStyle(fontSize: 10),
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}
