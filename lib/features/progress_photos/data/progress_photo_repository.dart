import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fittrack/core/supabase/supabase_config.dart';
import '../domain/progress_photo.dart';

abstract class ProgressPhotoRepository {
  Stream<List<ProgressPhoto>> getPhotosStream(String userId);
  Future<List<ProgressPhoto>> getPhotos(String userId);
  Future<void> savePhoto(ProgressPhoto photo);
  Future<void> deletePhoto(String photoId);
}

/// Supabase Storage & PostgreSQL implementation for Progress Photos
class SupabaseProgressPhotoRepository implements ProgressPhotoRepository {
  final _controller = StreamController<List<ProgressPhoto>>.broadcast();
  List<ProgressPhoto> _cache = [];

  @override
  Stream<List<ProgressPhoto>> getPhotosStream(String userId) {
    _fetchAndEmit(userId);
    return _controller.stream;
  }

  Future<void> _fetchAndEmit(String userId) async {
    try {
      final photos = await getPhotos(userId);
      _cache = photos;
      _controller.add(List.unmodifiable(_cache));
    } catch (_) {
      _controller.add(List.unmodifiable(_cache));
    }
  }

  @override
  Future<List<ProgressPhoto>> getPhotos(String userId) async {
    if (!SupabaseConfig.isConfigured) return [];

    final client = Supabase.instance.client;
    final records = await client
        .from('progress_photos')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    final photos = <ProgressPhoto>[];
    for (final item in records as List<dynamic>) {
      final storagePath = item['storage_path'] as String? ?? '';
      String? downloadUrl;

      if (storagePath.isNotEmpty) {
        try {
          downloadUrl = await client.storage
              .from(SupabaseConfig.photosBucket)
              .createSignedUrl(storagePath, 60 * 60 * 24 * 7); // 7 days
        } catch (_) {}
      }

      photos.add(
        ProgressPhoto(
          id: item['id'] as String,
          userId: item['user_id'] as String,
          storagePath: storagePath,
          downloadUrl: downloadUrl,
          pose: item['pose'] as String? ?? 'Front',
          workoutId: item['workout_id'] as String?,
          weightAtCapture: (item['weight_at_capture'] as num?)?.toDouble(),
          notes: item['notes'] as String?,
          createdAt: DateTime.tryParse(item['created_at'] as String? ?? '') ?? DateTime.now(),
        ),
      );
    }

    _cache = photos;
    return photos;
  }

  @override
  Future<void> savePhoto(ProgressPhoto photo) async {
    if (!SupabaseConfig.isConfigured) return;

    final client = Supabase.instance.client;
    String storagePath = photo.storagePath;
    String? downloadUrl = photo.downloadUrl;

    // 1. Upload image to Supabase Storage if local file exists
    if (photo.localFilePath != null) {
      final file = File(photo.localFilePath!);
      if (await file.exists()) {
        final isPng = photo.localFilePath!.toLowerCase().endsWith('.png');
        final ext = isPng ? 'png' : 'webp';
        final mimeType = isPng ? 'image/png' : 'image/webp';
        storagePath = '${photo.userId}/progress/${photo.id}/original.$ext';

        await client.storage.from(SupabaseConfig.photosBucket).upload(
              storagePath,
              file,
              fileOptions: FileOptions(contentType: mimeType, upsert: true),
            );

        try {
          downloadUrl = await client.storage
              .from(SupabaseConfig.photosBucket)
              .createSignedUrl(storagePath, 60 * 60 * 24 * 30); // 30 days
        } catch (_) {}
      }
    }

    // 2. Insert metadata row in PostgreSQL
    await client.from('progress_photos').upsert({
      'id': photo.id,
      'user_id': photo.userId,
      'storage_path': storagePath,
      'pose': photo.pose,
      'workout_id': photo.workoutId,
      'weight_at_capture': photo.weightAtCapture,
      'notes': photo.notes,
      'created_at': photo.createdAt.toIso8601String(),
    });

    final created = photo.copyWith(
      storagePath: storagePath,
      downloadUrl: downloadUrl,
    );

    _cache.removeWhere((p) => p.id == photo.id);
    _cache.insert(0, created);
    _controller.add(List.unmodifiable(_cache));
  }

  @override
  Future<void> deletePhoto(String photoId) async {
    if (!SupabaseConfig.isConfigured) return;

    final client = Supabase.instance.client;

    // 1. Fetch storage path to remove from Storage bucket
    final existing = await client
        .from('progress_photos')
        .select('storage_path')
        .eq('id', photoId)
        .maybeSingle();

    if (existing != null && existing['storage_path'] != null) {
      try {
        await client.storage
            .from(SupabaseConfig.photosBucket)
            .remove([existing['storage_path'] as String]);
      } catch (_) {}
    }

    // 2. Delete metadata row in PostgreSQL
    await client.from('progress_photos').delete().eq('id', photoId);

    _cache.removeWhere((p) => p.id == photoId);
    _controller.add(List.unmodifiable(_cache));
  }
}

// Global Riverpod Providers
final progressPhotoRepositoryProvider = Provider<ProgressPhotoRepository>((ref) {
  return SupabaseProgressPhotoRepository();
});

final progressPhotosStreamProvider = StreamProvider.family<List<ProgressPhoto>, String>((ref, userId) {
  final repo = ref.watch(progressPhotoRepositoryProvider);
  return repo.getPhotosStream(userId);
});
