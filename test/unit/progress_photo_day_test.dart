import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack/features/progress_photos/domain/progress_photo.dart';

void main() {
  group('ProgressPhoto Day Tracking Tests', () {
    test('creates photo with explicit Day 1 and verifies isDayOne and dayLabel', () {
      final photo = ProgressPhoto(
        id: 'p1',
        userId: 'u1',
        storagePath: 'path/1.jpg',
        createdAt: DateTime(2026, 1, 1),
        dayNumber: 1,
      );

      expect(photo.dayNumber, 1);
      expect(photo.effectiveDayNumber, 1);
      expect(photo.dayLabel, 'Day 1');
      expect(photo.isDayOne, true);
    });

    test('extracts Day 1 from notes tag [Day 1]', () {
      final photo = ProgressPhoto(
        id: 'p2',
        userId: 'u1',
        storagePath: 'path/2.jpg',
        createdAt: DateTime(2026, 1, 1),
        notes: '[Day 1] Starting fitness journey feeling motivated!',
      );

      expect(photo.effectiveDayNumber, 1);
      expect(photo.isDayOne, true);
      expect(photo.dayLabel, 'Day 1');
      expect(photo.cleanNotes, 'Starting fitness journey feeling motivated!');
    });

    test('extracts Day 30 from notes tag [Day 30]', () {
      final photo = ProgressPhoto(
        id: 'p3',
        userId: 'u1',
        storagePath: 'path/3.jpg',
        createdAt: DateTime(2026, 1, 30),
        notes: '[Day 30] 1 month progress check',
      );

      expect(photo.effectiveDayNumber, 30);
      expect(photo.isDayOne, false);
      expect(photo.dayLabel, 'Day 30');
      expect(photo.cleanNotes, '1 month progress check');
    });

    test('serializes and deserializes dayNumber properly', () {
      final photo = ProgressPhoto(
        id: 'p4',
        userId: 'u1',
        storagePath: 'path/4.jpg',
        createdAt: DateTime(2026, 2, 1),
        dayNumber: 15,
        notes: 'Feeling stronger',
      );

      final map = photo.toMap();
      expect(map['notes'], contains('[Day 15]'));

      final restored = ProgressPhoto.fromMap(map, 'p4');
      expect(restored.effectiveDayNumber, 15);
      expect(restored.dayLabel, 'Day 15');
      expect(restored.cleanNotes, 'Feeling stronger');
    });
  });
}
