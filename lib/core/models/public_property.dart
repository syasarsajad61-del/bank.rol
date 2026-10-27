// [R10][R12] Typed public property.
import 'game_state.dart';
import '../data/properties_data.dart';

class PublicProperty extends Property {
  PublicProperty(PublicPropertyData data)
    : super(
        id: data.id,
        name: data.name,
        price: data.price,
        baseRent: data.baseRent,
      );
}
