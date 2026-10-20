import 'dart:ui' show Color;

/// The kind of cell that sits on the 40 tile ring.
enum TileType {
  go,
  city,
  transport,
  utility,
  chance,
  community,
  jail,
  freeParking,
  goToJail,
  tax,
}

extension TileTypeX on TileType {
  bool get isPurchasable =>
      this == TileType.city ||
      this == TileType.transport ||
      this == TileType.utility;

  bool get isCity => this == TileType.city;

  /// Persian label used in dialogs / legends.
  String get labelFa {
    switch (this) {
      case TileType.go:
        return 'شروع';
      case TileType.city:
        return 'شهر';
      case TileType.transport:
        return 'حمل‌ونقل';
      case TileType.utility:
        return 'خدمات شهری';
      case TileType.chance:
        return 'شانس';
      case TileType.community:
        return 'همیاری';
      case TileType.jail:
        return 'بازداشتگاه';
      case TileType.freeParking:
        return 'پارکینگ آزاد';
      case TileType.goToJail:
        return 'برو به بازداشتگاه';
      case TileType.tax:
        return 'مالیات';
    }
  }
}

/// A single immutable board cell.
class TileModel {
  const TileModel({
    required this.index,
    required this.type,
    required this.name,
    required this.description,
    this.price = 0,
    this.baseRent = 0,
    this.groupId = -1,
    this.colorValue = 0xFF00E5FF,
    this.taxAmount = 0,
  });

  final int index;
  final TileType type;
  final String name;
  final String description;
  final int price;
  final int baseRent;

  /// 0..7 for colour groups, -1 when the tile does not belong to a group.
  final int groupId;
  final int colorValue;
  final int taxAmount;

  Color get color => Color(colorValue);

  bool get isPurchasable => type.isPurchasable;

  /// Human readable price tag used across the UI.
  String get priceLabel => isPurchasable ? '\$$price' : '';

  Map<String, dynamic> toJson() => <String, dynamic>{
        'index': index,
        'type': type.name,
        'name': name,
        'description': description,
        'price': price,
        'baseRent': baseRent,
        'groupId': groupId,
        'colorValue': colorValue,
        'taxAmount': taxAmount,
      };

