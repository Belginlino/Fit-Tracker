import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack/features/workouts/domain/workout.dart';

void main() {
  group('Workout & Exercise Domain Tests', () {
    test('calculates max weight correctly for an exercise', () {
      const exercise = Exercise(
        name: 'Bench Press',
        sets: [
          WorkoutSet(setNumber: 1, weight: 60.0, reps: 10),
          WorkoutSet(setNumber: 2, weight: 70.0, reps: 8),
          WorkoutSet(setNumber: 3, weight: 65.0, reps: 6),
        ],
      );

      expect(exercise.maxWeight, equals(70.0));
    });

    test('calculates total volume correctly for a workout', () {
      final workout = Workout(
        id: 'w-1',
        userId: 'u-1',
        title: 'Push Day',
        date: DateTime.now(),
        exercises: const [
          Exercise(
            name: 'Bench Press',
            sets: [
              WorkoutSet(setNumber: 1, weight: 50.0, reps: 10), // 500
              WorkoutSet(setNumber: 2, weight: 60.0, reps: 5), // 300
            ],
          ),
          Exercise(
            name: 'Pushdown',
            sets: [
              WorkoutSet(setNumber: 1, weight: 20.0, reps: 10), // 200
            ],
          ),
        ],
      );

      expect(workout.totalVolumeKg, equals(1000.0));
      expect(workout.totalSets, equals(3));
    });
  });
}
