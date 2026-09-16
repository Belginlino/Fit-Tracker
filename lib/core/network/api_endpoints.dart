import 'package:flutter/foundation.dart';

class ApiEndpoints {
  ApiEndpoints._();

  // Local development default (Android Emulator uses 10.0.2.2, others use 127.0.0.1)
  static String get baseUrl {
    if (kIsWeb) return 'http://127.0.0.1:8787';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8787';
    }
    return 'http://127.0.0.1:8787';
  }

  // Auth
  static String get register => '$baseUrl/api/auth/register';
  static String get login => '$baseUrl/api/auth/login';
  static String get me => '$baseUrl/api/auth/me';
  static String get profile => '$baseUrl/api/auth/profile';
  static String get deleteAccount => '$baseUrl/api/auth/delete-account';

  // Photos
  static String get photos => '$baseUrl/api/photos';
  static String get photoUpload => '$baseUrl/api/photos/upload';
  static String photoContent(String id) => '$baseUrl/api/photos/$id/content';

  // Workouts
  static String get workouts => '$baseUrl/api/workouts';

  // Measurements
  static String get measurements => '$baseUrl/api/measurements';

  // Analytics
  static String get analyticsDashboard => '$baseUrl/api/analytics/dashboard';
}
