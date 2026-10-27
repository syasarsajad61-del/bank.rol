// [R25][T06] laws_data.dart
import '../models/law.dart';

enum LawEffect {
  increaseRent, taxHighRent, increaseSalary, reduceJail,
  increaseBuildingCost, helpPoorest, reduceBuildingCap,
  taxTrade, doublePublicRent, reduceInsurance,
}

class LawData {
  final String id;
  final String title;
  final String description;
  final LawEffect effect;
  final double? value;
  const LawData({
    required this.id, required this.title, required this.description,
    required this.effect, this.value,
  });
}

const List<LawData> LAWS = [
  LawData(id: 'law_01', title: 'اجاره‌های بالاتر',
    description: 'اجاره‌ها ۲۰٪ افزایش',
    effect: LawEffect.increaseRent, value: 0.20),
  LawData(id: 'law_02', title: 'مالیات بر اجاره‌های کلان',
    description: 'اجاره بالای ۳۰۰ دلار، ۱۰٪ به بانک مشترک',
    effect: LawEffect.taxHighRent, value: 0.10),
  LawData(id: 'law_03', title: 'افزایش حقوق',
    description: 'حقوق عبور از شروع ۲۵۰ دلار',
    effect: LawEffect.increaseSalary, value: 250),
  LawData(id: 'law_04', title: 'زندان کوتاه',
    description: 'زندان فقط ۱ نوبت',
    effect: LawEffect.reduceJail, value: 1),
  LawData(id: 'law_05', title: 'گرانی ساخت',
    description: 'خرید ساختمان ۳۰٪ گران‌تر',
    effect: LawEffect.increaseBuildingCost, value: 0.30),
  LawData(id: 'law_06', title: 'کمک به کم‌درآمد',
    description: 'کم‌درآمدترین بازیکن ۳۰۰ دلار از بانک مرکزی',
    effect: LawEffect.helpPoorest, value: 300),
  LawData(id: 'law_07', title: 'سقف ساخت کمتر',
    description: 'حداکثر ۲ ساختمان',
    effect: LawEffect.reduceBuildingCap, value: 2),
  LawData(id: 'law_08', title: 'مالیات معاوضه',
    description: 'هر معاوضه ۵٪ به بانک مشترک',
    effect: LawEffect.taxTrade, value: 0.05),
  LawData(id: 'law_09', title: 'اجارهٔ عمومی دو برابر',
    description: 'اجارهٔ املاک عمومی ×۲ به‌جای ×تعداد',
    effect: LawEffect.doublePublicRent, value: 2),
  LawData(id: 'law_10', title: 'بیمهٔ ارزان',
    description: 'حق بیمه ۵۰٪ ارزان‌تر',
    effect: LawEffect.reduceInsurance, value: 0.50),
];
