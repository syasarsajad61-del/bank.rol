import 'tile_model.dart';

/// A property owned by a player, together with its build level and
/// mortgage flag. Level 1 means "plot", level 5 means "skyscraper".
class OwnedProperty {
  const OwnedProperty({
    required this.tileIndex,
    this.level = 1,
    this.mortgaged = false,
  });

  final int tileIndex;
  final int level;
  final bool mortgaged;

  TileModel get tile => TileModel.byIndex(tileIndex);

  OwnedProperty copyWith({int? level, bool? mortgaged}) => OwnedProperty(
        tileIndex: tileIndex,
        level: level ?? this.level,
        mortgaged: mortgaged ?? this.mortgaged,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'tileIndex': tileIndex,
        'level': level,
        'mortgaged': mortgaged,
      };

  factory OwnedProperty.fromJson(Map<String, dynamic> json) => OwnedProperty(
        tileIndex: (json['tileIndex'] as num?)?.toInt() ?? 0,
        level: ((json['level'] as num?)?.toInt() ?? 1).clamp(1, 5),
        mortgaged: (json['mortgaged'] as bool?) ?? false,
      );

  /// Book value used for net worth computation.
  int get marketValue {
    if (mortgaged) {
      return tile.mortgageValue;
    }
    return tile.price + tile.investedUpgradeValue(level);
  }
}

class PlayerModel {
  PlayerModel({
    required this.id,
    required this.name,
    required this.colorIndex,
    this.cash = 5000,
    this.position = 0,
    this.inJail = false,
    this.jailTurns = 0,
    this.bankrupt = false,
    this.connected = true,
    this.isHost = false,
    this.getOutOfJailCards = 0,
    Map<int, OwnedProperty>? properties,
    this.dealsCompleted = 0,
  }) : properties = Map<int, OwnedProperty>.unmodifiable(
          properties ?? const <int, OwnedProperty>{},
        );

  final String id;
  final String name;
  final int colorIndex;
  final int cash;
  final int position;
  final bool inJail;
  final int jailTurns;
  final bool bankrupt;
  final bool connected;
  final bool isHost;
  final int getOutOfJailCards;
  final Map<int, OwnedProperty> properties;
  final int dealsCompleted;

  static const int startingCash = 5000;

  int get propertyCount => properties.length;

  PlayerModel copyWith({
    String? name,
    int? colorIndex,
    int? cash,
    int? position,
    bool? inJail,
    int? jailTurns,
    bool? bankrupt,
    bool? connected,
    bool? isHost,
    int? getOutOfJailCards,
    Map<int, OwnedProperty>? properties,
    int? dealsCompleted,
  }) =>
      PlayerModel(
        id: id,
        name: name ?? this.name,
        colorIndex: colorIndex ?? this.colorIndex,
        cash: cash ?? this.cash,
        position: position ?? this.position,
        inJail: inJail ?? this.inJail,
        jailTurns: jailTurns ?? this.jailTurns,
        bankrupt: bankrupt ?? this.bankrupt,
        connected: connected ?? this.connected,
        isHost: isHost ?? this.isHost,
        getOutOfJailCards: getOutOfJailCards ?? this.getOutOfJailCards,
        properties: properties ?? this.properties,
        dealsCompleted: dealsCompleted ?? this.dealsCompleted,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'colorIndex': colorIndex,
        'cash': cash,
        'position': position,
        'inJail': inJail,
        'jailTurns': jailTurns,
        'bankrupt': bankrupt,
        'connected': connected,
        'isHost': isHost,
        'getOutOfJailCards': getOutOfJailCards,
        'properties': properties.map(
          (int key, OwnedProperty value) =>
              MapEntry<String, dynamic>('$key', value.toJson()),
        ),
        'dealsCompleted': dealsCompleted,
      };

  factory PlayerModel.fromJson(Map<String, dynamic> json) {
    final Map<int, OwnedProperty> props = <int, OwnedProperty>{};
    final dynamic rawProps = json['properties'];
    if (rawProps is Map) {
      rawProps.forEach((dynamic key, dynamic value) {
        final int? index = int.tryParse('$key');
        if (index != null && value is Map<String, dynamic>) {
          props[index] = OwnedProperty.fromJson(value);
        } else if (index != null && value is Map) {
          props[index] =
              OwnedProperty.fromJson(Map<String, dynamic>.from(value));
        }
      });
    }
    return PlayerModel(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? 'بازیکن',
      colorIndex: (json['colorIndex'] as num?)?.toInt() ?? 0,
      cash: (json['cash'] as num?)?.toInt() ?? startingCash,
      position: (json['position'] as num?)?.toInt() ?? 0,
      inJail: (json['inJail'] as bool?) ?? false,
      jailTurns: (json['jailTurns'] as num?)?.toInt() ?? 0,
      bankrupt: (json['bankrupt'] as bool?) ?? false,
      connected: (json['connected'] as bool?) ?? true,
      isHost: (json['isHost'] as bool?) ?? false,
      getOutOfJailCards: (json['getOutOfJailCards'] as num?)?.toInt() ?? 0,
      properties: props,
      dealsCompleted: (json['dealsCompleted'] as num?)?.toInt() ?? 0,
    );
  }

  /// Net worth = cash + book value of every owned property.
  int netWorth() {
    int total = cash;
    for (final OwnedProperty property in properties.values) {
      total += property.marketValue;
    }
    return total;
  }
}

/// Neon accent palette shared by tokens and UI.
class PlayerPalette {
  const PlayerPalette._();

  static const List<int> colors = <int>[
    0xFF00E5FF,
    0xFFFF2D95,
    0xFF39FF88,
    0xFFFFE54B,
    0xFFB14BFF,
    0xFFFF9F1C,
  ];

  static const List<String> namesFa = <String>[
    'فیروزه‌ای',
    'سرخابی',
    'سبز نئون',
    'زرد لیزری',
    'بنفش برقی',
    'نارنجی سایبری',
  ];

  static int colorFor(int index) =>
      colors[index % colors.length];
}
