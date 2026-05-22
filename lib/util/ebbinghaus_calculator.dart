class EbbinghausCalculator {
  static const List<int> intervalsInDays = [1, 2, 4, 7, 15, 30];

  static int getNextReviewTime(int stage) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final days = stage < intervalsInDays.length ? intervalsInDays[stage] : intervalsInDays.last;
    return now + days * 24 * 60 * 60 * 1000;
  }

  static int getIntervalDays(int stage) {
    return stage < intervalsInDays.length ? intervalsInDays[stage] : intervalsInDays.last;
  }

  static String getStageLabel(int stage) {
    if (stage >= 6) return '已掌握';
    final days = intervalsInDays[stage];
    return '第${stage + 1}轮 ($days天后复习)';
  }

  static bool isDueForReview(int nextReviewTime) {
    return DateTime.now().millisecondsSinceEpoch >= nextReviewTime;
  }

  static String getTimeUntilReview(int nextReviewTime) {
    final diff = nextReviewTime - DateTime.now().millisecondsSinceEpoch;
    if (diff <= 0) return '待复习';
    final days = diff ~/ (24 * 60 * 60 * 1000);
    final hours = (diff % (24 * 60 * 60 * 1000)) ~/ (60 * 60 * 1000);
    if (days > 0) return '$days天$hours小时后';
    return '$hours小时后';
  }
}
