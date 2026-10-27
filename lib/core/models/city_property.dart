// [R10][R13] Typed neighborhood property.
import 'game_state.dart';
import '../data/properties_data.dart';

class CityProperty extends Property {
  CityProperty(CityPropertyData data)
    : super(
        id: data.id,
        name: data.name,
        price: data.price,
        baseRent: data.baseRent,
        buildingCost: data.buildingCost,
        block: data.block,
      );
}
