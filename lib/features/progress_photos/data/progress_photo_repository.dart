import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fittrack/core/network/api_client.dart';
import 'package:fittrack/core/network/api_endpoints.dart';
import '../domain/progress_photo.dart';

abstract class ProgressPhotoRepository {
  Stream<List<ProgressPhoto>> getPhotosStream(String userId);
  Future<List<ProgressPhoto>> getPhotos(String userId);
  Future<void> savePhoto(ProgressPhoto photo);
  Future<void> deletePhoto(String photoId);
}

/// Cloudflare Workers & R2 implementation
class CloudflareProgressPhotoRepository implements ProgressPhotoRepository {
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
      _controller.add(_cache);
    } catch (_) {
      _controller.add(_cache);
    }
  }

  @override
  Future<List<ProgressPhoto>> getPhotos(String userId) async {
    final data = await ApiClient.instance.get(ApiEndpoints.photos);
    if (data is List) {
      return data.map((json) => ProgressPhoto.fromMap(json, json['id'])).toList();
    }
    return [];
  }

  @override
  Future<void> savePhoto(ProgressPhoto photo) async {
    // Record photo metadata in D1
    final data = await ApiClient.instance.post(ApiEndpoints.photos, body: {
      'id': photo.id,
      'objectKey': photo.storagePath,
      'pose': photo.pose,
      'workoutId': photo.workoutId,
      'weightAtCapture': photo.weightAtCapture,
      'notes': photo.notes,
    });

    final created = ProgressPhoto.fromMap(data, data['id'] ?? photo.id);
    _cache.insert(0, created);
    _controller.add(List.unmodifiable(_cache));
  }

  @override
  Future<void> deletePhoto(String photoId) async {
    await ApiClient.instance.delete('${ApiEndpoints.photos}/$photoId');
    _cache.removeWhere((p) => p.id == photoId);
    _controller.add(List.unmodifiable(_cache));
  }
}

/// Local mock repository for demo and offline fallback
class LocalMockProgressPhotoRepository implements ProgressPhotoRepository {
  final _controller = StreamController<List<ProgressPhoto>>.broadcast();

  final List<ProgressPhoto> _photos = [
    ProgressPhoto(
      id: 'photo-3',
      userId: 'demo-user-101',
      storagePath: 'users/demo-user-101/progress/photo-3.jpg',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      pose: 'Front',
      weightAtCapture: 74.2,
      notes: 'Shoulders looking fuller, post push-day pump.',
    ),
    ProgressPhoto(
      id: 'photo-2',
      userId: 'demo-user-101',
      storagePath: 'users/demo-user-101/progress/photo-2.jpg',
      createdAt: DateTime.now().subtract(const Duration(days: 14)),
      pose: 'Front',
      weightAtCapture: 72.8,
      notes: 'Midway check-in. Energy is solid.',
    ),
    ProgressPhoto(
      id: 'photo-1',
      userId: 'demo-user-101',
      storagePath: 'users/demo-user-101/progress/photo-1.jpg',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      pose: 'Front',
      weightAtCapture: 71.0,
      notes: 'Day 1 starting condition.',
    ),
  ];

  LocalMockProgressPhotoRepository() {
    Future.microtask(() => _controller.add(_photos));
  }

  @override
  Stream<List<ProgressPhoto>> getPhotosStream(String userId) => _controller.stream;

  @override
  Future<List<ProgressPhoto>> getPhotos(String userId) async {
    return List.unmodifiable(_photos);
  }

  @override
  Future<void> savePhoto(ProgressPhoto photo) async {
    _photos.insert(0, photo);
    _controller.add(List.unmodifiable(_photos));
  }

  @override
  Future<void> deletePhoto(String photoId) async {
    _photos.removeWhere((p) => p.id == photoId);
    _controller.add(List.unmodifiable(_photos));
  }
}

// Riverpod Providers
final progressPhotoRepositoryProvider = Provider<ProgressPhotoRepository>((ref) {
  return LocalMockProgressPhotoRepository();
});

final progressPhotosStreamProvider = StreamProvider.family<List<ProgressPhoto>, String>((ref, userId) {
  final repo = ref.watch(progressPhotoRepositoryProvider);
  return repo.getPhotosStream(userId);
});
