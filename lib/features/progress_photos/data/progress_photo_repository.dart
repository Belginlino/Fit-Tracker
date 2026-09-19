import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
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
/// and cross-device cloud manifest synchronization.
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

    // If local cache already has photos with day numbers or dates (e.g. on mobile),
    // sync manifest immediately to Appwrite cloud so other devices receive them
    if (_cache.isNotEmpty) {
      _syncManifest(userId);
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
          _cache = _resolveDayNumbers(loaded);
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

  /// Resolve real Appwrite account ID if userId is empty or 'user-local'
  Future<String> _resolveEffectiveUserId(String userId) async {
    if (userId.isNotEmpty && userId != 'user-local') {
      return userId;
    }
    try {
      final acc = await AppwriteClient.instance.account.get();
      return acc.$id;
    } catch (_) {
      return userId.isNotEmpty ? userId : 'default';
    }
  }

  /// Save photo metadata manifest to Appwrite Storage and Account Prefs for cross-device sync
  Future<void> _syncManifest(String userId) async {
    if (!AppwriteConfig.isConfigured || _cache.isEmpty) return;

    try {
      final effectiveUserId = await _resolveEffectiveUserId(userId);
      if (effectiveUserId == 'user-local' && userId == 'user-local') return;

      final manifestData = _cache.map((p) => {
        'id': p.id,
        'storagePath': p.storagePath,
        'downloadUrl': p.downloadUrl,
        'dayNumber': p.dayNumber ?? p.effectiveDayNumber,
        'createdAt': p.createdAt.toIso8601String(),
        'pose': p.pose,
        'weightAtCapture': p.weightAtCapture,
        'notes': p.notes,
        'workoutId': p.workoutId,
      }).toList();

      final jsonStr = jsonEncode(manifestData);

      // 1. Sync to Appwrite Account Preferences
      try {
        await AppwriteClient.instance.account.updatePrefs(prefs: {
          'photos_manifest_$effectiveUserId': jsonStr,
          'photos_manifest': jsonStr,
        });
      } catch (_) {}

      // 2. Sync to Appwrite Storage bucket file
      try {
        final storage = AppwriteClient.instance.storage;
        final fileList = await storage.listFiles(
          bucketId: AppwriteConfig.photosBucket,
          queries: [Query.limit(100)],
        );

        final targetName = 'manifest_$effectiveUserId.json';
        final oldManifestFiles = fileList.files
            .where((f) => f.name == targetName || f.name == 'manifest.json')
            .toList();

        for (final oldFile in oldManifestFiles) {
          try {
            await storage.deleteFile(
              bucketId: AppwriteConfig.photosBucket,
              fileId: oldFile.$id,
            );
          } catch (_) {}
        }

        final bytes = utf8.encode(jsonStr);
        await storage.createFile(
          bucketId: AppwriteConfig.photosBucket,
          fileId: ID.unique(),
          file: InputFile.fromBytes(
            bytes: bytes,
            filename: targetName,
          ),
          permissions: [
            Permission.read(Role.any()),
            Permission.write(Role.any()),
          ],
        );
      } catch (_) {}
    } catch (_) {}
  }

  /// Load photo metadata manifest from Appwrite Account Prefs or Storage bucket
  Future<Map<String, Map<String, dynamic>>> _loadManifest(String userId) async {
    final result = <String, Map<String, dynamic>>{};
    if (!AppwriteConfig.isConfigured) return result;

    try {
      final effectiveUserId = await _resolveEffectiveUserId(userId);

      // 1. Try Account Preferences
      try {
        final prefs = await AppwriteClient.instance.account.getPrefs();
        final raw = prefs.data['photos_manifest_$effectiveUserId'] as String? ??
            prefs.data['photos_manifest'] as String?;
        if (raw != null && raw.isNotEmpty) {
          final dynamic decoded = jsonDecode(raw);
          if (decoded is List) {
            for (final item in decoded) {
              if (item is Map) {
                final m = Map<String, dynamic>.from(item);
                final id = m['id'] as String? ?? '';
                if (id.isNotEmpty) result[id] = m;
                final sp = m['storagePath'] as String? ?? '';
                if (sp.isNotEmpty) result[sp] = m;
              }
            }
          }
        }
      } catch (_) {}

      if (result.isNotEmpty) return result;

      // 2. Try Appwrite Storage bucket manifest file
      try {
        final storage = AppwriteClient.instance.storage;
        final fileList = await storage.listFiles(
          bucketId: AppwriteConfig.photosBucket,
          queries: [Query.limit(100)],
        );

        final targetName = 'manifest_$effectiveUserId.json';
        final manifestFile = fileList.files
            .where((f) => f.name == targetName || f.name == 'manifest.json')
            .firstOrNull;

        if (manifestFile != null) {
          Uint8List? bytes;
          try {
            bytes = await storage.getFileDownload(
              bucketId: AppwriteConfig.photosBucket,
              fileId: manifestFile.$id,
            );
          } catch (_) {
            final url = AppwriteClient.instance.getFileViewUrl(manifestFile.$id);
            final res = await http.get(Uri.parse(url));
            if (res.statusCode == 200) {
              bytes = res.bodyBytes;
            }
          }

          if (bytes != null && bytes.isNotEmpty) {
            final jsonStr = utf8.decode(bytes);
            final dynamic decoded = jsonDecode(jsonStr);
            if (decoded is List) {
              for (final item in decoded) {
                if (item is Map) {
                  final m = Map<String, dynamic>.from(item);
                  final id = m['id'] as String? ?? '';
                  if (id.isNotEmpty) result[id] = m;
                  final sp = m['storagePath'] as String? ?? '';
                  if (sp.isNotEmpty) result[sp] = m;
                }
              }
            }
          }
        }
      } catch (_) {}
    } catch (_) {}

    return result;
  }

  /// Chronologically resolve and assign day numbers from baseline dates and progression
  List<ProgressPhoto> _resolveDayNumbers(List<ProgressPhoto> inputPhotos) {
    if (inputPhotos.isEmpty) return inputPhotos;

    // Sort chronologically ascending (earliest first) to establish baseline
    final sortedAsc = List<ProgressPhoto>.from(inputPhotos)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final baselineDate = sortedAsc.first.createdAt;
    final resolved = <ProgressPhoto>[];

    for (int i = 0; i < sortedAsc.length; i++) {
      final photo = sortedAsc[i];
      final explicitDay =
          photo.dayNumber ?? ProgressPhoto.extractDayNumber(photo.notes);

      if (explicitDay != null) {
        resolved.add(photo.copyWith(dayNumber: explicitDay));
      } else {
        final dPhoto =
            DateTime(photo.createdAt.year, photo.createdAt.month, photo.createdAt.day);
        final dBase =
            DateTime(baselineDate.year, baselineDate.month, baselineDate.day);
        final diffDays = dPhoto.difference(dBase).inDays;

        int computedDay = diffDays >= 0 ? diffDays + 1 : 1;

        // If multiple photos end up with the same day because they were uploaded in batch
        // on the same date/timestamp with the same pose:
        // ensure distinct progressive days so user doesn't see duplicate day badges
        final samePosePrevious =
            resolved.where((p) => p.pose == photo.pose).toList();
        final isDuplicateDay =
            samePosePrevious.any((p) => p.effectiveDayNumber == computedDay);

        if (isDuplicateDay) {
          final maxDay = samePosePrevious
              .map((p) => p.effectiveDayNumber)
              .reduce((a, b) => a > b ? a : b);
          computedDay = maxDay + 1;
        }

        resolved.add(photo.copyWith(
          dayNumber: computedDay,
          notes: (photo.notes == null || photo.notes!.isEmpty)
              ? '[Day $computedDay]'
              : (photo.notes!.contains(RegExp(r'\[Day\s*\d+\]'))
                  ? photo.notes
                  : '[Day $computedDay] ${photo.notes}'),
        ));
      }
    }

    // Return sorted descending (newest first for UI displays)
    resolved.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return resolved;
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
              notes: local.notes ?? remote.notes,
              pose: local.pose,
              weightAtCapture: local.weightAtCapture ?? remote.weightAtCapture,
              dayNumber: local.dayNumber ?? remote.dayNumber,
              createdAt: local.createdAt,
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

        _cache = _resolveDayNumbers(merged);
      }
      _controller.add(List.unmodifiable(_cache));
      await _saveToLocal(userId);
    } catch (_) {
      _controller.add(List.unmodifiable(_cache));
    }
  }

  @override
  Future<List<ProgressPhoto>> getPhotos(String userId) async {
    if (!AppwriteConfig.isConfigured) {
      return _cache;
    }

    final effectiveUserId = await _resolveEffectiveUserId(userId);
    final manifestMap = await _loadManifest(effectiveUserId);

    final photos = <ProgressPhoto>[];
    final foundStorageIds = <String>{};

    // 1. Try querying Appwrite Databases collection (with fallbacks if unindexed)
    try {
      final db = AppwriteClient.instance.databases;
      dynamic records;
      try {
        records = await db.listDocuments(
          databaseId: AppwriteConfig.databaseId,
          collectionId: AppwriteConfig.progressPhotosCollection,
          queries: [
            Query.equal('user_id', effectiveUserId),
            Query.orderDesc('created_at'),
            Query.limit(100),
          ],
        );
      } catch (_) {
        try {
          records = await db.listDocuments(
            databaseId: AppwriteConfig.databaseId,
            collectionId: AppwriteConfig.progressPhotosCollection,
            queries: [Query.limit(100)],
          );
        } catch (_) {}
      }

      if (records != null) {
        for (final doc in records.documents) {
          final data = doc.data;
          final fileId =
              (data['file_id'] ?? data['storage_path']) as String? ?? '';
          String? downloadUrl;

          if (fileId.isNotEmpty) {
            downloadUrl = AppwriteClient.instance.getFileViewUrl(fileId);
            foundStorageIds.add(fileId);
          }

          final manifestMatch = manifestMap[doc.$id] ?? manifestMap[fileId];

          photos.add(
            ProgressPhoto(
              id: doc.$id,
              userId: data['user_id'] as String? ?? effectiveUserId,
              storagePath: fileId,
              downloadUrl: downloadUrl,
              pose: (manifestMatch?['pose'] as String?) ??
                  (data['pose'] as String?) ??
                  'Front',
              workoutId: (manifestMatch?['workoutId'] as String?) ??
                  (data['workout_id'] as String?),
              weightAtCapture: (manifestMatch?['weightAtCapture'] as num?)
                      ?.toDouble() ??
                  (data['weight_at_capture'] as num?)?.toDouble(),
              notes: (manifestMatch?['notes'] as String?) ??
                  (data['notes'] as String?),
              dayNumber: (manifestMatch?['dayNumber'] as int?) ??
                  (data['day_number'] ?? data['dayNumber']) as int? ??
                  ProgressPhoto.extractDayNumber(data['notes'] as String?),
              createdAt: manifestMatch?['createdAt'] != null
                  ? (DateTime.tryParse(manifestMatch!['createdAt'] as String) ??
                      DateTime.now())
                  : (DateTime.tryParse(data['created_at'] as String? ?? '') ??
                      DateTime.now()),
            ),
          );
        }
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
        // Skip manifest files from photo listing
        if (fileName.startsWith('manifest') || fileName.endsWith('.json')) {
          continue;
        }

        final photoId = fileName.contains('.')
            ? fileName.split('.').first
            : (fileName.isNotEmpty ? fileName : 'photo-$fileId');

        // Check manifest metadata match
        final manifestMatch = manifestMap[photoId] ??
            manifestMap[fileId] ??
            manifestMap['photo-$fileId'];

        // Check local cache match
        final localMatch = _cache
            .where((p) =>
                p.id == photoId ||
                p.storagePath == fileId ||
                p.storagePath == photoId)
            .firstOrNull;

        // Resolve createdAt
        DateTime photoDate;
        if (manifestMatch != null && manifestMatch['createdAt'] != null) {
          photoDate = DateTime.tryParse(manifestMatch['createdAt'] as String) ??
              DateTime.now();
        } else if (localMatch != null) {
          photoDate = localMatch.createdAt;
        } else {
          // Parse date from filename e.g. date1789800000000 or photo-1789800000000
          final dateMatch = RegExp(r'date[-_]?(\d+)').firstMatch(fileName);
          if (dateMatch != null) {
            final ms = int.tryParse(dateMatch.group(1)!);
            photoDate = ms != null
                ? DateTime.fromMillisecondsSinceEpoch(ms)
                : DateTime.now();
          } else if (photoId.startsWith('photo-')) {
            final msStr = photoId.replaceFirst('photo-', '');
            final ms = int.tryParse(msStr);
            photoDate = ms != null
                ? DateTime.fromMillisecondsSinceEpoch(ms)
                : (DateTime.tryParse(file.$createdAt) ?? DateTime.now());
          } else {
            photoDate = DateTime.tryParse(file.$createdAt) ?? DateTime.now();
          }
        }

        // Resolve dayNumber
        int? dayNum = (manifestMatch?['dayNumber'] ??
                manifestMatch?['day_number']) as int? ??
            localMatch?.dayNumber;
        if (dayNum == null) {
          final dayMatch =
              RegExp(r'day[-_]?(\d+)', caseSensitive: false).firstMatch(fileName);
          if (dayMatch != null) {
            dayNum = int.tryParse(dayMatch.group(1)!);
          }
        }

        // Resolve pose
        String pose = (manifestMatch?['pose'] as String?) ??
            localMatch?.pose ??
            'Front';
        if (pose == 'Front') {
          final poseMatch =
              RegExp(r'pose[-_]?([A-Za-z]+)', caseSensitive: false)
                  .firstMatch(fileName);
          if (poseMatch != null) {
            pose = poseMatch.group(1)!;
          }
        }

        // Resolve notes
        String? notes = (manifestMatch?['notes'] as String?) ??
            localMatch?.notes;
        if (notes == null && dayNum != null) {
          notes = '[Day $dayNum]';
        }

        final downloadUrl = AppwriteClient.instance.getFileViewUrl(fileId);
        foundStorageIds.add(fileId);

        photos.add(
          ProgressPhoto(
            id: photoId,
            userId: effectiveUserId,
            storagePath: fileId,
            downloadUrl: downloadUrl,
            localFilePath: localMatch?.localFilePath,
            pose: pose,
            workoutId: (manifestMatch?['workoutId'] as String?) ??
                localMatch?.workoutId,
            weightAtCapture: (manifestMatch?['weightAtCapture'] as num?)
                    ?.toDouble() ??
                localMatch?.weightAtCapture,
            notes: notes,
            dayNumber: dayNum,
            createdAt: photoDate,
          ),
        );
      }
    } catch (_) {
      // Storage listing error caught
    }

    if (photos.isNotEmpty) {
      final resolved = _resolveDayNumbers(photos);
      // If manifest was empty or missing items, sync resolved metadata to cloud
      if (manifestMap.isEmpty || manifestMap.length < resolved.length) {
        _cache = resolved;
        _syncManifest(effectiveUserId);
      }
      return resolved;
    }

    return _resolveDayNumbers(_cache);
  }

  @override
  Future<void> savePhoto(ProgressPhoto photo) async {
    _cache.removeWhere((p) => p.id == photo.id || p.storagePath == photo.storagePath);
    _cache.insert(0, photo);
    _cache = _resolveDayNumbers(_cache);
    _controller.add(List.unmodifiable(_cache));
    await _saveToLocal(photo.userId);

    if (!AppwriteConfig.isConfigured) return;

    final effectiveUserId = await _resolveEffectiveUserId(photo.userId);
    final permissions = [
      Permission.read(Role.any()),
      Permission.write(Role.any()),
      Permission.update(Role.any()),
      Permission.delete(Role.any()),
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

          // Encode day, date, and pose into filename for bulletproof retrieval
          final dayTag = 'day${photo.effectiveDayNumber}';
          final dateTag = 'date${photo.createdAt.millisecondsSinceEpoch}';
          final poseTag = 'pose${photo.pose}';
          final newFilename =
              '${photo.id}_${dayTag}_${dateTag}_$poseTag.$ext';

          final uploadedFile = await AppwriteClient.instance.storage.createFile(
            bucketId: AppwriteConfig.photosBucket,
            fileId: newFileId,
            file: InputFile.fromBytes(
              bytes: bytes,
              filename: newFilename,
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
          _cache = _resolveDayNumbers(_cache);
          _controller.add(List.unmodifiable(_cache));
          await _saveToLocal(photo.userId);
        }
      } catch (_) {}
    }

    // 2. Synchronize Cloud Manifest (Appwrite Storage & Account Prefs)
    await _syncManifest(effectiveUserId);

    // 3. Save metadata in Appwrite Databases if collection exists
    try {
      final formattedNotes =
          photo.toMap()['notes'] as String? ?? photo.notes ?? '';
      final docData = {
        'user_id': effectiveUserId,
        'file_id': fileId,
        'storage_path': fileId,
        'pose': photo.pose,
        'workout_id': photo.workoutId ?? '',
        'weight_at_capture': photo.weightAtCapture ?? 0.0,
        'notes': formattedNotes,
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
          } catch (_) {
            final fallback = Map<String, dynamic>.from(docData)
              ..remove('day_number');
            try {
              await AppwriteClient.instance.databases.createDocument(
                databaseId: AppwriteConfig.databaseId,
                collectionId: AppwriteConfig.progressPhotosCollection,
                documentId: photo.id,
                data: fallback,
                permissions: permissions,
              );
            } catch (_) {}
          }
        } else {
          final fallback = Map<String, dynamic>.from(docData)
            ..remove('day_number');
          try {
            await AppwriteClient.instance.databases.updateDocument(
              databaseId: AppwriteConfig.databaseId,
              collectionId: AppwriteConfig.progressPhotosCollection,
              documentId: photo.id,
              data: fallback,
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
    _cache = _resolveDayNumbers(_cache);
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
            (existing.data['file_id'] ?? existing.data['storage_path'])
                as String?;
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

    // 3. Update Cloud Manifest
    await _syncManifest(uid);
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
