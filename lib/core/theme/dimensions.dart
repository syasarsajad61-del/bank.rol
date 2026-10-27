// [TH11][TH12][TH13] Shared dimensions and motion durations.
class Dimensions {
  static const spacing = [4.0, 8.0, 12.0, 16.0, 24.0, 32.0, 48.0, 64.0];
  static const radiusSmall = 8.0,
      radiusCard = 12.0,
      radiusButton = 20.0,
      radiusModal = 32.0;
  static const micro = Duration(milliseconds: 150),
      standard = Duration(milliseconds: 300),
      macro = Duration(milliseconds: 500),
      cinematic = Duration(milliseconds: 800);
}
