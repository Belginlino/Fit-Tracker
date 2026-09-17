import 'dart:async';
import 'dart:convert';
import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fittrack/core/appwrite/appwrite_client.dart';
import 'package:fittrack/core/appwrite/appwrite_config.dart';
import '../domain/progress_photo.dart';

abstract class ProgressPhotoRepository {
  Stream<List<ProgressPhoto>> getPhotosStream(String userId);
  Future<List<ProgressPhoto>> getPhotos(String userId);
  Future<void> savePhoto(ProgressPhoto photo);
  Future<void> deletePhoto(String photoId, {String? userId});
}

/// Appwrite Storage & Database implementation for Progress Photos with local persistence
class AppwriteProgressPhotoRepository implements ProgressPhotoRepository {
  final _controller = StreamController<List<ProgressPhoto>>.broadcast();
  List<ProgressPhoto> _cache = [];
  bool _localLoaded = false;

  @override
  Stream<List<ProgressPhoto>> getPhotosStream(String userId) {
    _initAndFetch(userId);
    return _controller.stream;
  }

  Future<void> _initAndFetch(String userId) async {
    if (!_localLoaded) {
      await _loadFromLocal(userId);
    }
    await _fetchAndEmit(userId);
  }

  Future<void> _loadFromLocal(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'fittrack_photos_${userId.isEmpty ? "default" : userId}';
      final raw = prefs.getString(key);
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> list = jsonDecode(raw);
        final loaded = list
            .map((item) => ProgressPhoto.fromMap(
                Map<String, dynamic>.from(item), item['id'] as String? ?? ''))
            .toList();
        if (loaded.isNotEmpty) {
          _cache = loaded;
          _controller.add(List.unmodifiable(_cache));
        }
      }
      _localLoaded = true;
    } catch (_) {}
  }

  Future<void> _saveToLocal(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'fittrack_photos_${userId.isEmpty ? "default" : userId}';
      final raw = jsonEncode(_cache.map((p) => p.toMap()).toList());
      await prefs.setString(key, raw);
    } catch (_) {}
  }

  Future<void> _fetchAndEmit(String userId) async {
    try {
      final photos = await getPhotos(userId);
      if (photos.isNotEmpty) {
        // Merge remote photos with local photos (preserve localFilePath if present)
        final localMap = {for (var p in _cache) p.id: p};
        final merged = photos.map((remote) {
          final local = localMap[remote.id];
          if (local != null && local.localFilePath != null) {
            return remote.copyWith(localFilePath: local.localFilePath);
          }
          return remote;
        }).toList();

        // Also keep any local photos that haven't synced to remote yet
        final remoteIds = {for (var p in photos) p.id};
        for (final local in _cache) {
          if (!remoteIds.contains(local.id)) {
            merged.add(local);
          }
        }

        merged.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _cache = merged;
      }
      _controller.add(List.unmodifiable(_cache));
      await _saveToLocal(userId);
    } catch (_) {
      _controller.add(List.unmodifiable(_cache));
    }
  }

  @override
  Future<List<ProgressPhoto>> getPhotos(String userId) async {
    if (!AppwriteConfig.isConfigured || userId.isEmpty || userId == 'user-local') {
      return _cache;
    }

    try {
      final db = AppwriteClient.instance.databases;
      final records = await db.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.progressPhotosCollection,
        queries: [
          Query.equal('user_id', userId),
          Query.orderDesc('created_at'),
          Query.limit(100),
        ],
      );

      final photos = <ProgressPhoto>[];
      for (final doc in records.documents) {
        final data = doc.data;
        final fileId = (data['file_id'] ?? data['storage_path']) as String? ?? '';
        String? downloadUrl;

        if (fileId.isNotEmpty) {
          downloadUrl = AppwriteClient.instance.getFileViewUrl(fileId);
        }

        photos.add(
          ProgressPhoto(
            id: doc.$id,
            userId: data['user_id'] as String? ?? userId,
            storagePath: fileId,
            downloadUrl: downloadUrl,
            pose: data['pose'] as String? ?? 'Front',
            workoutId: data['workout_id'] as String?,
            weightAtCapture: (data['weight_at_capture'] as num?)?.toDouble(),
            notes: data['notes'] as String?,
            createdAt: DateTime.tryParse(data['created_at'] as String? ?? '') ??
                DateTime.now(),
          ),
        );
      }

      return photos;
    } catch (_) {
      return _cache;
    }
  }

  @override
  Future<void> savePhoto(ProgressPhoto photo) async {
    _cache.removeWhere((p) => p.id == photo.id);
    _cache.insert(0, photo);
    _controller.add(List.unmodifiable(_cache));
    await _saveToLocal(photo.userId);

    if (!AppwriteConfig.isConfigured || photo.userId == 'user-local') return;

    final permissions = [
      Permission.read(Role.user(photo.userId)),
      Permission.update(Role.user(photo.userId)),
      Permission.delete(Role.user(photo.userId)),
    ];

    String fileId = photo.storagePath;
    String? downloadUrl = photo.downloadUrl;

    try {
      // 1. Upload photo binary to Appwrite Storage if local file exists
      if (photo.localFilePath != null) {
        final xFile = XFile(photo.localFilePath!);
        final bytes = await xFile.readAsBytes();
        final isPng = photo.localFilePath!.toLowerCase().endsWith('.png');
        final ext = isPng ? 'png' : 'jpg';
        final newFileId = ID.unique();

        final uploadedFile = await AppwriteClient.instance.storage.createFile(
          bucketId: AppwriteConfig.photosBucket,
          fileId: newFileId,
          file: InputFile.fromBytes(
            bytes: bytes,
            filename: '${photo.id}.$ext',
          ),
          permissions: [
            Permission.read(Role.user(photo.userId)),
            Permission.delete(Role.user(photo.userId)),
          ],
        );

        fileId = uploadedFile.$id;
        downloadUrl = AppwriteClient.instance.getFileViewUrl(fileId);
      }

      // 2. Save metadata in Appwrite Databases
      final docData = {
        'user_id': photo.userId,
        'file_id': fileId,
        'storage_path': fileId,
        'pose': photo.pose,
        'workout_id': photo.workoutId,
        'weight_at_capture': photo.weightAtCapture,
        'notes': photo.notes ?? '',
        'created_at': photo.createdAt.toIso8601String(),
      };

      try {
        await AppwriteClient.instance.databases.updateDocument(
          databaseId: AppwriteConfig.databaseId,
          collectionId: AppwriteConfig.progressPhotosCollection,
          documentId: photo.id,
          data: docData,
        );
      } on AppwriteException catch (e) {
        if (e.code == 404) {
          await AppwriteClient.instance.databases.createDocument(
            databaseId: AppwriteConfig.databaseId,
            collectionId: AppwriteConfig.progressPhotosCollection,
            documentId: photo.id,
            data: docData,
            permissions: permissions,
          );
        }
      }

      if (downloadUrl != null) {
        final updated = photo.copyWith(
          storagePath: fileId,
          downloadUrl: downloadUrl,
        );
        _cache.removeWhere((p) => p.id == photo.id);
        _cache.insert(0, updated);
        _controller.add(List.unmodifiable(_cache));
        await _saveToLocal(photo.userId);
      }
    } catch (_) {
      // Remote sync error caught; local photo remains visible and persistent
    }
  }

  @override
  Future<void> deletePhoto(String photoId, {String? userId}) async {
    final uid = userId ?? (_cache.isNotEmpty ? _cache.first.userId : '');
    _cache.removeWhere((p) => p.id == photoId);
    _controller.add(List.unmodifiable(_cache));
    await _saveToLocal(uid);

    if (!AppwriteConfig.isConfigured) return;

    try {
      final db = AppwriteClient.instance.databases;
      try {
        final existing = await db.getDocument(
          databaseId: AppwriteConfig.databaseId,
          collectionId: AppwriteConfig.progressPhotosCollection,
          documentId: photoId,
        );
        final fileId = (existing.data['file_id'] ?? existing.data['storage_path']) as String?;
        if (fileId != null && fileId.isNotEmpty) {
          await AppwriteClient.instance.storage.deleteFile(
            bucketId: AppwriteConfig.photosBucket,
            fileId: fileId,
          );
        }
      } catch (_) {}

      await db.deleteDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.progressPhotosCollection,
        documentId: photoId,
      );
    } catch (_) {}
  }
}

// Global Riverpod Providers
final progressPhotoRepositoryProvider =
    Provider<ProgressPhotoRepository>((ref) {
  return AppwriteProgressPhotoRepository();
});

final progressPhotosStreamProvider =
    StreamProvider.family<List<ProgressPhoto>, String>((ref, userId) {
  final repo = ref.watch(progressPhotoRepositoryProvider);
  return repo.getPhotosStream(userId);
});
