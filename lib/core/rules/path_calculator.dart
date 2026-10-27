// [BL01][BL12] Portrait 4x8; landscape 8x4, with alternating direction.
import '../models/board_path_point.dart';

class PathCalculator {
  static List<BoardPathPoint> points({bool landscape = false}) {
    final columns = landscape ? 4 : 8;
    final rows = 32 ~/ columns;
    return List.generate(32, (i) {
      final r = i ~/ columns, c = i % columns;
      return BoardPathPoint(
        i,
        (r.isEven ? c : columns - 1 - c) / (columns - 1),
        r / (rows - 1),
      );
    });
  }

  static List<int> steps(int start, int dice) =>
      List.generate(dice, (i) => (start + i + 1) % 32);
}
