// [R10][R11][R12][R13][R16][R25][T06] properties_data.dart
// محله‌های ایرانی — زاهدان
import '../models/city_property.dart';
import '../models/public_property.dart';

enum PropertyColor { turquoise, pink, orange, red, yellow, green }

class CityPropertyData {
  final String id;
  final String name;
  final String nameEn;
  final int price;
  final int baseRent;
  final int buildingCost;
  final PropertyColor block;
  const CityPropertyData({
    required this.id, required this.name, required this.nameEn,
    required this.price, required this.baseRent,
    required this.buildingCost, required this.block,
  });
}

class PublicPropertyData {
  final String id;
  final String name;
  final String nameEn;
  final int price;
  final int baseRent;
  const PublicPropertyData({
    required this.id, required this.name, required this.nameEn,
    required this.price, required this.baseRent,
  });
}

// ۱۵ محله — ۶ بلوک رنگی
const List<CityPropertyData> CITY_PROPERTIES = [
  // بلوک فیروزه‌ای — ارزان (سطح ۱)
  CityPropertyData(id: 'n_bozorgmehr', name: 'بزرگمهر', nameEn: 'Bozorgmehr',
    price: 60, baseRent: 4, buildingCost: 50, block: PropertyColor.turquoise),
  CityPropertyData(id: 'n_daneshju', name: 'دانشجو', nameEn: 'Daneshju',
    price: 60, baseRent: 4, buildingCost: 50, block: PropertyColor.turquoise),

  // بلوک صورتی — متوسط پایین (سطح ۲)
  CityPropertyData(id: 'n_kambuzia', name: 'کامبوزیا', nameEn: 'Kambuzia',
    price: 100, baseRent: 6, buildingCost: 50, block: PropertyColor.pink),
  CityPropertyData(id: 'n_zibashahr', name: 'زیباشهر', nameEn: 'Zibashahr',
    price: 100, baseRent: 6, buildingCost: 50, block: PropertyColor.pink),
  CityPropertyData(id: 'n_daneshgah', name: 'دانشگاه', nameEn: 'Daneshgah',
    price: 120, baseRent: 8, buildingCost: 60, block: PropertyColor.pink),

  // بلوک نارنجی — متوسط (سطح ۳)
  CityPropertyData(id: 'n_shirabad', name: 'شیرآباد', nameEn: 'Shirabad',
    price: 140, baseRent: 10, buildingCost: 70, block: PropertyColor.orange),
  CityPropertyData(id: 'n_karimabad', name: 'کریم‌آباد', nameEn: 'Karimabad',
    price: 140, baseRent: 10, buildingCost: 70, block: PropertyColor.orange),
  CityPropertyData(id: 'n_looriabad', name: 'لوری‌آباد', nameEn: 'Looriabad',
    price: 160, baseRent: 12, buildingCost: 80, block: PropertyColor.orange),

  // بلوک قرمز — متوسط بالا (سطح ۴)
  CityPropertyData(id: 'n_tehran', name: 'خیابان تهران', nameEn: 'Tehran St.',
    price: 180, baseRent: 14, buildingCost: 90, block: PropertyColor.red),
  CityPropertyData(id: 'n_bazaar', name: 'بازار بزرگ', nameEn: 'Grand Bazaar',
    price: 180, baseRent: 14, buildingCost: 90, block: PropertyColor.red),
  CityPropertyData(id: 'n_milad', name: 'شهرک میلاد', nameEn: 'Milad Town',
    price: 200, baseRent: 16, buildingCost: 100, block: PropertyColor.red),

  // بلوک زرد — بالا (سطح ۵)
  CityPropertyData(id: 'n_imamhossein', name: 'میدان امام حسین',
    nameEn: 'Imam Hossein Sq.', price: 220, baseRent: 18,
    buildingCost: 110, block: PropertyColor.yellow),
  CityPropertyData(id: 'n_ferdowsi', name: 'خیابان فردوسی',
    nameEn: 'Ferdowsi St.', price: 240, baseRent: 20,
    buildingCost: 120, block: PropertyColor.yellow),

  // بلوک سبز — خیلی بالا (سطح ۶)
  CityPropertyData(id: 'n_ghods', name: 'شهرک قدس', nameEn: 'Ghods Town',
    price: 280, baseRent: 22, buildingCost: 130, block: PropertyColor.green),
  CityPropertyData(id: 'n_khorramshahr', name: 'بلوار خرمشهر',
    nameEn: 'Khorramshahr Blvd', price: 300, baseRent: 25,
    buildingCost: 150, block: PropertyColor.green),
];

