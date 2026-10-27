// [R22][T07] Clamping happens before the final half factor.
import 'package:flutter_test/flutter_test.dart';
import 'package:bankroll_plato/core/rules/inflation.dart';

void main() {
  test('upper lower neutral and zero baseline', () {
    expect(Inflation.calculate(200, 100), .2);
    expect(Inflation.calculate(1, 100), -.15);
    expect(Inflation.calculate(100, 100), 0);
    expect(Inflation.calculate(110, 100), closeTo(.05, 1e-9));
    expect(Inflation.calculate(100, 0), 0);
  });
}
