// [R16][T06] chance_cards_data.dart
import '../models/chance_card.dart';

enum ChanceEffect {
  moneyFromBank, moneyFromPlayers, discountNextProperty,
  moneyFromBankPool, moveToStart, payBankPool, payPlayers,
  loseBuilding, goToJail, loseCredit, moveToAnywhere,
  moveToNextChance, moveToLastBought, gainUnownedProperty, swapPosition,
}

class ChanceCardData {
  final String id;
  final String title;
  final String description;
  final ChanceEffect effect;
  final int? amount;
  final bool positive;
  const ChanceCardData({
    required this.id, required this.title, required this.description,
    required this.effect, this.amount, required this.positive,
  });
}

const List<ChanceCardData> CHANCE_CARDS = [
  ChanceCardData(id: 'cc_01', title: 'سود سهام',
    description: 'از بانک ۱۵۰ دلار دریافت کنید',
    effect: ChanceEffect.moneyFromBank, amount: 150, positive: true),
  ChanceCardData(id: 'cc_02', title: 'کمک دوستان',
    description: 'از هر بازیکن ۵۰ دلار دریافت کنید',
    effect: ChanceEffect.moneyFromPlayers, amount: 50, positive: true),
  ChanceCardData(id: 'cc_03', title: 'تخفیف ویژه',
    description: 'خرید ملک بعدی ۵۰٪ تخفیف',
    effect: ChanceEffect.discountNextProperty, positive: true),
  ChanceCardData(id: 'cc_04', title: 'سود بانک مشترک',
    description: 'از بانک مشترک ۱۰۰ دلار دریافت کنید',
    effect: ChanceEffect.moneyFromBankPool, amount: 100, positive: true),
  ChanceCardData(id: 'cc_05', title: 'حقوق ماهانه',
    description: 'به خانه شروع بروید و حقوق بگیرید',
    effect: ChanceEffect.moveToStart, positive: true),
  ChanceCardData(id: 'cc_06', title: 'مالیات سنگین',
    description: '۲۰۰ دلار به بانک مشترک بپردازید',
    effect: ChanceEffect.payBankPool, amount: 200, positive: false),
  ChanceCardData(id: 'cc_07', title: 'مهمانی',
    description: 'به هر بازیکن ۱۰۰ دلار بپردازید',
    effect: ChanceEffect.payPlayers, amount: 100, positive: false),
  ChanceCardData(id: 'cc_08', title: 'آتش‌سوزی',
    description: 'یک ساختمان تصادفی از دست می‌دهید',
    effect: ChanceEffect.loseBuilding, positive: false),
  ChanceCardData(id: 'cc_09', title: 'زندانی شدید',
    description: 'به زندان بروید (۳ نوبت)',
    effect: ChanceEffect.goToJail, positive: false),
  ChanceCardData(id: 'cc_10', title: 'افت اعتبار',
    description: 'اعتبار شما ۱۰ واحد کاهش می‌یابد',
    effect: ChanceEffect.loseCredit, amount: 10, positive: false),
  ChanceCardData(id: 'cc_11', title: 'آزادی مطلق',
    description: 'به هر خانه‌ای که می‌خواهید بروید',
    effect: ChanceEffect.moveToAnywhere, positive: true),
  ChanceCardData(id: 'cc_12', title: 'خانهٔ شانس بعدی',
    description: 'به نزدیک‌ترین خانهٔ شانس بروید',
    effect: ChanceEffect.moveToNextChance, positive: true),
  ChanceCardData(id: 'cc_13', title: 'بازداشت اشتباهی',
    description: 'به زندان بروید (۳ نوبت)',
    effect: ChanceEffect.goToJail, positive: false),
  ChanceCardData(id: 'cc_14', title: 'سرکشی به دارایی',
    description: 'به آخرین ملک خریداری‌شده بروید',
    effect: ChanceEffect.moveToLastBought, positive: true),
  ChanceCardData(id: 'cc_15', title: 'مالکیت رایگان',
    description: 'یک ملک بی‌صاحب تصادفی رایگان بگیرید',
    effect: ChanceEffect.gainUnownedProperty, positive: true),
  ChanceCardData(id: 'cc_16', title: 'تبادل مهره',
    description: 'جای مهره با بازیکن تصادفی عوض شود',
    effect: ChanceEffect.swapPosition, positive: false),
];
