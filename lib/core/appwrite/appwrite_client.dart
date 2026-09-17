import 'package:appwrite/appwrite.dart';
import 'appwrite_config.dart';

/// Singleton manager for Appwrite client and service instances
class AppwriteClient {
  AppwriteClient._();
  static final AppwriteClient instance = AppwriteClient._();

  late final Client client;
  late final Account account;
  late final Databases databases;
  late final Storage storage;
  late final Realtime realtime;

  bool _initialized = false;
  bool get isInitialized => _initialized;

  void init() {
    if (_initialized) return;

    client = Client()
        .setEndpoint(AppwriteConfig.endpoint)
        .setProject(AppwriteConfig.projectId)
        .setSelfSigned(status: true);

    account = Account(client);
    databases = Databases(client);
    storage = Storage(client);
    realtime = Realtime(client);

    _initialized = true;
  }

  /// Construct a direct view/download URL for an Appwrite Storage file
  String getFileViewUrl(String fileId, {String? bucketId}) {
    final bId = bucketId ?? AppwriteConfig.photosBucket;
    return '${AppwriteConfig.endpoint}/storage/buckets/$bId/files/$fileId/view?project=${AppwriteConfig.projectId}';
  }

  /// Construct a preview URL with width/height for thumbnails
  String getFilePreviewUrl(String fileId, {int width = 400, int height = 400, String? bucketId}) {
    final bId = bucketId ?? AppwriteConfig.photosBucket;
    return '${AppwriteConfig.endpoint}/storage/buckets/$bId/files/$fileId/preview?project=${AppwriteConfig.projectId}&width=$width&height=$height';
  }

  /// Format Appwrite errors into user-friendly readable messages
  static String formatError(dynamic error) {
    if (error is AppwriteException) {
      final msg = (error.message ?? '').toLowerCase();
      final code = error.code ?? 0;

      if (code == 401 || msg.contains('invalid credentials') || msg.contains('user not found')) {
        return 'Invalid email or password. Please try again.';
      } else if (code == 409 || msg.contains('already exists')) {
        return 'An account with this email address already exists.';
      } else if (code == 429 || msg.contains('rate limit')) {
        return 'Too many requests. Please wait a moment and try again.';
      } else if (code == 403 || msg.contains('permission denied') || msg.contains('not authorized')) {
        return 'Access denied. You do not have permission to perform this action.';
      } else if (code == 404 || msg.contains('not found')) {
        return 'The requested resource was not found.';
      } else if (msg.contains('network') || msg.contains('socket') || msg.contains('failed host lookup')) {
        return 'Network error. Please check your internet connection.';
      }
      return error.message ?? 'An unexpected Appwrite error occurred ($code).';
    }
    return error.toString();
  }
}
