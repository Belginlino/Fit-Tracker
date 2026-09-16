import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fittrack/core/supabase/supabase_config.dart';
import '../domain/measurement.dart';

abstract class MeasurementRepository {
  Stream<List<BodyMeasurement>> getMeasurementsStream(String userId, {String? type});
  Future<List<BodyMeasurement>> getMeasurements(String userId, {String? type});
  Future<void> saveMeasurement(BodyMeasurement measurement);
  Future<void> deleteMeasurement(String measurementId);
}

/// Supabase PostgreSQL implementation for Body Measurements
class SupabaseMeasurementRepository implements MeasurementRepository {
  final _controller = StreamController<List<BodyMeasurement>>.broadcast();
  List<BodyMeasurement> _cache = [];

  @override
  Stream<List<BodyMeasurement>> getMeasurementsStream(String userId, {String? type}) {
    _fetchAndEmit(userId, type: type);
    return _controller.stream.map((list) {
      if (type != null) {
        return list.where((m) => m.type.toLowerCase() == type.toLowerCase()).toList();
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
  Future<List<BodyMeasurement>> getMeasurements(String userId, {String? type}) async {
    if (!SupabaseConfig.isConfigured) return [];

    final client = Supabase.instance.client;
    var query = client
        .from('measurements')
        .select('id, user_id, measurement_type, value, unit, recorded_at, notes')
        .eq('user_id', userId);

    if (type != null) {
      query = query.eq('measurement_type', type.toLowerCase());
    }

    final response = await query.order('recorded_at', ascending: false);
    final list = (response as List<dynamic>).map((item) {
      final rawType = item['measurement_type'] as String? ?? 'weight';
      final formattedType = rawType.isEmpty
          ? 'Weight'
          : rawType[0].toUpperCase() + rawType.substring(1);

      return BodyMeasurement(
        id: item['id'] as String,
        userId: item['user_id'] as String,
        type: formattedType,
        value: (item['value'] as num).toDouble(),
        unit: item['unit'] as String? ?? 'kg',
        recordedAt: DateTime.tryParse(item['recorded_at'] as String? ?? '') ?? DateTime.now(),
        note: item['notes'] as String?,
      );
    }).toList();

    _cache = list;
    return list;
  }

  @override
  Future<void> saveMeasurement(BodyMeasurement measurement) async {
    if (!SupabaseConfig.isConfigured) return;

    final client = Supabase.instance.client;
    await client.from('measurements').upsert({
      'id': measurement.id,
      'user_id': measurement.userId,
      'measurement_type': measurement.type.toLowerCase(),
      'value': measurement.value,
      'unit': measurement.unit,
      'recorded_at': measurement.recordedAt.toIso8601String(),
      'notes': measurement.note,
    });

    _cache.removeWhere((m) => m.id == measurement.id);
    _cache.insert(0, measurement);
    _controller.add(List.unmodifiable(_cache));
  }

  @override
  Future<void> deleteMeasurement(String measurementId) async {
    if (!SupabaseConfig.isConfigured) return;

    final client = Supabase.instance.client;
    await client.from('measurements').delete().eq('id', measurementId);

    _cache.removeWhere((m) => m.id == measurementId);
    _controller.add(List.unmodifiable(_cache));
  }
}

// Global Riverpod Providers
final measurementRepositoryProvider = Provider<MeasurementRepository>((ref) {
  return SupabaseMeasurementRepository();
});

final weightHistoryStreamProvider = StreamProvider.family<List<BodyMeasurement>, String>((ref, userId) {
  final repo = ref.watch(measurementRepositoryProvider);
  return repo.getMeasurementsStream(userId, type: 'Weight');
});

final bodyCircumferenceStreamProvider = StreamProvider.family<List<BodyMeasurement>, String>((ref, userId) {
  final repo = ref.watch(measurementRepositoryProvider);
  return repo.getMeasurementsStream(userId);
});
