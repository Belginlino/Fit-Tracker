import 'progress_photo.dart';

/// Represents a folder/collection of progress photos belonging to a single day
class DayPhotoGroup {
  final int dayNumber;
  final DateTime date;
  final List<ProgressPhoto> photos;

  const DayPhotoGroup({
    required this.dayNumber,
    required this.date,
    required this.photos,
  });

  bool get isFolder => photos.length > 1;
  int get photoCount => photos.length;
  bool get isDayOne => dayNumber == 1;
  String get dayLabel => 'Day $dayNumber';

  /// Primary cover photo for folder thumbnail (prefers Front pose if available)
  ProgressPhoto get coverPhoto {
    if (photos.isEmpty) {
      throw StateError('DayPhotoGroup must contain at least one photo');
    }
    return photos.where((p) => p.pose.toLowerCase() == 'front').firstOrNull ??
        photos.first;
  }

  /// Summary label of poses included in this day folder e.g. "Front · Side · Back"
  String get posesSummary {
    final uniquePoses = photos.map((p) => p.pose).toSet().toList();
    if (uniquePoses.isEmpty) return 'Front';
    if (uniquePoses.length == 1) return uniquePoses.first;
    return uniquePoses.join(' · ');
  }

  /// Groups a flat list of progress photos into day-based folders
  static List<DayPhotoGroup> groupPhotos(List<ProgressPhoto> photos) {
    if (photos.isEmpty) return [];

    final Map<int, List<ProgressPhoto>> byDay = {};
    for (final photo in photos) {
      final day = photo.effectiveDayNumber;
      byDay.putIfAbsent(day, () => []).add(photo);
    }

    final groups = byDay.entries.map((entry) {
      final dayPhotos = List<ProgressPhoto>.from(entry.value)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return DayPhotoGroup(
        dayNumber: entry.key,
        date: dayPhotos.first.createdAt,
        photos: dayPhotos,
      );
    }).toList();

    // Sort folders by day descending (highest day first)
    groups.sort((a, b) => b.dayNumber.compareTo(a.dayNumber));
    return groups;
  }
}
