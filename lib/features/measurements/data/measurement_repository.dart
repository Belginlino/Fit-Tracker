import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fittrack/core/network/api_client.dart';
import 'package:fittrack/core/network/api_endpoints.dart';
import '../domain/measurement.dart';

abstract class MeasurementRepository {
  Stream<List<BodyMeasurement>> getMeasurementsStream(String userId, {String? type});
  Future<List<BodyMeasurement>> getMeasurements(String userId, {String? type});
  Future<void> saveMeasurement(BodyMeasurement measurement);
  Future<void> deleteMeasurement(String measurementId);
}

/// Cloudflare Workers & D1 implementation
class CloudflareMeasurementRepository implements MeasurementRepository {
  final _controller = StreamController<List<BodyMeasurement>>.broadcast();
  List<BodyMeasurement> _cache = [];

  @override
  Stream<List<BodyMeasurement>> getMeasurementsStream(String userId, {String? type}) {
    _fetchAndEmit(userId, type: type);
    return _controller.stream.map((list) {
      if (type != null) {
        return list.where((m) => m.type == type).toList();
      }
      return list;
    });
  }

  Future<void> _fetchAndEmit(String userId, {String? type}) async {
    try {
      final records = await getMeasurements(userId, type: type);
      _cache = records;
      _controller.add(_cache);
    } catch (_) {
      _controller.add(_cache);
    }
  }

  @override
  Future<List<BodyMeasurement>> getMeasurements(String userId, {String? type}) async {
    final url = type != null ? '${ApiEndpoints.measurements}?type=$type' : ApiEndpoints.measurements;
    final data = await ApiClient.instance.get(url);
    if (data is List) {
      return data.map((json) => BodyMeasurement.fromMap(json, json['id'])).toList();
    }
    return [];
  }

  @override
  Future<void> saveMeasurement(BodyMeasurement measurement) async {
    final data = await ApiClient.instance.post(ApiEndpoints.measurements, body: measurement.toMap());
    final created = BodyMeasurement.fromMap(data, data['id'] ?? measurement.id);
    _cache.insert(0, created);
    _controller.add(List.unmodifiable(_cache));
  }

  @override
  Future<void> deleteMeasurement(String measurementId) async {
    await ApiClient.instance.delete('${ApiEndpoints.measurements}/$measurementId');
    _cache.removeWhere((m) => m.id == measurementId);
    _controller.add(List.unmodifiable(_cache));
  }
}

/// Local mock repository for demo and offline fallback
class LocalMockMeasurementRepository implements MeasurementRepository {
  final _controller = StreamController<List<BodyMeasurement>>.broadcast();

  final List<BodyMeasurement> _measurements = [
    BodyMeasurement(
      id: 'm-1',
      userId: 'demo-user-101',
      type: 'Weight',
      value: 74.2,
      unit: 'kg',
      recordedAt: DateTime.now().subtract(const Duration(days: 1)),
      note: 'Morning weigh-in',
    ),
    BodyMeasurement(
      id: 'm-2',
      userId: 'demo-user-101',
      type: 'Weight',
      value: 73.8,
      unit: 'kg',
      recordedAt: DateTime.now().subtract(const Duration(days: 7)),
    ),
    BodyMeasurement(
      id: 'm-3',
      userId: 'demo-user-101',
      type: 'Weight',
      value: 73.1,
      unit: 'kg',
      recordedAt: DateTime.now().subtract(const Duration(days: 14)),
    ),
    BodyMeasurement(
      id: 'm-4',
      userId: 'demo-user-101',
      type: 'Weight',
      value: 72.4,
      unit: 'kg',
      recordedAt: DateTime.now().subtract(const Duration(days: 21)),
    ),
    BodyMeasurement(
      id: 'm-5',
      userId: 'demo-user-101',
      type: 'Weight',
      value: 71.5,
      unit: 'kg',
      recordedAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    BodyMeasurement(
      id: 'm-6',
      userId: 'demo-user-101',
      type: 'Chest',
      value: 104.0,
      unit: 'cm',
      recordedAt: DateTime.now().subtract(const Duration(days: 7)),
    ),
    BodyMeasurement(
      id: 'm-7',
      userId: 'demo-user-101',
      type: 'Waist',
      value: 81.0,
      unit: 'cm',
      recordedAt: DateTime.now().subtract(const Duration(days: 7)),
    ),
    BodyMeasurement(
      id: 'm-8',
      userId: 'demo-user-101',
      type: 'Left Arm',
      value: 38.5,
      unit: 'cm',
      recordedAt: DateTime.now().subtract(const Duration(days: 7)),
    ),
  ];

  LocalMockMeasurementRepository() {
    Future.microtask(() => _controller.add(_measurements));
  }

  @override
  Stream<List<BodyMeasurement>> getMeasurementsStream(String userId, {String? type}) {
    if (type != null) {
      return _controller.stream.map((list) => list.where((m) => m.type == type).toList());
    }
    return _controller.stream;
  }

  @override
  Future<List<BodyMeasurement>> getMeasurements(String userId, {String? type}) async {
    if (type != null) {
      return _measurements.where((m) => m.type == type).toList();
    }
    return List.unmodifiable(_measurements);
  }

  @override
  Future<void> saveMeasurement(BodyMeasurement measurement) async {
    _measurements.insert(0, measurement);
    _controller.add(List.unmodifiable(_measurements));
  }

  @override
  Future<void> deleteMeasurement(String measurementId) async {
    _measurements.removeWhere((m) => m.id == measurementId);
    _controller.add(List.unmodifiable(_measurements));
  }
}

// Riverpod Providers
final measurementRepositoryProvider = Provider<MeasurementRepository>((ref) {
  return LocalMockMeasurementRepository();
});

final weightHistoryStreamProvider = StreamProvider.family<List<BodyMeasurement>, String>((ref, userId) {
  final repo = ref.watch(measurementRepositoryProvider);
  return repo.getMeasurementsStream(userId, type: 'Weight');
});

final bodyCircumferenceStreamProvider = StreamProvider.family<List<BodyMeasurement>, String>((ref, userId) {
  final repo = ref.watch(measurementRepositoryProvider);
  return repo.getMeasurementsStream(userId);
});
