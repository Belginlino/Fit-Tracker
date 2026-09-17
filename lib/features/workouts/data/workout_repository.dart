import 'dart:async';
import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

/// Appwrite Database implementation for Workouts, Exercises, Sets, and PRs
class AppwriteWorkoutRepository implements WorkoutRepository {
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
    if (!AppwriteConfig.isConfigured) return [];

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

      final workouts = <Workout>[];

      for (final doc in response.documents) {
        final workoutId = doc.$id;
        final data = doc.data;

        // Fetch exercises for this workout
        List<Exercise> exercises = [];
        try {
          final exDocs = await db.listDocuments(
            databaseId: AppwriteConfig.databaseId,
            collectionId: AppwriteConfig.workoutExercisesCollection,
            queries: [
              Query.equal('workout_id', workoutId),
              Query.orderAsc('exercise_order'),
            ],
          );

          // Fetch all sets for this workout
          final setsDocs = await db.listDocuments(
            databaseId: AppwriteConfig.databaseId,
            collectionId: AppwriteConfig.workoutSetsCollection,
            queries: [
              Query.equal('workout_id', workoutId),
              Query.orderAsc('set_number'),
            ],
          );

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

          exercises = exDocs.documents.map((eDoc) {
            final exId = eDoc.$id;
            return Exercise(
              name: eDoc.data['exercise_name'] as String? ?? 'Exercise',
              sets: setsByExId[exId] ?? [],
            );
          }).toList();
        } catch (_) {}

        workouts.add(
          Workout(
            id: workoutId,
            userId: data['user_id'] as String? ?? userId,
            title: data['title'] as String? ?? 'Workout Session',
            date: DateTime.tryParse(data['workout_date'] as String? ?? '') ??
                DateTime.now(),
            durationMinutes:
                (data['duration_minutes'] as num?)?.toInt() ?? 45,
            exercises: exercises,
            notes: data['notes'] as String?,
          ),
        );
      }

      _cache = workouts;
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
    _cache.removeWhere((w) => w.id == workoutId);
    _controller.add(List.unmodifiable(_cache));

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