  factory TileModel.fromJson(Map<String, dynamic> json) {
    final String typeName = (json['type'] as String?) ?? TileType.city.name;
    final TileType parsed = TileType.values.firstWhere(
      (TileType t) => t.name == typeName,
      orElse: () => TileType.city,
    );
    return TileModel(
      index: (json['index'] as num?)?.toInt() ?? 0,
      type: parsed,
      name: (json['name'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      price: (json['price'] as num?)?.toInt() ?? 0,
      baseRent: (json['baseRent'] as num?)?.toInt() ?? 0,
      groupId: (json['groupId'] as num?)?.toInt() ?? -1,
      colorValue: (json['colorValue'] as num?)?.toInt() ?? 0xFF00E5FF,
      taxAmount: (json['taxAmount'] as num?)?.toInt() ?? 0,
    );
  }

  static TileModel byIndex(int index) =>
      (index >= 0 && index < board.length) ? board[index] : board[0];

  /// The canonical 40 tile ring.
  ///
  /// 22 cities, 4 transports, 2 utilities, 3 chance, 3 community,
  /// start, jail, free parking, go-to-jail and 2 taxes.
  static const List<TileModel> board = <TileModel>[
    TileModel(
      index: 0,
      type: TileType.go,
      name: 'شروع',
      description: 'با عبور از این خانه ۵۰۰ دلار دریافت می‌کنید.',
      colorValue: 0xFF39FF88,
    ),
    TileModel(
      index: 1,
      type: TileType.city,
      name: 'تهران',
      description: 'پایتخت نئونی؛ قلب تپنده اقتصاد.',
      price: 600,
      baseRent: 25,
      groupId: 0,
      colorValue: 0xFFB14BFF,
    ),
    TileModel(
      index: 2,
      type: TileType.community,
      name: 'همیاری',
      description: 'کارت همیاری شهروندان را بردارید.',
      colorValue: 0xFF00E5FF,
    ),
    TileModel(
      index: 3,
      type: TileType.city,
      name: 'مشهد',
      description: 'قطب زیارتی و تجاری شرق کشور.',
      price: 800,
      baseRent: 35,
      groupId: 0,
      colorValue: 0xFFB14BFF,
    ),
    TileModel(
      index: 4,
      type: TileType.tax,
      name: 'مالیات بر درآمد',
      description: 'پرداخت ۲۰۰ دلار مالیات بر درآمد.',
      taxAmount: 200,
      colorValue: 0xFFFF3B3B,
    ),
    TileModel(
      index: 5,
      type: TileType.transport,
      name: 'فرودگاه امام خمینی',
      description: 'کریدور هوایی بین‌المللی.',
      price: 1200,
      baseRent: 60,
      groupId: 8,
      colorValue: 0xFF9AA6FF,
    ),
    TileModel(
      index: 6,
      type: TileType.city,
      name: 'اصفهان',
      description: 'نگین معماری ایران و مرکز فناوری.',
      price: 1000,
      baseRent: 45,
      groupId: 1,
      colorValue: 0xFF00E5FF,
    ),
    TileModel(
      index: 7,
      type: TileType.chance,
      name: 'شانس',
      description: 'کارت شانس را بردارید.',
      colorValue: 0xFFFFE54B,
    ),
    TileModel(
      index: 8,
      type: TileType.city,
      name: 'شیراز',
      description: 'شهر شعر و داده‌های کلان.',
      price: 1200,
      baseRent: 55,
      groupId: 1,
      colorValue: 0xFF00E5FF,
    ),
    TileModel(
      index: 9,
      type: TileType.city,
      name: 'تبریز',
      description: 'دروازه تجارت شمال‌غرب.',
      price: 1400,
      baseRent: 65,
      groupId: 1,
      colorValue: 0xFF00E5FF,
    ),
    TileModel(
      index: 10,
      type: TileType.jail,
      name: 'بازداشتگاه',
      description: 'فقط ملاقات؛ گرفتاران اینجا می‌مانند.',
      colorValue: 0xFFFF9F1C,
    ),
    TileModel(
      index: 11,
      type: TileType.city,
      name: 'کرج',
      description: 'حاشیه پرترافیک پایتخت.',
      price: 1600,
      baseRent: 75,
      groupId: 2,
      colorValue: 0xFFFF2D95,
    ),
    TileModel(
      index: 12,
      type: TileType.utility,
      name: 'شرکت برق شهری',
      description: 'شبکه توزیع انرژی نئون.',
      price: 1200,
      baseRent: 40,
      groupId: 9,
      colorValue: 0xFFFFE54B,
    ),
    TileModel(
      index: 13,
      type: TileType.city,
      name: 'اهواز',
      description: 'پایتخت انرژی و پتروشیمی.',
      price: 1800,
      baseRent: 85,
      groupId: 2,
      colorValue: 0xFFFF2D95,
    ),
    TileModel(
      index: 14,
      type: TileType.city,
      name: 'قم',
      description: 'گره لجستیک مرکزی کشور.',
      price: 2000,
      baseRent: 95,
      groupId: 2,
      colorValue: 0xFFFF2D95,
    ),
    TileModel(
      index: 15,
      type: TileType.transport,
      name: 'راه‌آهن سراسری',
      description: 'شریان ریلی کشور.',
      price: 1200,
      baseRent: 60,
      groupId: 8,
      colorValue: 0xFF9AA6FF,
    ),
    TileModel(
      index: 16,
      type: TileType.city,
      name: 'کرمانشاه',
      description: 'دروازه غرب و صنایع سنگین.',
      price: 2200,
      baseRent: 105,
      groupId: 3,
      colorValue: 0xFFFF9F1C,
    ),
    TileModel(
      index: 17,
      type: TileType.community,
      name: 'همیاری',
      description: 'کارت همیاری شهروندان را بردارید.',
      colorValue: 0xFF00E5FF,
    ),
    TileModel(
      index: 18,
      type: TileType.city,
      name: 'ارومیه',
      description: 'مرکز کشاورزی و آب شیرین.',
      price: 2400,
      baseRent: 115,
      groupId: 3,
      colorValue: 0xFFFF9F1C,
    ),
    TileModel(
      index: 19,
      type: TileType.city,
      name: 'رشت',
      description: 'بندر سبز شمال.',
      price: 2600,
      baseRent: 125,
      groupId: 3,
      colorValue: 0xFFFF9F1C,
    ),
    TileModel(
      index: 20,
      type: TileType.freeParking,
      name: 'پارکینگ آزاد',
      description: 'جریمه‌های انباشته این پارکینگ را بردارید.',
      colorValue: 0xFF39FF88,
    ),
    TileModel(
      index: 21,
      type: TileType.city,
      name: 'زاهدان',
      description: 'گمرک شرقی و ترانزیت.',
      price: 2800,
      baseRent: 135,
      groupId: 4,
      colorValue: 0xFFFF3B3B,
    ),
    TileModel(
      index: 22,
      type: TileType.chance,
      name: 'شانس',
      description: 'کارت شانس را بردارید.',
      colorValue: 0xFFFFE54B,
    ),
    TileModel(
      index: 23,
      type: TileType.city,
      name: 'همدان',
      description: 'قطب گردشگری و تاریخ.',
      price: 3000,
      baseRent: 145,
      groupId: 4,
      colorValue: 0xFFFF3B3B,
    ),
    TileModel(
      index: 24,
      type: TileType.city,
      name: 'کرمان',
      description: 'معدن و صنایع معدنی.',
      price: 3200,
      baseRent: 155,
      groupId: 4,
      colorValue: 0xFFFF3B3B,
    ),
    TileModel(
      index: 25,
      type: TileType.transport,
      name: 'پایانه باربری',
      description: 'هاب حمل کالای کشور.',
      price: 1200,
      baseRent: 60,
      groupId: 8,
      colorValue: 0xFF9AA6FF,
    ),
    TileModel(
      index: 26,
      type: TileType.city,
      name: 'یزد',
      description: 'شهر بادگیرها و معماری پایدار.',
      price: 3400,
      baseRent: 165,
      groupId: 5,
      colorValue: 0xFFFFE54B,
    ),
    TileModel(
      index: 27,
      type: TileType.city,
      name: 'اردبیل',
      description: 'انرژی زمین‌گرمایی و گردشگری.',
      price: 3600,
      baseRent: 175,
      groupId: 5,
      colorValue: 0xFFFFE54B,
    ),
    TileModel(
      index: 28,
      type: TileType.utility,
      name: 'آب و فاضلاب',
      description: 'زیرساخت حیاتی شهری.',
      price: 1200,
      baseRent: 40,
      groupId: 9,
      colorValue: 0xFF6FD3FF,
    ),
    TileModel(
      index: 29,
      type: TileType.city,
      name: 'بندرعباس',
      description: 'بزرگ‌ترین بندر تجاری جنوب.',
      price: 3800,
      baseRent: 185,
      groupId: 5,
      colorValue: 0xFFFFE54B,
    ),
    TileModel(
      index: 30,
      type: TileType.goToJail,
      name: 'برو به بازداشتگاه',
      description: 'مستقیم به بازداشتگاه بروید.',
      colorValue: 0xFFFF3B3B,
    ),
    TileModel(
      index: 31,
      type: TileType.city,
      name: 'اراک',
      description: 'قطب صنایع ماشین‌سازی.',
      price: 4000,
      baseRent: 195,
      groupId: 6,
      colorValue: 0xFF39FF88,
    ),
    TileModel(
      index: 32,
      type: TileType.city,
      name: 'قزوین',
      description: 'کریدور صنعتی تهران-تبریز.',
      price: 4200,
      baseRent: 205,
      groupId: 6,
      colorValue: 0xFF39FF88,
    ),
    TileModel(
      index: 33,
      type: TileType.community,
      name: 'همیاری',
      description: 'کارت همیاری شهروندان را بردارید.',
      colorValue: 0xFF00E5FF,
    ),
    TileModel(
      index: 34,
      type: TileType.city,
      name: 'ساری',
      description: 'دروازه جنگل و دریا.',
      price: 4400,
      baseRent: 215,
      groupId: 6,
      colorValue: 0xFF39FF88,
    ),
    TileModel(
      index: 35,
      type: TileType.transport,
      name: 'ایستگاه مترو',
      description: 'شبکه ریلی درون‌شهری.',
      price: 1200,
      baseRent: 60,
      groupId: 8,
      colorValue: 0xFF9AA6FF,
    ),
    TileModel(
      index: 36,
      type: TileType.chance,
      name: 'شانس',
      description: 'کارت شانس را بردارید.',
      colorValue: 0xFFFFE54B,
    ),
    TileModel(
      index: 37,
      type: TileType.city,
      name: 'بوشهر',
      description: 'پایانه گازی و انرژی جنوب.',
      price: 4600,
      baseRent: 225,
      groupId: 7,
      colorValue: 0xFF2D7BFF,
    ),
    TileModel(
      index: 38,
      type: TileType.tax,
      name: 'مالیات تجملی',
      description: 'پرداخت ۱۵۰ دلار مالیات تجملی.',
      taxAmount: 150,
      colorValue: 0xFFFF3B3B,
    ),
    TileModel(
      index: 39,
      type: TileType.city,
      name: 'سنندج',
      description: 'درگاه غربی و گردشگری کوهستان.',
      price: 4800,
      baseRent: 235,
      groupId: 7,
      colorValue: 0xFF2D7BFF,
    ),
  ];

  /// Build level 1..5 costs (index 0 is unused).
  static const List<double> levelCostFactors = <double>[
    0.0,
    0.0,
    0.6,
    0.9,
    1.4,
    2.1,
  ];

  /// Rent multiplier per level, starting at level 1.
  static const List<int> rentMultipliers = <int>[1, 1, 3, 7, 15, 30];

  static const List<String> levelNamesFa = <String>[
    'خالی',
    'زمین',
    'خانه',
    'آپارتمان',
    'مرکز خرید',
    'آسمان‌خراش',
  ];

  /// Cost to upgrade from [level] to [level] + 1.
  int upgradeCostFrom(int level) {
    if (level >= 5 || !type.isCity) {
      return 0;
    }
    final double factor = levelCostFactors[(level + 1).clamp(1, 5)];
    return (price * factor).round();
  }

  /// Total invested capital into buildings up to [level].
  int investedUpgradeValue(int level) {
    int total = 0;
    for (int l = 1; l < level && l < 5; l++) {
      total += upgradeCostFrom(l);
    }
    return total;
  }

  /// Rent for a city at [level]. Owns full group doubles the roll.
  int cityRent(int level, {bool ownsGroup = false}) {
    final int safeLevel = level.clamp(1, 5);
    int rent = baseRent * rentMultipliers[safeLevel];
    if (ownsGroup) {
      rent = rent * 2;
    }
    return rent;
  }

  int transportRent(int ownedCount) {
    final int count = ownedCount.clamp(1, 4);
    return baseRent * count;
  }

  int utilityRent(int diceTotal, int ownedCount) {
    final int multiplier = ownedCount >= 2 ? 10 : 4;
    return diceTotal * multiplier;
  }

  int get mortgageValue => (price * 0.5).round();
  int get unmortgageCost => (price * 0.55).round();
}
