// [R27][T07] Independent numeric expectations for the locked formula.
import 'package:flutter_test/flutter_test.dart';
import 'package:bankroll_plato/core/rules/rent_calculator.dart';
import 'test_helpers.dart';

void main() {
  test('all eight factors multiply exactly', () {
    expect(
      RentCalculator.calculate(
        base: 10,
        phaseMult: 1.4,
        inflation: .1,
        blockMult: 2,
        publicMult: 3,
        insuranceMult: .5,
        lawMult: 1.2,
        buildingMult: 5,
      ),
      closeTo(277.2, .00001),
    );
  });
  test('complete block and building compound', () {
    final s = fixture(), p = s.active;
    for (final q in s.properties.where(
      (q) => q.block == s.properties.first.block,
    )) {
      q.owner = p.id;
    }
    final q = s.properties.first;
    q.buildings = 1;
    expect(RentCalculator.of(s, q, s.players.last), 24);
  });
  test('public count scales public rent', () {
    final s = fixture();
    for (final q in s.properties.where((q) => q.isPublic)) {
      q.owner = s.active.id;
    }
    final q = s.properties.firstWhere((q) => q.isPublic);
    expect(RentCalculator.of(s, q, s.players.last), 60);
  });
}
