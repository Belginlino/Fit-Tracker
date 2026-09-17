import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack/features/progress_photos/domain/progress_photo.dart';

void main() {
  group('Progress Photo Storage Parsing & Recovery Tests', () {
    test('parses timestamp from Appwrite storage photo filename correctly', () {
      const fileName = 'photo-1789663224300.jpeg';
      final photoId = fileName.split('.').first;
      final msStr = photoId.replaceFirst('photo-', '');
      final ms = int.parse(msStr);
      final date = DateTime.fromMillisecondsSinceEpoch(ms);

      expect(photoId, 'photo-1789663224300');
      expect(ms, 1789663224300);
      expect(date.isAfter(DateTime(2020)), isTrue);
    });

    test('reconstructs ProgressPhoto from Appwrite storage file attributes', () {
      const fileId = '6aac17f84af0f39ce034';
      const fileName = 'photo-1789663224300.jpeg';
      final photoId = fileName.split('.').first;
      final ms = int.parse(photoId.replaceFirst('photo-', ''));
      final photoDate = DateTime.fromMillisecondsSinceEpoch(ms);
      const downloadUrl =
          'https://sgp.cloud.appwrite.io/v1/storage/buckets/progress-photos/files/$fileId/view?project=6aac02f1002c53d0bc56';

      final photo = ProgressPhoto(
        id: photoId,
        userId: 'user-123',
        storagePath: fileId,
        downloadUrl: downloadUrl,
        pose: 'Front',
        createdAt: photoDate,
      );

      expect(photo.id, 'photo-1789663224300');
      expect(photo.storagePath, '6aac17f84af0f39ce034');
      expect(photo.downloadUrl, contains(fileId));
      expect(photo.effectiveDayNumber, 1);
    });
  });
}
