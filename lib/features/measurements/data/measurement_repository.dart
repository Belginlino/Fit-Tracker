import 'dart:async';
import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fittrack/core/appwrite/appwrite_client.dart';
import 'package:fittrack/core/appwrite/appwrite_config.dart';
import '../domain/measurement.dart';

abstract class MeasurementRepository {
  Stream<List<BodyMeasurement>> getMeasurementsStream(String userId,
      {String? type});
  Future<List<BodyMeasurement>> getMeasurements(String userId, {String? type});
  Future<void> saveMeasurement(BodyMeasurement measurement);
  Future<void> deleteMeasurement(String measurementId);
}

/// Appwrite Database implementation for Body Measurements
class AppwriteMeasurementRepository implements MeasurementRepository {
  final _controller = StreamController<List<BodyMeasurement>>.broadcast();
  List<BodyMeasurement> _cache = [];

  @override
  Stream<List<BodyMeasurement>> getMeasurementsStream(String userId,
      {String? type}) {
    _fetchAndEmit(userId, type: type);
    return _controller.stream.map((list) {
      if (type != null) {
        return list
            .where((m) => m.type.toLowerCase() == type.toLowerCase())
            .toList();
      }
      return list;
    });
  }

  Future<void> _fetchAndEmit(String userId, {String? type}) async {
    try {
      final records = await getMeasurements(userId, type: type);
      _cache = records;
      _controller.add(List.unmodifiable(_cache));
    } catch (_) {
      _controller.add(List.unmodifiable(_cache));
    }
  }

  @override
  Future<List<BodyMeasurement>> getMeasurements(String userId,
      {String? type}) async {
    if (!AppwriteConfig.isConfigured) return [];

    try {
      final db = AppwriteClient.instance.databases;
      final queries = [
        Query.equal('user_id', userId),
        Query.orderDesc('recorded_at'),
        Query.limit(100),
      ];

      if (type != null) {
        queries.add(Query.equal('measurement_type', type.toLowerCase()));
      }

      final response = await db.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.measurementsCollection,
        queries: queries,
      );

      final list = response.documents.map((doc) {
        final item = doc.data;
        final rawType = item['measurement_type'] as String? ?? 'weight';
        final formattedType = rawType.isEmpty
            ? 'Weight'
            : rawType[0].toUpperCase() + rawType.substring(1);

        return BodyMeasurement(
          id: doc.$id,
          userId: item['user_id'] as String? ?? userId,
          type: formattedType,
          value: (item['value'] as num).toDouble(),
          unit: item['unit'] as String? ?? 'kg',
          recordedAt: DateTime.tryParse(item['recorded_at'] as String? ?? '') ??
              DateTime.now(),
          note: item['notes'] as String?,
        );
      }).toList();

      _cache = list;
      return list;
    } catch (_) {
      return _cache;
    }
  }

  @override
  Future<void> saveMeasurement(BodyMeasurement measurement) async {
    _cache.removeWhere((m) => m.id == measurement.id);
    _cache.insert(0, measurement);
    _controller.add(List.unmodifiable(_cache));

    if (!AppwriteConfig.isConfigured) return;

    try {
      final db = AppwriteClient.instance.databases;
      final permissions = [
        Permission.read(Role.user(measurement.userId)),
        Permission.update(Role.user(measurement.userId)),
        Permission.delete(Role.user(measurement.userId)),
      ];

      final docData = {
        'user_id': measurement.userId,
        'measurement_type': measurement.type.toLowerCase(),
        'value': measurement.value,
        'unit': measurement.unit,
        'recorded_at': measurement.recordedAt.toIso8601String(),
        'notes': measurement.note ?? '',
      };

      try {
        await db.updateDocument(
          databaseId: AppwriteConfig.databaseId,
          collectionId: AppwriteConfig.measurementsCollection,
          documentId: measurement.id,
          data: docData,
        );
      } on AppwriteException catch (e) {
        if (e.code == 404) {
          await db.createDocument(
            databaseId: AppwriteConfig.databaseId,
            collectionId: AppwriteConfig.measurementsCollection,
            documentId: measurement.id,
            data: docData,
            permissions: permissions,
          );
        }
      }
    } catch (_) {}
  }

  @override
  Future<void> deleteMeasurement(String measurementId) async {
    _cache.removeWhere((m) => m.id == measurementId);
    _controller.add(List.unmodifiable(_cache));

    if (!AppwriteConfig.isConfigured) return;

    try {
      final db = AppwriteClient.instance.databases;
      await db.deleteDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.measurementsCollection,
        documentId: measurementId,
      );
    } catch (_) {}
  }
}

// Global Riverpod Providers
final measurementRepositoryProvider = Provider<MeasurementRepository>((ref) {
  return AppwriteMeasurementRepository();
});

final weightHistoryStreamProvider =
    StreamProvider.family<List<BodyMeasurement>, String>((ref, userId) {
  final repo = ref.watch(measurementRepositoryProvider);
  return repo.getMeasurementsStream(userId, type: 'Weight');
});

final bodyCircumferenceStreamProvider =
    StreamProvider.family<List<BodyMeasurement>, String>((ref, userId) {
  final repo = ref.watch(measurementRepositoryProvider);
  return repo.getMeasurementsStream(userId);
});
