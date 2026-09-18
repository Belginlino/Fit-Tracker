class StreakCalculator {
  StreakCalculator._();

  /// Calculates consecutive daily active streak from a collection of activity timestamps.
  ///
  /// Rules:
  /// 1. Timestamps are normalized to calendar dates (midnight local time).
  /// 2. Multiple activities on the same calendar day count as 1 active day.
  /// 3. If the most recent activity is today or yesterday, the streak is alive.
  /// 4. If the most recent activity is 2 or more days ago, the streak is 0 (broken).
  /// 5. Counts continuous sequence of consecutive days backwards.
  static int calculateStreak(Iterable<DateTime> activityDates, {DateTime? now}) {
    if (activityDates.isEmpty) return 0;

    final referenceNow = now ?? DateTime.now();
    final today = DateTime(referenceNow.year, referenceNow.month, referenceNow.day);
    final yesterday = today.subtract(const Duration(days: 1));

    // Normalize and deduplicate into unique calendar dates
    final uniqueDays = activityDates
        .map((d) => DateTime(d.year, d.month, d.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a)); // Descending order (latest first)

    if (uniqueDays.isEmpty) return 0;

    final latest = uniqueDays.first;

    // If the latest activity is older than yesterday, streak is broken
    if (latest.isBefore(yesterday)) {
      return 0;
    }

    int streak = 0;
    DateTime currentExpected = latest;

    for (final day in uniqueDays) {
      if (day.isAtSameMomentAs(currentExpected)) {
        streak++;
        currentExpected = currentExpected.subtract(const Duration(days: 1));
      } else if (day.isBefore(currentExpected)) {
        // Gap detected; streak ends
        break;
      }
    }

    return streak;
  }
}
