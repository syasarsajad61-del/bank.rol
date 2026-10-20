/// Every mutation a client is allowed to *request*. The host validates and
/// is the only device that actually changes [GameState].
enum ActionType {
  join,
  rollDice,
  buyProperty,
  declinePurchase,
  placeBid,
  passBid,
  upgradeProperty,
  mortgageProperty,
  unmortgageProperty,
  proposeTrade,
  respondTrade,
  withdrawTrade,
  acknowledgeCard,
  endTurn,
  declareBankrupt,
  startGame,
  rematch,
}

extension ActionTypeX on ActionType {
  String get labelFa {
    switch (this) {
      case ActionType.join:
        return 'ورود به بازی';
      case ActionType.rollDice:
        return 'تاس بریز';
      case ActionType.buyProperty:
        return 'خرید ملک';
      case ActionType.declinePurchase:
        return 'انصراف از خرید';
      case ActionType.placeBid:
        return 'پیشنهاد قیمت';
      case ActionType.passBid:
        return 'رد کردن حراج';
      case ActionType.upgradeProperty:
        return 'ارتقای ساختمان';
      case ActionType.mortgageProperty:
        return 'رهن ملک';
      case ActionType.unmortgageProperty:
        return 'آزادسازی رهن';
      case ActionType.proposeTrade:
        return 'پیشنهاد معامله';
      case ActionType.respondTrade:
        return 'پاسخ به معامله';
      case ActionType.withdrawTrade:
        return 'لغو معامله';
      case ActionType.acknowledgeCard:
        return 'تایید کارت';
      case ActionType.endTurn:
        return 'پایان نوبت';
      case ActionType.declareBankrupt:
        return 'اعلام ورشکستگی';
      case ActionType.startGame:
        return 'شروع بازی';
      case ActionType.rematch:
        return 'بازی مجدد';
    }
  }
}

/// A client-to-host request. Carries no authority of its own.
class ActionRequest {
  const ActionRequest({
    required this.type,
    required this.playerId,
    this.data = const <String, dynamic>{},
  });

  final ActionType type;
  final String playerId;
  final Map<String, dynamic> data;

  int intOf(String key, [int fallback = 0]) {
    final dynamic raw = data[key];
    if (raw is num) {
      return raw.toInt();
    }
    if (raw is String) {
      return int.tryParse(raw) ?? fallback;
    }
    return fallback;
  }

  bool boolOf(String key, [bool fallback = false]) {
    final dynamic raw = data[key];
    if (raw is bool) {
      return raw;
    }
    if (raw is String) {
      return raw == 'true';
    }
    if (raw is num) {
      return raw != 0;
    }
    return fallback;
  }

  String stringOf(String key, [String fallback = '']) {
    final dynamic raw = data[key];
    return raw is String ? raw : fallback;
  }

  List<int> intListOf(String key) {
    final dynamic raw = data[key];
    if (raw is List) {
      return raw
          .map((dynamic e) => e is num ? e.toInt() : int.tryParse('$e') ?? 0)
          .toList(growable: false);
    }
    return const <int>[];
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': type.name,
        'playerId': playerId,
        'data': data,
      };

  factory ActionRequest.fromJson(Map<String, dynamic> json) => ActionRequest(
        type: ActionType.values.firstWhere(
          (ActionType t) => t.name == (json['type'] as String?),
          orElse: () => ActionType.endTurn,
        ),
        playerId: (json['playerId'] as String?) ?? '',
        data: json['data'] is Map
            ? Map<String, dynamic>.from(json['data'] as Map)
            : const <String, dynamic>{},
      );
}

/// Transport level envelope used by both ends of the socket.
class WireMessage {
  const WireMessage(this.type, [this.payload = const <String, dynamic>{}]);

  final String type;
  final Map<String, dynamic> payload;

  Map<String, dynamic> toJson() => <String, dynamic>{
        't': type,
        'p': payload,
      };

  factory WireMessage.fromJson(Map<String, dynamic> json) => WireMessage(
        (json['t'] as String?) ?? '',
        json['p'] is Map
            ? Map<String, dynamic>.from(json['p'] as Map)
            : const <String, dynamic>{},
      );

  static const String hello = 'hello';
  static const String welcome = 'welcome';
  static const String joined = 'joined';
  static const String state = 'state';
  static const String action = 'action';
  static const String ping = 'ping';
  static const String pong = 'pong';
  static const String error = 'error';
  static const String roster = 'roster';
  static const String info = 'info';
  static const String bye = 'bye';
}
