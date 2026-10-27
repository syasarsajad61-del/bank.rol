// [TH10] Persian digits, with consistent monetary formatting.
extension PersianNumber on num {
  String get fa => toStringAsFixed(
    this is int ? 0 : 0,
  ).replaceAllMapped(RegExp('[0-9]'), (m) => '۰۱۲۳۴۵۶۷۸۹'[int.parse(m[0]!)]);
  String get money => '$fa \$';
}
