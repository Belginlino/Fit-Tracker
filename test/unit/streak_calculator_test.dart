import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack/core/utils/streak_calculator.dart';

void main() {
  group('StreakCalculator Tests', () {
    final refDate = DateTime(2026, 9, 18, 14, 30);

    test('returns 0 for empty activity dates', () {
      expect(StreakCalculator.calculateStreak([], now: refDate), equals(0));
    });

    test('returns 1 when there is an activity today', () {
      final dates = [DateTime(2026, 9, 18, 8, 0)];
      expect(StreakCalculator.calculateStreak(dates, now: refDate), equals(1));
    });

    test('returns 1 when there is an activity yesterday and none today', () {
      final dates = [DateTime(2026, 9, 17, 20, 0)];
      expect(StreakCalculator.calculateStreak(dates, now: refDate), equals(1));
    });

    test('deduplicates multiple activities on the same day to 1 day', () {
      final dates = [
        DateTime(2026, 9, 18, 7, 0),
        DateTime(2026, 9, 18, 12, 30),
        DateTime(2026, 9, 18, 19, 0),
      ];
      expect(StreakCalculator.calculateStreak(dates, now: refDate), equals(1));
    });

    test('calculates 3 consecutive days ending today', () {
      final dates = [
        DateTime(2026, 9, 18, 9, 0),
        DateTime(2026, 9, 17, 18, 0),
        DateTime(2026, 9, 16, 17, 0),
      ];
      expect(StreakCalculator.calculateStreak(dates, now: refDate), equals(3));
    });

    test('calculates 3 consecutive days ending yesterday (streak still active)', () {
      final dates = [
        DateTime(2026, 9, 17, 18, 0),
        DateTime(2026, 9, 16, 17, 0),
        DateTime(2026, 9, 15, 10, 0),
      ];
      expect(StreakCalculator.calculateStreak(dates, now: refDate), equals(3));
    });

    test('returns 0 if latest activity is 2 days ago (streak broken)', () {
      final dates = [
        DateTime(2026, 9, 16, 17, 0),
        DateTime(2026, 9, 15, 10, 0),
        DateTime(2026, 9, 14, 10, 0),
      ];
      expect(StreakCalculator.calculateStreak(dates, now: refDate), equals(0));
    });

    test('correctly stops counting across a gap in activity', () {
      final dates = [
        DateTime(2026, 9, 18, 9, 0),
        DateTime(2026, 9, 17, 18, 0),
        // missing 9/16
        DateTime(2026, 9, 15, 10, 0),
        DateTime(2026, 9, 14, 10, 0),
      ];
      expect(StreakCalculator.calculateStreak(dates, now: refDate), equals(2));
    });

    test('handles month boundary correctly', () {
      final monthEndRef = DateTime(2026, 10, 2, 10, 0);
      final dates = [
        DateTime(2026, 10, 2, 8, 0),
        DateTime(2026, 10, 1, 8, 0),
        DateTime(2026, 9, 30, 8, 0),
        DateTime(2026, 9, 29, 8, 0),
      ];
      expect(StreakCalculator.calculateStreak(dates, now: monthEndRef), equals(4));
    });
  });
}
