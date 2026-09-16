import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:fittrack/core/supabase/supabase_config.dart';
import '../domain/workout.dart';

abstract class WorkoutRepository {
  Stream<List<Workout>> getWorkoutsStream(String userId);
  Future<List<Workout>> getWorkouts(String userId);
  Future<void> saveWorkout(Workout workout);
  Future<void> deleteWorkout(String workoutId);
  Future<Map<String, double>> getPersonalRecords(String userId);
}

/// Supabase PostgreSQL implementation for Workouts, Exercises, Sets, and PRs
class SupabaseWorkoutRepository implements WorkoutRepository {
  final _controller = StreamController<List<Workout>>.broadcast();
  List<Workout> _cache = [];

  @override
  Stream<List<Workout>> getWorkoutsStream(String userId) {
    _fetchAndEmit(userId);
    return _controller.stream;
  }

  Future<void> _fetchAndEmit(String userId) async {
    try {
      final workouts = await getWorkouts(userId);
      _cache = workouts;
      _controller.add(List.unmodifiable(_cache));
    } catch (_) {
      _controller.add(List.unmodifiable(_cache));
    }
  }

  @override
  Future<List<Workout>> getWorkouts(String userId) async {
    if (!SupabaseConfig.isConfigured) return [];

    final client = Supabase.instance.client;
    final response = await client
        .from('workouts')
        .select(
            'id, user_id, title, workout_date, duration_minutes, notes, workout_exercises(id, exercise_name, exercise_order, workout_sets(id, set_number, weight, reps, is_completed))')
        .eq('user_id', userId)
        .order('workout_date', ascending: false);

    final List<dynamic> data = response as List<dynamic>;
    final workouts = <Workout>[];

    for (final item in data) {
      final exercisesData = (item['workout_exercises'] as List<dynamic>?) ?? [];
      exercisesData.sort((a, b) =>
          ((a['exercise_order'] as num?) ?? 0).compareTo((b['exercise_order'] as num?) ?? 0));

      final exercises = exercisesData.map((exJson) {
        final setsData = (exJson['workout_sets'] as List<dynamic>?) ?? [];
        setsData.sort((a, b) =>
            ((a['set_number'] as num?) ?? 0).compareTo((b['set_number'] as num?) ?? 0));

        final sets = setsData.map((sJson) {
          return WorkoutSet(
            setNumber: (sJson['set_number'] as num?)?.toInt() ?? 1,
            weight: (sJson['weight'] as num?)?.toDouble() ?? 0.0,
            reps: (sJson['reps'] as num?)?.toInt() ?? 0,
            isCompleted: sJson['is_completed'] as bool? ?? true,
          );
        }).toList();

        return Exercise(
          name: exJson['exercise_name'] as String? ?? 'Exercise',
          sets: sets,
        );
      }).toList();

      workouts.add(
        Workout(
          id: item['id'] as String,
          userId: item['user_id'] as String,
          title: item['title'] as String? ?? 'Workout Session',
          date: DateTime.tryParse(item['workout_date'] as String? ?? '') ?? DateTime.now(),
          durationMinutes: (item['duration_minutes'] as num?)?.toInt() ?? 45,
          exercises: exercises,
          notes: item['notes'] as String?,
        ),
      );
    }

    _cache = workouts;
    return workouts;
  }

  @override
  Future<void> saveWorkout(Workout workout) async {
    if (!SupabaseConfig.isConfigured) return;

    final client = Supabase.instance.client;

    // 1. Upsert Workout
    await client.from('workouts').upsert({
      'id': workout.id,
      'user_id': workout.userId,
      'title': workout.title,
      'workout_date': workout.date.toIso8601String(),
      'duration_minutes': workout.durationMinutes,
      'notes': workout.notes,
    });

    // 2. Clean previous exercises if updating
    await client.from('workout_exercises').delete().eq('workout_id', workout.id);

    // 3. Insert Exercises and Sets
    for (int i = 0; i < workout.exercises.length; i++) {
      final ex = workout.exercises[i];
      final exId = const Uuid().v4();

      await client.from('workout_exercises').insert({
        'id': exId,
        'workout_id': workout.id,
        'exercise_name': ex.name,
        'exercise_order': i,
      });

      if (ex.sets.isNotEmpty) {
        final setsToInsert = ex.sets.map((s) => {
          'workout_exercise_id': exId,
          'set_number': s.setNumber,
          'weight': s.weight,
          'reps': s.reps,
          'is_completed': s.isCompleted,
        }).toList();

        await client.from('workout_sets').insert(setsToInsert);
      }

      // 4. Update Personal Records (PRs)
      if (ex.maxWeight > 0) {
        final existingPR = await client
            .from('personal_records')
            .select()
            .eq('user_id', workout.userId)
            .eq('exercise_name', ex.name)
            .maybeSingle();

        final currentMax = (existingPR?['max_weight'] as num?)?.toDouble() ?? 0.0;
        if (existingPR == null || ex.maxWeight > currentMax) {
          await client.from('personal_records').upsert({
            'user_id': workout.userId,
            'exercise_name': ex.name,
            'max_weight': ex.maxWeight,
            'max_reps': ex.sets.isNotEmpty ? ex.sets.first.reps : 0,
            'achieved_at': workout.date.toIso8601String(),
            'workout_id': workout.id,
          }, onConflict: 'user_id,exercise_name');
        }
      }
    }

    _cache.removeWhere((w) => w.id == workout.id);
    _cache.insert(0, workout);
    _controller.add(List.unmodifiable(_cache));
  }

  @override
  Future<void> deleteWorkout(String workoutId) async {
    if (!SupabaseConfig.isConfigured) return;

    final client = Supabase.instance.client;
    await client.from('workouts').delete().eq('id', workoutId);

    _cache.removeWhere((w) => w.id == workoutId);
    _controller.add(List.unmodifiable(_cache));
  }

  @override
  Future<Map<String, double>> getPersonalRecords(String userId) async {
    if (!SupabaseConfig.isConfigured) return {};

    final client = Supabase.instance.client;
    final res = await client
        .from('personal_records')
        .select('exercise_name, max_weight')
        .eq('user_id', userId);

    final map = <String, double>{};
    for (final row in res as List<dynamic>) {
      final name = row['exercise_name'] as String;
      final weight = (row['max_weight'] as num).toDouble();
      map[name] = weight;
    }
    return map;
  }
}

// Global Riverpod Providers
final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  return SupabaseWorkoutRepository();
});

final workoutsStreamProvider = StreamProvider.family<List<Workout>, String>((ref, userId) {
  final repo = ref.watch(workoutRepositoryProvider);
  return repo.getWorkoutsStream(userId);
});

final personalRecordsProvider = FutureProvider.family<Map<String, double>, String>((ref, userId) async {
  final repo = ref.watch(workoutRepositoryProvider);
  return repo.getPersonalRecords(userId);
});
