/// Which pile a card belongs to.
enum CardDeck {
  chance,
  community,
}

extension CardDeckX on CardDeck {
  String get labelFa =>
      this == CardDeck.chance ? 'کارت شانس' : 'کارت همیاری';
}

/// The mechanical effect encoded on a card. The host engine interprets
/// every value; clients only render [GameCard.title]/[description].
enum CardEffect {
  collectCash,
  payCash,
  moveToGo,
  goToJail,
  heist,
  sabotage,
  teleport,
  moveBy,
  collectPerProperty,
  payPerBuilding,
  getOutOfJail,
  freeUpgrade,
  collectFromEach,
  payEach,
  advanceNearestTransport,
}

/// A single immutable event card.
class GameCard {
  const GameCard({
    required this.id,
    required this.deck,
    required this.title,
    required this.description,
    required this.effect,
    this.amount = 0,
    this.ratio = 0,
    this.targetTile = 0,
  });

  final String id;
  final CardDeck deck;
  final String title;
  final String description;
  final CardEffect effect;
  final int amount;
  final double ratio;
  final int targetTile;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'deck': deck.name,
        'title': title,
        'description': description,
        'effect': effect.name,
        'amount': amount,
        'ratio': ratio,
        'targetTile': targetTile,
      };

  factory GameCard.fromJson(Map<String, dynamic> json) {
    return GameCard(
      id: (json['id'] as String?) ?? '',
      deck: CardDeck.values.firstWhere(
        (CardDeck d) => d.name == (json['deck'] as String?),
        orElse: () => CardDeck.chance,
      ),
      title: (json['title'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      effect: CardEffect.values.firstWhere(
        (CardEffect e) => e.name == (json['effect'] as String?),
        orElse: () => CardEffect.collectCash,
      ),
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      ratio: (json['ratio'] as num?)?.toDouble() ?? 0,
      targetTile: (json['targetTile'] as num?)?.toInt() ?? 0,
    );
  }

  /// All 12 chance cards.
  static const List<GameCard> chanceCards = <GameCard>[
    GameCard(
      id: 'ch_01',
      deck: CardDeck.chance,
      title: 'سود شبکه',
      description: 'یک معامله پر سود انجام دادید. ۵۰۰ دلار دریافت کنید.',
      effect: CardEffect.collectCash,
      amount: 500,
    ),
    GameCard(
      id: 'ch_02',
      deck: CardDeck.chance,
      title: 'هزینه نگهداری سرور',
      description: 'سرورهای شما داغ کردند. ۳۰۰ دلار بپردازید.',
      effect: CardEffect.payCash,
      amount: 300,
    ),
    GameCard(
      id: 'ch_03',
      deck: CardDeck.chance,
      title: 'سرقت سایبری',
      description:
          '۱۰٪ از موجودی نقدی ثروتمندترین بازیکن را هک کردید و برداشتید.',
      effect: CardEffect.heist,
      ratio: 0.10,
    ),
    GameCard(
      id: 'ch_04',
      deck: CardDeck.chance,
      title: 'خرابکاری صنعتی',
      description:
          'یکی از ساختمان‌های یک رقیب تصادفی یک سطح تنزل پیدا می‌کند.',
      effect: CardEffect.sabotage,
    ),
    GameCard(
      id: 'ch_05',
      deck: CardDeck.chance,
      title: 'بازگشت به خانه',
      description: 'مستقیم به خانه شروع بروید و ۵۰۰ دلار بگیرید.',
      effect: CardEffect.moveToGo,
    ),
    GameCard(
      id: 'ch_06',
      deck: CardDeck.chance,
      title: 'دستگیری توسط پلیس سایبری',
      description: 'مستقیم به بازداشتگاه بروید. از عبور از شروع خبری نیست.',
      effect: CardEffect.goToJail,
    ),
    GameCard(
      id: 'ch_07',
      deck: CardDeck.chance,
      title: 'پرواز اضطراری',
      description: 'به نزدیک‌ترین ایستگاه حمل‌ونقل بروید.',
      effect: CardEffect.advanceNearestTransport,
    ),
    GameCard(
      id: 'ch_08',
      deck: CardDeck.chance,
      title: 'درآمد اجاره',
      description:
          'برای هر ملکی که در اختیار دارید ۲۰۰ دلار اجاره معوقه دریافت کنید.',
      effect: CardEffect.collectPerProperty,
      amount: 200,
    ),
    GameCard(
      id: 'ch_09',
      deck: CardDeck.chance,
      title: 'بازرسی ایمنی',
      description: 'برای هر سطح ساختمان ۱۰۰ دلار جریمه بپردازید.',
      effect: CardEffect.payPerBuilding,
      amount: 100,
    ),
    GameCard(
      id: 'ch_10',
      deck: CardDeck.chance,
      title: 'کارت طلایی آزادی',
      description: 'یک کارت خروج از بازداشتگاه دریافت می‌کنید.',
      effect: CardEffect.getOutOfJail,
    ),
    GameCard(
      id: 'ch_11',
      deck: CardDeck.chance,
      title: 'جهش کوانتومی',
      description: 'سه خانه به جلو حرکت کنید.',
      effect: CardEffect.moveBy,
      amount: 3,
    ),
    GameCard(
      id: 'ch_12',
      deck: CardDeck.chance,
      title: 'تلپورت به کرمان',
      description: 'به صورت آنی به خانه کرمان منتقل می‌شوید.',
      effect: CardEffect.teleport,
      targetTile: 24,
    ),
  ];

  /// All 12 community cards.
  static const List<GameCard> communityCards = <GameCard>[
    GameCard(
      id: 'co_01',
      deck: CardDeck.community,
      title: 'سود سهام شهری',
      description: '۴۰۰ دلار سود سهام از صندوق شهروندی دریافت کنید.',
      effect: CardEffect.collectCash,
      amount: 400,
    ),
    GameCard(
      id: 'co_02',
      deck: CardDeck.community,
      title: 'هزینه تعمیرات',
      description: '۲۵۰ دلار برای تعمیرات شبکه شهری بپردازید.',
      effect: CardEffect.payCash,
      amount: 250,
    ),
    GameCard(
      id: 'co_03',
      deck: CardDeck.community,
      title: 'ارتقای رایگان',
      description: 'یکی از ملک‌های شما یک سطح رایگان ارتقا می‌یابد.',
      effect: CardEffect.freeUpgrade,
    ),
    GameCard(
      id: 'co_04',
      deck: CardDeck.community,
      title: 'کمک‌هزینه شهروندان',
      description: 'هر بازیکن دیگر ۱۰۰ دلار به شما پرداخت می‌کند.',
      effect: CardEffect.collectFromEach,
      amount: 100,
    ),
    GameCard(
      id: 'co_05',
      deck: CardDeck.community,
      title: 'ضیافت نئونی',
      description: 'به هر بازیکن دیگر ۵۰ دلار بپردازید.',
      effect: CardEffect.payEach,
      amount: 50,
    ),
    GameCard(
      id: 'co_06',
      deck: CardDeck.community,
      title: 'جایزه نوآوری',
      description: 'برای ایده نوآورانه ۳۰۰ دلار جایزه بگیرید.',
      effect: CardEffect.collectCash,
      amount: 300,
    ),
    GameCard(
      id: 'co_07',
      deck: CardDeck.community,
      title: 'مالیات محلی',
      description: '۲۰۰ دلار مالیات محلی بپردازید.',
      effect: CardEffect.payCash,
      amount: 200,
    ),
    GameCard(
      id: 'co_08',
      deck: CardDeck.community,
      title: 'بازگشت به نقطه صفر',
      description: 'به خانه شروع برگردید و ۵۰۰ دلار دریافت کنید.',
      effect: CardEffect.moveToGo,
    ),
    GameCard(
      id: 'co_09',
      deck: CardDeck.community,
      title: 'کمک مالی دولت',
      description: '۶۰۰ دلار بسته حمایتی دریافت کنید.',
      effect: CardEffect.collectCash,
      amount: 600,
    ),
    GameCard(
      id: 'co_10',
      deck: CardDeck.community,
      title: 'جریمه زیست‌محیطی',
      description: '۳۵۰ دلار جریمه آلودگی هوا بپردازید.',
      effect: CardEffect.payCash,
      amount: 350,
    ),
    GameCard(
      id: 'co_11',
      deck: CardDeck.community,
      title: 'ریزش بازار',
      description: 'پنج خانه به عقب حرکت کنید.',
      effect: CardEffect.moveBy,
      amount: -5,
    ),
    GameCard(
      id: 'co_12',
      deck: CardDeck.community,
      title: 'قرعه‌کشی شهروندی',
      description: '۲۰۰ دلار و یک کارت خروج از بازداشتگاه دریافت کنید.',
      effect: CardEffect.getOutOfJail,
      amount: 200,
    ),
  ];

  static List<GameCard> deckFor(CardDeck deck) =>
      deck == CardDeck.chance ? chanceCards : communityCards;

  static GameCard? byId(String id) {
    for (final GameCard card in <GameCard>[...chanceCards, ...communityCards]) {
      if (card.id == id) {
        return card;
      }
    }
    return null;
  }
}
