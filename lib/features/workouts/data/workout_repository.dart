import 'dart:async';
import 'dart:convert';
import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:fittrack/core/appwrite/appwrite_client.dart';
import 'package:fittrack/core/appwrite/appwrite_config.dart';
import '../domain/workout.dart';

abstract class WorkoutRepository {
  Stream<List<Workout>> getWorkoutsStream(String userId);
  Future<List<Workout>> getWorkouts(String userId);
  Future<void> saveWorkout(Workout workout);
  Future<void> deleteWorkout(String workoutId);
  Future<Map<String, double>> getPersonalRecords(String userId);
}

/// Appwrite Database implementation for Workouts, Exercises, Sets, and PRs with local persistence
class AppwriteWorkoutRepository implements WorkoutRepository {
  final _controller = StreamController<List<Workout>>.broadcast();
  List<Workout> _cache = [];
  final Set<String> _loadedUsers = {};

  @override
  Stream<List<Workout>> getWorkoutsStream(String userId) async* {
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
      final key = 'fittrack_workouts_${userId.isEmpty ? "default" : userId}';
      final raw = prefs.getString(key);
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> list = jsonDecode(raw);
        final loaded = list
            .map((item) => Workout.fromMap(
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
      final key = 'fittrack_workouts_${userId.isEmpty ? "default" : userId}';
      final raw = jsonEncode(_cache.map((w) => w.toMap()).toList());
      await prefs.setString(key, raw);
    } catch (_) {}
  }

  Future<void> _fetchAndEmit(String userId) async {
    try {
      final workouts = await getWorkouts(userId);
      _cache = workouts;
      _controller.add(List.unmodifiable(_cache));
      await _saveToLocal(userId);
    } catch (_) {
      _controller.add(List.unmodifiable(_cache));
    }
  }

  @override
  Future<List<Workout>> getWorkouts(String userId) async {
    if (!AppwriteConfig.isConfigured || userId.isEmpty || userId == 'user-local') {
      return _cache;
    }

    try {
      final db = AppwriteClient.instance.databases;
      final response = await db.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.workoutsCollection,
        queries: [
          Query.equal('user_id', userId),
          Query.orderDesc('workout_date'),
          Query.limit(50),
        ],
      );

      if (response.documents.isEmpty) {
        return _cache;
      }

      // Batch query exercises and sets for the user (3 requests instead of 1 + 2*N)
      final exDocs = await db.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.workoutExercisesCollection,
        queries: [
          Query.equal('user_id', userId),
          Query.orderAsc('exercise_order'),
          Query.limit(200),
        ],
      );

      final setsDocs = await db.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.workoutSetsCollection,
        queries: [
          Query.equal('user_id', userId),
          Query.orderAsc('set_number'),
          Query.limit(500),
        ],
      );

      // Group sets by workout_exercise_id
      final setsByExId = <String, List<WorkoutSet>>{};
      for (final sDoc in setsDocs.documents) {
        final exId = sDoc.data['workout_exercise_id'] as String? ?? '';
        final s = WorkoutSet(
          setNumber: (sDoc.data['set_number'] as num?)?.toInt() ?? 1,
          weight: (sDoc.data['weight'] as num?)?.toDouble() ?? 0.0,
          reps: (sDoc.data['reps'] as num?)?.toInt() ?? 0,
          isCompleted: sDoc.data['is_completed'] as bool? ?? true,
        );
        setsByExId.putIfAbsent(exId, () => []).add(s);
      }

      // Group exercises by workout_id
      final exercisesByWorkoutId = <String, List<Exercise>>{};
      for (final eDoc in exDocs.documents) {
        final wId = eDoc.data['workout_id'] as String? ?? '';
        final ex = Exercise(
          name: eDoc.data['exercise_name'] as String? ?? 'Exercise',
          sets: setsByExId[eDoc.$id] ?? [],
        );
        exercisesByWorkoutId.putIfAbsent(wId, () => []).add(ex);
      }

