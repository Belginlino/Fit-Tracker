import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fittrack/core/network/api_client.dart';
import 'package:fittrack/core/network/api_endpoints.dart';
import '../domain/workout.dart';

abstract class WorkoutRepository {
  Stream<List<Workout>> getWorkoutsStream(String userId);
  Future<List<Workout>> getWorkouts(String userId);
  Future<void> saveWorkout(Workout workout);
  Future<void> deleteWorkout(String workoutId);
  Future<Map<String, double>> getPersonalRecords(String userId);
}

/// Cloudflare Workers & D1 implementation
class CloudflareWorkoutRepository implements WorkoutRepository {
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
      _controller.add(_cache);
    } catch (_) {
      _controller.add(_cache);
    }
  }

  @override
  Future<List<Workout>> getWorkouts(String userId) async {
    final data = await ApiClient.instance.get(ApiEndpoints.workouts);
    if (data is List) {
      return data.map((json) => Workout.fromMap(json, json['id'])).toList();
    }
    return [];
  }

  @override
  Future<void> saveWorkout(Workout workout) async {
    final data = await ApiClient.instance.post(ApiEndpoints.workouts, body: workout.toMap());
    final created = Workout.fromMap(data, data['id'] ?? workout.id);
    _cache.insert(0, created);
    _controller.add(List.unmodifiable(_cache));
  }

  @override
  Future<void> deleteWorkout(String workoutId) async {
    await ApiClient.instance.delete('${ApiEndpoints.workouts}/$workoutId');
    _cache.removeWhere((w) => w.id == workoutId);
    _controller.add(List.unmodifiable(_cache));
  }

  @override
  Future<Map<String, double>> getPersonalRecords(String userId) async {
    final data = await ApiClient.instance.get(ApiEndpoints.analyticsDashboard);
    if (data != null && data['personalRecords'] is Map) {
      final map = data['personalRecords'] as Map<String, dynamic>;
      return map.map((key, value) => MapEntry(key, (value as num).toDouble()));
    }
    return {};
  }
}

/// Local mock repository for demo and offline fallback
class LocalMockWorkoutRepository implements WorkoutRepository {
  final _controller = StreamController<List<Workout>>.broadcast();

  final List<Workout> _workouts = [
    Workout(
      id: 'workout-1',
      userId: 'demo-user-101',
      title: 'Chest + Triceps',
      date: DateTime.now().subtract(const Duration(days: 1)),
      durationMinutes: 52,
      notes: 'Hit new PR on bench press! Felt smooth.',
      exercises: const [
        Exercise(
          name: 'Barbell Bench Press',
          sets: [
            WorkoutSet(setNumber: 1, weight: 60.0, reps: 10),
            WorkoutSet(setNumber: 2, weight: 65.0, reps: 8),
            WorkoutSet(setNumber: 3, weight: 70.0, reps: 6),
          ],
        ),
        Exercise(
          name: 'Incline Dumbbell Press',
          sets: [
            WorkoutSet(setNumber: 1, weight: 22.0, reps: 10),
            WorkoutSet(setNumber: 2, weight: 24.0, reps: 8),
          ],
        ),
        Exercise(
          name: 'Tricep Rope Pushdown',
          sets: [
            WorkoutSet(setNumber: 1, weight: 25.0, reps: 12),
            WorkoutSet(setNumber: 2, weight: 27.5, reps: 10),
          ],
        ),
      ],
    ),
    Workout(
      id: 'workout-2',
      userId: 'demo-user-101',
      title: 'Back + Biceps',
      date: DateTime.now().subtract(const Duration(days: 3)),
      durationMinutes: 48,
      exercises: const [
        Exercise(
          name: 'Lat Pulldown',
          sets: [
            WorkoutSet(setNumber: 1, weight: 55.0, reps: 12),
            WorkoutSet(setNumber: 2, weight: 60.0, reps: 10),
            WorkoutSet(setNumber: 3, weight: 65.0, reps: 8),
          ],
        ),
        Exercise(
          name: 'Barbell Bent-Over Row',
          sets: [
            WorkoutSet(setNumber: 1, weight: 50.0, reps: 10),
            WorkoutSet(setNumber: 2, weight: 55.0, reps: 8),
          ],
        ),
        Exercise(
          name: 'Incline Dumbbell Curl',
          sets: [
            WorkoutSet(setNumber: 1, weight: 14.0, reps: 12),
            WorkoutSet(setNumber: 2, weight: 14.0, reps: 10),
          ],
        ),
      ],
    ),
  ];

  LocalMockWorkoutRepository() {
    Future.microtask(() => _controller.add(_workouts));
  }

  @override
  Stream<List<Workout>> getWorkoutsStream(String userId) => _controller.stream;

  @override
  Future<List<Workout>> getWorkouts(String userId) async => List.unmodifiable(_workouts);

  @override
  Future<void> saveWorkout(Workout workout) async {
    _workouts.insert(0, workout);
    _controller.add(List.unmodifiable(_workouts));
  }

  @override
  Future<void> deleteWorkout(String workoutId) async {
    _workouts.removeWhere((w) => w.id == workoutId);
    _controller.add(List.unmodifiable(_workouts));
  }

  @override
  Future<Map<String, double>> getPersonalRecords(String userId) async {
    final prs = <String, double>{};
    for (final w in _workouts) {
      for (final ex in w.exercises) {
        final currentPr = prs[ex.name] ?? 0.0;
        final maxWeight = ex.maxWeight;
        if (maxWeight > currentPr) {
          prs[ex.name] = maxWeight;
        }
      }
    }
    return prs;
  }
}

// Riverpod Providers
final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  return LocalMockWorkoutRepository();
});

final workoutsStreamProvider = StreamProvider.family<List<Workout>, String>((ref, userId) {
  final repo = ref.watch(workoutRepositoryProvider);
  return repo.getWorkoutsStream(userId);
});

final personalRecordsProvider = FutureProvider.family<Map<String, double>, String>((ref, userId) {
  final repo = ref.watch(workoutRepositoryProvider);
  return repo.getPersonalRecords(userId);
});
