import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fittrack/core/appwrite/appwrite_client.dart';
import 'package:fittrack/core/appwrite/appwrite_config.dart';
import 'package:fittrack/core/widgets/app_photo_image.dart';
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
  final Set<String> _loadedUsers = {};

  @override
  Stream<List<ProgressPhoto>> getPhotosStream(String userId) async* {
    if (_cache.isNotEmpty) {
      yield List.unmodifiable(_cache);
    }
    _initAndFetch(userId);
    yield* _controller.stream;
  }

  Future<void> _initAndFetch(String userId) async {
    if (!_loadedUsers.contains(userId)) {
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
      _loadedUsers.add(userId);
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
        // Merge remote photos with local photos (preserve localFilePath & metadata if present)
        final localMap = {for (var p in _cache) p.id: p};
        final merged = photos.map((remote) {
          final local = localMap[remote.id];
          if (local != null) {
            return remote.copyWith(
              localFilePath: local.localFilePath ?? remote.localFilePath,
              notes: (remote.notes != null && remote.notes!.isNotEmpty)
                  ? remote.notes
                  : local.notes,
              pose: remote.pose != 'Front' ? remote.pose : local.pose,
              weightAtCapture: remote.weightAtCapture ?? local.weightAtCapture,
              dayNumber: remote.dayNumber ?? local.dayNumber,
            );
          }
          return remote;
        }).toList();

        // Also keep any local-only photos that haven't synced to remote yet
        final remoteIds = {for (var p in photos) p.id};
        final remotePaths = {for (var p in photos) p.storagePath};
        for (final local in _cache) {
          if (!remoteIds.contains(local.id) &&
              !remotePaths.contains(local.storagePath)) {
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

    final photos = <ProgressPhoto>[];
    final foundStorageIds = <String>{};

    // 1. Try querying Appwrite Databases collection
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

      for (final doc in records.documents) {
        final data = doc.data;
        final fileId = (data['file_id'] ?? data['storage_path']) as String? ?? '';
        String? downloadUrl;

        if (fileId.isNotEmpty) {
          downloadUrl = AppwriteClient.instance.getFileViewUrl(fileId);
          foundStorageIds.add(fileId);
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
            dayNumber: (data['day_number'] ?? data['dayNumber']) as int? ??
                ProgressPhoto.extractDayNumber(data['notes'] as String?),
            createdAt: DateTime.tryParse(data['created_at'] as String? ?? '') ??
                DateTime.now(),
          ),
        );
      }
    } catch (_) {
      // Database collection may not exist yet or request failed
    }

    // 2. Query Appwrite Storage bucket directly to recover uploaded photos
    try {
      final storage = AppwriteClient.instance.storage;
      final fileList = await storage.listFiles(
        bucketId: AppwriteConfig.photosBucket,
        queries: [
          Query.orderDesc(r'$createdAt'),
          Query.limit(100),
        ],
      );

      for (final file in fileList.files) {
        final fileId = file.$id;
        if (foundStorageIds.contains(fileId)) {
          continue; // Already loaded from database collection
        }

        final fileName = file.name;
        // Format: photo-1789663224300.jpeg or photo-1789663224300.jpg
        final photoId = fileName.contains('.')
            ? fileName.split('.').first
            : (fileName.isNotEmpty ? fileName : 'photo-$fileId');

        // Extract timestamp from filename (e.g. photo-1789663224300)
        DateTime photoDate;
        if (photoId.startsWith('photo-')) {
          final msStr = photoId.replaceFirst('photo-', '');
          final ms = int.tryParse(msStr);
          photoDate = ms != null
              ? DateTime.fromMillisecondsSinceEpoch(ms)
              : (DateTime.tryParse(file.$createdAt) ?? DateTime.now());
        } else {
          photoDate = DateTime.tryParse(file.$createdAt) ?? DateTime.now();
        }

        final localMatch = _cache
            .where((p) => p.id == photoId || p.storagePath == fileId)
            .firstOrNull;

        final downloadUrl = AppwriteClient.instance.getFileViewUrl(fileId);
        foundStorageIds.add(fileId);

        photos.add(
          ProgressPhoto(
            id: photoId,
            userId: userId,
            storagePath: fileId,
            downloadUrl: downloadUrl,
            localFilePath: localMatch?.localFilePath,
            pose: localMatch?.pose ?? 'Front',
            workoutId: localMatch?.workoutId,
            weightAtCapture: localMatch?.weightAtCapture,
            notes: localMatch?.notes,
            dayNumber: localMatch?.dayNumber,
            createdAt: localMatch?.createdAt ?? photoDate,
          ),
        );
      }
    } catch (_) {
      // Storage listing error caught
    }

    if (photos.isNotEmpty) {
      photos.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return photos;
    }

    return _cache;
  }

  @override
  Future<void> savePhoto(ProgressPhoto photo) async {
    _cache.removeWhere((p) => p.id == photo.id);
    _cache.insert(0, photo);
    _cache.sort((a, b) => b.createdAt.compareTo(a.createdAt));
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

    // 1. Upload photo binary to Appwrite Storage if a new local file exists
    if (photo.localFilePath != null && !photo.localFilePath!.startsWith('http')) {
      try {
        final file = File(photo.localFilePath!);
        final needsUpload = file.existsSync() &&
            (photo.downloadUrl == null ||
                photo.downloadUrl!.isEmpty ||
                fileId.isEmpty ||
                fileId.contains('/'));

        if (needsUpload) {
          final bytes = await file.readAsBytes();
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
            permissions: permissions,
          );

          fileId = uploadedFile.$id;
          downloadUrl = AppwriteClient.instance.getFileViewUrl(fileId);

          // Update cache & local storage immediately with verified fileId & downloadUrl
          final updated = photo.copyWith(
            storagePath: fileId,
            downloadUrl: downloadUrl,
          );
          _cache.removeWhere((p) => p.id == photo.id);
          _cache.insert(0, updated);
          _cache.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          _controller.add(List.unmodifiable(_cache));
          await _saveToLocal(photo.userId);
        }
      } catch (_) {}
    }

    // 2. Save metadata in Appwrite Databases if collection exists
    try {
      final docData = {
        'user_id': photo.userId,
        'file_id': fileId,
        'storage_path': fileId,
        'pose': photo.pose,
        'workout_id': photo.workoutId ?? '',
        'weight_at_capture': photo.weightAtCapture ?? 0.0,
        'notes': photo.notes ?? '',
        'day_number': photo.effectiveDayNumber,
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
          try {
            await AppwriteClient.instance.databases.createDocument(
              databaseId: AppwriteConfig.databaseId,
              collectionId: AppwriteConfig.progressPhotosCollection,
              documentId: photo.id,
              data: docData,
              permissions: permissions,
            );
          } catch (_) {}
        }
      }
    } catch (_) {
      // Remote sync error caught; local photo remains visible and persistent
    }
  }

  @override
  Future<void> deletePhoto(String photoId, {String? userId}) async {
    final uid = userId ?? (_cache.isNotEmpty ? _cache.first.userId : '');
    final target = _cache
        .where((p) => p.id == photoId || p.storagePath == photoId)
        .firstOrNull;
    _cache.removeWhere((p) => p.id == photoId || p.storagePath == photoId);
    _controller.add(List.unmodifiable(_cache));
    await _saveToLocal(uid);

    if (!AppwriteConfig.isConfigured) return;

    // 1. Delete from Appwrite Storage
    String? fileId = target?.storagePath;
    if (fileId == null || fileId.isEmpty || fileId.contains('/')) {
      if (photoId.isNotEmpty &&
          !photoId.contains('/') &&
          !photoId.startsWith('photo-')) {
        fileId = photoId;
      }
    }

    if (fileId != null && fileId.isNotEmpty) {
      try {
        await AppwriteClient.instance.storage.deleteFile(
          bucketId: AppwriteConfig.photosBucket,
          fileId: fileId,
        );
        AppPhotoImage.evict(fileId);
      } catch (_) {}
    } else {
      // If photoId was a timestamp ID like photo-1789663224300, search storage files by name
      try {
        final storageFiles = await AppwriteClient.instance.storage.listFiles(
          bucketId: AppwriteConfig.photosBucket,
          queries: [Query.limit(100)],
        );
        for (final file in storageFiles.files) {
          if (file.name.contains(photoId) || file.$id == photoId) {
            await AppwriteClient.instance.storage.deleteFile(
              bucketId: AppwriteConfig.photosBucket,
              fileId: file.$id,
            );
            AppPhotoImage.evict(file.$id);
            break;
          }
        }
      } catch (_) {}
    }

    // 2. Delete from Appwrite Databases
    try {
      final db = AppwriteClient.instance.databases;
      final docId = target?.id ?? photoId;
      try {
        final existing = await db.getDocument(
          databaseId: AppwriteConfig.databaseId,
          collectionId: AppwriteConfig.progressPhotosCollection,
          documentId: docId,
        );
        final docFileId =
            (existing.data['file_id'] ?? existing.data['storage_path']) as String?;
        if (docFileId != null && docFileId.isNotEmpty) {
          await AppwriteClient.instance.storage.deleteFile(
            bucketId: AppwriteConfig.photosBucket,
            fileId: docFileId,
          );
          AppPhotoImage.evict(docFileId);
        }
      } catch (_) {}

      await db.deleteDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.progressPhotosCollection,
        documentId: docId,
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
