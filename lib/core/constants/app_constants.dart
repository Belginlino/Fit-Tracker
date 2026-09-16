class AppConstants {
  AppConstants._();

  static const String appName = 'FitTrack';
  static const String appTagline = 'Transform with consistency';

  // Cloudflare D1 Database Table Names
  static const String usersTable = 'users';
  static const String progressPhotosTable = 'progress_photos';
  static const String workoutsTable = 'workouts';
  static const String setsTable = 'workout_sets';
  static const String templatesTable = 'workout_templates';
  static const String measurementsTable = 'measurements';

  // Supported Poses
  static const List<String> photoPoses = ['Front', 'Side', 'Back', 'Free'];

  // Default Workout Templates
  static const List<String> defaultTemplates = [
    'Push',
    'Pull',
    'Legs',
    'Upper Body',
    'Lower Body',
    'Chest + Triceps',
    'Back + Biceps',
  ];

  // Body Measurement Types
  static const List<String> measurementTypes = [
    'Weight',
    'Chest',
    'Waist',
    'Hips',
    'Left Arm',
    'Right Arm',
    'Left Thigh',
    'Right Thigh',
    'Shoulders',
    'Body Fat %',
  ];
}
