// [R13] A validated building level and its rent multiplier.
class Building {
  final int level;
  Building(this.level) {
    if (level < 0 || level > 3) throw RangeError.range(level, 0, 3);
  }
  double get multiplier => [1.0, 3.0, 5.0, 8.0][level];
}
