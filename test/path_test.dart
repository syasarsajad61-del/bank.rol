// [BL01][BL12] Each row alternates direction and wrap visits start.
import 'package:flutter_test/flutter_test.dart';
import 'package:bankroll_plato/core/rules/path_calculator.dart';

void main() {
  test('serpentine portrait and landscape geometry', () {
    for (final landscape in [false, true]) {
      final p = PathCalculator.points(landscape: landscape);
      final cols = landscape ? 4 : 8;
      expect(p.length, 32);
      expect(p.map((p) => '${p.x},${p.y}').toSet().length, 32);
      expect(p[0].x, 0);
      expect(p[cols - 1].x, 1);
      expect(p[cols].x, 1);
      expect(p[cols * 2 - 1].x, 0);
      expect(p.last.y, 1);
    }
  });
  test('movement wraps through start', () {
    expect(PathCalculator.steps(30, 4), [31, 0, 1, 2]);
  });
}
