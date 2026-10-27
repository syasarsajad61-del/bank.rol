// [R10][INSTR07] Reference board is coherent.
import 'package:flutter_test/flutter_test.dart';
import 'package:bankroll_plato/core/data/properties_data.dart';

void main() {
  test('32 indexed spaces reference 18 unique properties', () {
    expect(BOARD.length, 32);
    expect(BOARD.map((s) => s.index), List.generate(32, (i) => i));
    final ids = [
      ...CITY_PROPERTIES.map((q) => q.id),
      ...PUBLIC_PROPERTIES.map((q) => q.id),
    ];
    expect(ids.length, 18);
    expect(
      BOARD.where((s) => s.propertyId != null).map((s) => s.propertyId).toSet(),
      ids.toSet(),
    );
    expect([0, 8, 16, 24, 30].map((i) => BOARD[i].type), [
      BoardSpaceType.start,
      BoardSpaceType.jail,
      BoardSpaceType.freeParking,
      BoardSpaceType.goToJail,
      BoardSpaceType.bankPool,
    ]);
  });
}