// ۳ ملک عمومی
const List<PublicPropertyData> PUBLIC_PROPERTIES = [
  PublicPropertyData(id: 'p_terminal', name: 'پایانهٔ مسافربری',
    nameEn: 'Bus Terminal', price: 180, baseRent: 20),
  PublicPropertyData(id: 'p_airport', name: 'فرودگاه زاهدان',
    nameEn: 'Zahedan Airport', price: 200, baseRent: 25),
  PublicPropertyData(id: 'p_border', name: 'بازار مرزی میرجاوه',
    nameEn: 'Mirjaveh Border Market', price: 220, baseRent: 30),
];

enum BoardSpaceType {
  start, city, publicProperty, chance, tax, auction,
  jail, goToJail, freeParking, bankPool,
}

class BoardSpace {
  final int index;
  final BoardSpaceType type;
  final String? propertyId;
  final int? taxAmount;
  final int? bonusAmount;
  const BoardSpace({
    required this.index, required this.type,
    this.propertyId, this.taxAmount, this.bonusAmount,
  });
}

const int BOARD_SIZE = 32;

const List<BoardSpace> BOARD = [
  BoardSpace(index: 0, type: BoardSpaceType.start),
  BoardSpace(index: 1, type: BoardSpaceType.city, propertyId: 'n_bozorgmehr'),
  BoardSpace(index: 2, type: BoardSpaceType.city, propertyId: 'n_daneshju'),
  BoardSpace(index: 3, type: BoardSpaceType.chance),
  BoardSpace(index: 4, type: BoardSpaceType.publicProperty, propertyId: 'p_terminal'),
  BoardSpace(index: 5, type: BoardSpaceType.tax, taxAmount: 100),
  BoardSpace(index: 6, type: BoardSpaceType.city, propertyId: 'n_kambuzia'),
  BoardSpace(index: 7, type: BoardSpaceType.city, propertyId: 'n_zibashahr'),
  BoardSpace(index: 8, type: BoardSpaceType.jail),
  BoardSpace(index: 9, type: BoardSpaceType.city, propertyId: 'n_daneshgah'),
  BoardSpace(index: 10, type: BoardSpaceType.publicProperty, propertyId: 'p_airport'),
  BoardSpace(index: 11, type: BoardSpaceType.auction),
  BoardSpace(index: 12, type: BoardSpaceType.city, propertyId: 'n_shirabad'),
  BoardSpace(index: 13, type: BoardSpaceType.chance),
  BoardSpace(index: 14, type: BoardSpaceType.city, propertyId: 'n_karimabad'),
  BoardSpace(index: 15, type: BoardSpaceType.city, propertyId: 'n_looriabad'),
  BoardSpace(index: 16, type: BoardSpaceType.freeParking, bonusAmount: 150),
  BoardSpace(index: 17, type: BoardSpaceType.city, propertyId: 'n_tehran'),
  BoardSpace(index: 18, type: BoardSpaceType.city, propertyId: 'n_bazaar'),
  BoardSpace(index: 19, type: BoardSpaceType.chance),
  BoardSpace(index: 20, type: BoardSpaceType.publicProperty, propertyId: 'p_border'),
  BoardSpace(index: 21, type: BoardSpaceType.city, propertyId: 'n_milad'),
  BoardSpace(index: 22, type: BoardSpaceType.auction),
  BoardSpace(index: 23, type: BoardSpaceType.city, propertyId: 'n_imamhossein'),
  BoardSpace(index: 24, type: BoardSpaceType.goToJail),
  BoardSpace(index: 25, type: BoardSpaceType.city, propertyId: 'n_ferdowsi'),
  BoardSpace(index: 26, type: BoardSpaceType.chance),
  BoardSpace(index: 27, type: BoardSpaceType.city, propertyId: 'n_ghods'),
  BoardSpace(index: 28, type: BoardSpaceType.tax, taxAmount: 150),
  BoardSpace(index: 29, type: BoardSpaceType.city, propertyId: 'n_khorramshahr'),
  BoardSpace(index: 30, type: BoardSpaceType.bankPool),
  BoardSpace(index: 31, type: BoardSpaceType.tax, taxAmount: 50),
];

const Map<int, double> BUILDING_RENT_MULTIPLIER = {
  0: 1.0, 1: 3.0, 2: 5.0, 3: 8.0,
};
const double BLOCK_BONUS_MULTIPLIER = 2.0;