      final workouts = <Workout>[];
      for (final doc in response.documents) {
        final workoutId = doc.$id;
        final data = doc.data;
        workouts.add(
          Workout(
            id: workoutId,
            userId: data['user_id'] as String? ?? userId,
            title: data['title'] as String? ?? 'Workout Session',
            date: DateTime.tryParse(data['workout_date'] as String? ?? '') ??
                DateTime.now(),
            durationMinutes:
                (data['duration_minutes'] as num?)?.toInt() ?? 45,
            exercises: exercisesByWorkoutId[workoutId] ?? [],
            notes: data['notes'] as String?,
          ),
        );
      }

      _cache = workouts;
      await _saveToLocal(userId);
      return workouts;
    } catch (_) {
      return _cache;
    }
  }

  @override
  Future<void> saveWorkout(Workout workout) async {
    _cache.removeWhere((w) => w.id == workout.id);
    _cache.insert(0, workout);
    _controller.add(List.unmodifiable(_cache));
    await _saveToLocal(workout.userId);

    if (!AppwriteConfig.isConfigured) return;

    try {
      final db = AppwriteClient.instance.databases;
      final permissions = [
        Permission.read(Role.user(workout.userId)),
        Permission.update(Role.user(workout.userId)),
        Permission.delete(Role.user(workout.userId)),
      ];

      final workoutData = {
        'user_id': workout.userId,
        'title': workout.title,
        'workout_date': workout.date.toIso8601String(),
        'duration_minutes': workout.durationMinutes,
        'notes': workout.notes ?? '',
      };

      // 1. Create or update Workout document
      try {
        await db.updateDocument(
          databaseId: AppwriteConfig.databaseId,
          collectionId: AppwriteConfig.workoutsCollection,
          documentId: workout.id,
          data: workoutData,
        );
      } on AppwriteException catch (e) {
        if (e.code == 404) {
          await db.createDocument(
            databaseId: AppwriteConfig.databaseId,
            collectionId: AppwriteConfig.workoutsCollection,
            documentId: workout.id,
            data: workoutData,
            permissions: permissions,
          );
        }
      }

      // 2. Clean previous exercises and sets if updating
      try {
        final existingExercises = await db.listDocuments(
          databaseId: AppwriteConfig.databaseId,
          collectionId: AppwriteConfig.workoutExercisesCollection,
          queries: [Query.equal('workout_id', workout.id)],
        );
        for (final exDoc in existingExercises.documents) {
          await db.deleteDocument(
            databaseId: AppwriteConfig.databaseId,
            collectionId: AppwriteConfig.workoutExercisesCollection,
            documentId: exDoc.$id,
          );
        }

        final existingSets = await db.listDocuments(
          databaseId: AppwriteConfig.databaseId,
          collectionId: AppwriteConfig.workoutSetsCollection,
          queries: [Query.equal('workout_id', workout.id)],
        );
        for (final sDoc in existingSets.documents) {
          await db.deleteDocument(
            databaseId: AppwriteConfig.databaseId,
            collectionId: AppwriteConfig.workoutSetsCollection,
            documentId: sDoc.$id,
          );
        }
      } catch (_) {}

      // 3. Insert Exercises and Sets
      for (int i = 0; i < workout.exercises.length; i++) {
        final ex = workout.exercises[i];
        final exId = const Uuid().v4().replaceAll('-', '').substring(0, 20);

        await db.createDocument(
          databaseId: AppwriteConfig.databaseId,
          collectionId: AppwriteConfig.workoutExercisesCollection,
          documentId: exId,
          data: {
            'workout_id': workout.id,
            'user_id': workout.userId,
            'exercise_name': ex.name,
            'exercise_order': i,
          },
          permissions: permissions,
        );

        for (final s in ex.sets) {
          final setId = ID.unique();
          await db.createDocument(
            databaseId: AppwriteConfig.databaseId,
            collectionId: AppwriteConfig.workoutSetsCollection,
            documentId: setId,
            data: {
              'workout_id': workout.id,
              'workout_exercise_id': exId,
              'user_id': workout.userId,
              'set_number': s.setNumber,
              'weight': s.weight,
              'reps': s.reps,
              'is_completed': s.isCompleted,
            },
            permissions: permissions,
          );
        }

        // 4. Update Personal Records (PRs)
        if (ex.maxWeight > 0) {
          try {
            final prList = await db.listDocuments(
              databaseId: AppwriteConfig.databaseId,
              collectionId: AppwriteConfig.personalRecordsCollection,
              queries: [
                Query.equal('user_id', workout.userId),
                Query.equal('exercise_name', ex.name),
                Query.limit(1),
              ],
            );

            if (prList.documents.isEmpty) {
              await db.createDocument(
                databaseId: AppwriteConfig.databaseId,
                collectionId: AppwriteConfig.personalRecordsCollection,
                documentId: ID.unique(),
                data: {
                  'user_id': workout.userId,
                  'exercise_name': ex.name,
                  'max_weight': ex.maxWeight,
                  'max_reps': ex.sets.isNotEmpty ? ex.sets.first.reps : 0,
                  'achieved_at': workout.date.toIso8601String(),
                  'workout_id': workout.id,
                },
                permissions: permissions,
              );
            } else {
              final prDoc = prList.documents.first;
              final currentMax = (prDoc.data['max_weight'] as num?)?.toDouble() ?? 0.0;
              if (ex.maxWeight > currentMax) {
                await db.updateDocument(
                  databaseId: AppwriteConfig.databaseId,
                  collectionId: AppwriteConfig.personalRecordsCollection,
                  documentId: prDoc.$id,
                  data: {
                    'max_weight': ex.maxWeight,
                    'max_reps': ex.sets.isNotEmpty ? ex.sets.first.reps : 0,
                    'achieved_at': workout.date.toIso8601String(),
                    'workout_id': workout.id,
                  },
                );
              }
            }
          } catch (_) {}
        }
      }
    } catch (_) {
      // Remote sync error caught; local workout session is saved and active
    }
  }

  @override
  Future<void> deleteWorkout(String workoutId) async {
    final uid = _cache.isNotEmpty ? _cache.first.userId : '';
    _cache.removeWhere((w) => w.id == workoutId);
    _controller.add(List.unmodifiable(_cache));
    if (uid.isNotEmpty) {
      await _saveToLocal(uid);
    }

    if (!AppwriteConfig.isConfigured) return;

    try {
      final db = AppwriteClient.instance.databases;
      await db.deleteDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.workoutsCollection,
        documentId: workoutId,
      );

      // Clean exercises and sets
      final exDocs = await db.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.workoutExercisesCollection,
        queries: [Query.equal('workout_id', workoutId)],
      );
      for (final exDoc in exDocs.documents) {
        await db.deleteDocument(
          databaseId: AppwriteConfig.databaseId,
          collectionId: AppwriteConfig.workoutExercisesCollection,
          documentId: exDoc.$id,
        );
      }

      final setsDocs = await db.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.workoutSetsCollection,
        queries: [Query.equal('workout_id', workoutId)],
      );
      for (final sDoc in setsDocs.documents) {
        await db.deleteDocument(
          databaseId: AppwriteConfig.databaseId,
          collectionId: AppwriteConfig.workoutSetsCollection,
          documentId: sDoc.$id,
        );
      }
    } catch (_) {}
  }

  @override
  Future<Map<String, double>> getPersonalRecords(String userId) async {
    if (!AppwriteConfig.isConfigured) return {};

    try {
      final db = AppwriteClient.instance.databases;
      final res = await db.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.personalRecordsCollection,
        queries: [
          Query.equal('user_id', userId),
          Query.limit(100),
        ],
      );

      final map = <String, double>{};
      for (final doc in res.documents) {
        final name = doc.data['exercise_name'] as String? ?? '';
        final weight = (doc.data['max_weight'] as num?)?.toDouble() ?? 0.0;
        if (name.isNotEmpty) {
          map[name] = weight;
        }
      }
      return map;
    } catch (_) {
      return {};
    }
  }
}

// Global Riverpod Providers
final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  return AppwriteWorkoutRepository();
});

final workoutsStreamProvider =
    StreamProvider.family<List<Workout>, String>((ref, userId) {
  final repo = ref.watch(workoutRepositoryProvider);
  return repo.getWorkoutsStream(userId);
});

final personalRecordsProvider =
    FutureProvider.family<Map<String, double>, String>((ref, userId) async {
  final repo = ref.watch(workoutRepositoryProvider);
  return repo.getPersonalRecords(userId);
});
