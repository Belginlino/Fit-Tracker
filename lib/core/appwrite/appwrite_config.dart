class AppwriteConfig {
  AppwriteConfig._();

  /// Appwrite Project Endpoint
  static const String endpoint = String.fromEnvironment(
    'APPWRITE_ENDPOINT',
    defaultValue: 'https://sgp.cloud.appwrite.io/v1',
  );

  /// Appwrite Project ID
  static const String projectId = String.fromEnvironment(
    'APPWRITE_PROJECT_ID',
    defaultValue: '6aac02f1002c53d0bc56',
  );

  /// Appwrite Database ID
  static const String databaseId = String.fromEnvironment(
    'APPWRITE_DATABASE_ID',
    defaultValue: 'fittrack',
  );

  /// Appwrite Storage Bucket for Progress Photos
  static const String photosBucket = String.fromEnvironment(
    'APPWRITE_PHOTOS_BUCKET',
    defaultValue: 'progress-photos',
  );

  // Collection IDs
  static const String profilesCollection = 'profiles';
  static const String workoutsCollection = 'workouts';
  static const String workoutExercisesCollection = 'workout_exercises';
  static const String workoutSetsCollection = 'workout_sets';
  static const String personalRecordsCollection = 'personal_records';
  static const String measurementsCollection = 'measurements';
  static const String progressPhotosCollection = 'progress_photos';

  static bool get isConfigured =>
      endpoint.isNotEmpty &&
      projectId.isNotEmpty &&
      projectId != 'YOUR_PROJECT_ID_HERE';
}
