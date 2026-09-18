import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack/features/auth/domain/user_model.dart';
import 'package:fittrack/features/measurements/domain/measurement.dart';
import 'package:fittrack/features/progress_photos/domain/progress_photo.dart';
import 'package:fittrack/features/workouts/domain/workout.dart';

void main() {
  group('Model Serialization & Null-Safety Tests', () {
    test('BodyMeasurement.fromMap handles missing and numeric variations safely', () {
      final mapWithNulls = <String, dynamic>{
        'value': null,
        'type': null,
        'unit': null,
        'recordedAt': null,
      };

      final bm = BodyMeasurement.fromMap(mapWithNulls, 'bm-test-1');
      expect(bm.id, equals('bm-test-1'));
      expect(bm.value, equals(0.0));
      expect(bm.type, equals('Weight'));
      expect(bm.unit, equals('kg'));
      expect(bm.recordedAt, isNotNull);

      // Integer value safely converted to double
      final mapWithInt = <String, dynamic>{
        'value': 80,
        'type': 'Chest',
      };
      final bm2 = BodyMeasurement.fromMap(mapWithInt, 'bm-test-2');
      expect(bm2.value, equals(80.0));
      expect(bm2.type, equals('Chest'));
    });

    test('WorkoutSet and Exercise fromMap handle missing and null fields', () {
      final setMap = <String, dynamic>{
        'setNumber': 2,
        'weight': 62.5,
        'reps': 8,
      };
      final setObj = WorkoutSet.fromMap(setMap);
      expect(setObj.setNumber, equals(2));
      expect(setObj.weight, equals(62.5));
      expect(setObj.reps, equals(8));
      expect(setObj.isCompleted, isTrue);

      final exMap = <String, dynamic>{
        'name': 'Barbell Squat',
        'sets': [setMap],
      };
      final ex = Exercise.fromMap(exMap);
      expect(ex.name, equals('Barbell Squat'));
      expect(ex.sets.length, equals(1));
      expect(ex.maxWeight, equals(62.5));
      expect(ex.totalVolume, equals(500.0));
    });

    test('Workout.fromMap handles empty exercises and missing dates', () {
      final workoutMap = <String, dynamic>{
        'title': 'Leg Day',
        'durationMinutes': 60,
      };
      final w = Workout.fromMap(workoutMap, 'w-101');
      expect(w.id, equals('w-101'));
      expect(w.title, equals('Leg Day'));
      expect(w.durationMinutes, equals(60));
      expect(w.exercises, isEmpty);
      expect(w.totalVolumeKg, equals(0.0));
    });

    test('UserProfile.fromMap safely parses stringified or list days', () {
      final userMap = <String, dynamic>{
        'name': 'Athlete One',
        'current_weight': 75,
        'height': 180,
        'preferred_workout_days': 'Mon, Wed, Fri',
        'workout_streak': 5,
        'has_completed_onboarding': true,
      };

      final profile = UserProfile.fromMap(userMap, 'user-1');
      expect(profile.id, equals('user-1'));
      expect(profile.name, equals('Athlete One'));
      expect(profile.currentWeight, equals(75.0));
      expect(profile.height, equals(180.0));
      expect(profile.workoutStreak, equals(5));
      expect(profile.hasCompletedOnboarding, isTrue);
      expect(profile.preferredWorkoutDays, contains('Mon'));
    });

    test('ProgressPhoto.fromMap parses day number from note or explicit field', () {
      final photoMap = <String, dynamic>{
        'user_id': 'u1',
        'file_id': 'file-123',
        'notes': '[Day 45] Halfway through 90-day cut',
        'pose': 'Side',
      };
      final photo = ProgressPhoto.fromMap(photoMap, 'p-45');
      expect(photo.effectiveDayNumber, equals(45));
      expect(photo.pose, equals('Side'));
      expect(photo.cleanNotes, equals('Halfway through 90-day cut'));
    });
  });
}
