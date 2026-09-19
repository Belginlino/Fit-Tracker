import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack/features/progress_photos/domain/day_photo_group.dart';
import 'package:fittrack/features/progress_photos/domain/progress_photo.dart';

void main() {
  group('DayPhotoGroup Tests', () {
    final now = DateTime(2026, 9, 19, 10, 0);

    final p1Day1Front = ProgressPhoto(
      id: 'p1',
      userId: 'user_1',
      storagePath: 'photos/p1.jpg',
      pose: 'Front',
      createdAt: now.subtract(const Duration(days: 2)),
      dayNumber: 1,
    );

    final p2Day3Front = ProgressPhoto(
      id: 'p2',
      userId: 'user_1',
      storagePath: 'photos/p2.jpg',
      pose: 'Front',
      createdAt: now,
      dayNumber: 3,
    );

    final p3Day3Side = ProgressPhoto(
      id: 'p3',
      userId: 'user_1',
      storagePath: 'photos/p3.jpg',
      pose: 'Side',
      createdAt: now.add(const Duration(minutes: 5)),
      dayNumber: 3,
    );

    final p4Day3Back = ProgressPhoto(
      id: 'p4',
      userId: 'user_1',
      storagePath: 'photos/p4.jpg',
      pose: 'Back',
      createdAt: now.add(const Duration(minutes: 10)),
      dayNumber: 3,
    );

    test('groups multiple photos belonging to the same day into one group', () {
      final photos = [p1Day1Front, p2Day3Front, p3Day3Side, p4Day3Back];
      final groups = DayPhotoGroup.groupPhotos(photos);

      // Should have 2 groups: Day 3 and Day 1
      expect(groups.length, 2);

      // Highest day number first
      expect(groups[0].dayNumber, 3);
      expect(groups[0].isFolder, isTrue);
      expect(groups[0].photoCount, 3);
      expect(groups[0].photos.length, 3);

      expect(groups[1].dayNumber, 1);
      expect(groups[1].isFolder, isFalse);
      expect(groups[1].photoCount, 1);
      expect(groups[1].isDayOne, isTrue);
    });

    test('selects Front pose as coverPhoto when available', () {
      final day3Photos = [p3Day3Side, p2Day3Front, p4Day3Back];
      final group = DayPhotoGroup(
        dayNumber: 3,
        date: now,
        photos: day3Photos,
      );

      expect(group.coverPhoto.pose, 'Front');
    });

    test('formats posesSummary accurately', () {
      final groupMulti = DayPhotoGroup(
        dayNumber: 3,
        date: now,
        photos: [p2Day3Front, p3Day3Side, p4Day3Back],
      );
      expect(groupMulti.posesSummary, 'Front · Side · Back');

      final groupSingle = DayPhotoGroup(
        dayNumber: 1,
        date: now,
        photos: [p1Day1Front],
      );
      expect(groupSingle.posesSummary, 'Front');
    });

    test('handles empty photo list gracefully', () {
      final groups = DayPhotoGroup.groupPhotos([]);
      expect(groups, isEmpty);
    });
  });
}
