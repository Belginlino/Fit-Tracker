import 'dart:async';
import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fittrack/core/appwrite/appwrite_client.dart';
import 'package:fittrack/core/appwrite/appwrite_config.dart';
import '../domain/user_model.dart';

abstract class AuthRepository {
  Stream<UserProfile?> authStateChanges();
  UserProfile? get currentUser;
  Future<UserProfile> signInWithEmail(String email, String password);
  Future<UserProfile> registerWithEmail(
      String email, String password, String name);
  Future<void> sendPasswordReset(String email);
  Future<void> updateProfile(UserProfile profile);
  Future<void> signOut();
  Future<void> deleteAccount();
}

/// Appwrite Auth & Profiles Repository
class AppwriteAuthRepository implements AuthRepository {
  final _controller = StreamController<UserProfile?>.broadcast();
  UserProfile? _currentUser;

  AppwriteAuthRepository() {
    _init();
  }

  void _init() async {
    if (!AppwriteConfig.isConfigured) {
      _controller.add(null);
      return;
    }

    try {
      final user = await AppwriteClient.instance.account.get();
      await _fetchProfile(user.$id, user.email, name: user.name);
    } catch (_) {
      _currentUser = null;
      _controller.add(null);
    }
  }

  Future<void> _fetchProfile(String userId, String? email, {String? name}) async {
    try {
      final doc = await AppwriteClient.instance.databases.getDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.profilesCollection,
        documentId: userId,
      );

      final map = Map<String, dynamic>.from(doc.data);
      map['email'] = email ?? '';
      _currentUser = UserProfile.fromMap(map, userId);
      _controller.add(_currentUser);
    } on AppwriteException catch (e) {
      if (e.code == 404) {
        // Document does not exist yet; create default profile
        final defaultProfile = UserProfile(
          id: userId,
          email: email ?? '',
          name: (name != null && name.isNotEmpty)
              ? name
              : (email?.split('@').first ?? 'Athlete'),
          createdAt: DateTime.now(),
        );
        await _createProfileDoc(defaultProfile);
        _currentUser = defaultProfile;
        _controller.add(_currentUser);
      } else {
        _currentUser = UserProfile(
          id: userId,
          email: email ?? '',
          name: (name != null && name.isNotEmpty)
              ? name
              : (email?.split('@').first ?? 'Athlete'),
          createdAt: DateTime.now(),
        );
        _controller.add(_currentUser);
      }
    } catch (_) {
      _currentUser = UserProfile(
        id: userId,
        email: email ?? '',
        name: (name != null && name.isNotEmpty)
            ? name
            : (email?.split('@').first ?? 'Athlete'),
        createdAt: DateTime.now(),
      );
      _controller.add(_currentUser);
    }
  }

  Future<void> _createProfileDoc(UserProfile profile) async {
    try {
      String formattedTime = profile.reminderTime;
      if (formattedTime.length == 5) {
        formattedTime = '$formattedTime:00';
      }

      await AppwriteClient.instance.databases.createDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.profilesCollection,
        documentId: profile.id,
        data: {
          'name': profile.name,
          'goal': profile.goal,
          'height': profile.height,
          'current_weight': profile.currentWeight,
          'target_weight': profile.targetWeight,
          'preferred_reminder_time': formattedTime,
          'workout_streak': profile.workoutStreak,
          'photo_streak': profile.photoStreak,
          'has_completed_onboarding': profile.hasCompletedOnboarding,
        },
        permissions: [
          Permission.read(Role.user(profile.id)),
          Permission.update(Role.user(profile.id)),
          Permission.delete(Role.user(profile.id)),
        ],
      );
    } catch (_) {
      // Ignored for offline or if collection has different schema
    }
  }

  @override
  Stream<UserProfile?> authStateChanges() => _controller.stream;

  @override
  UserProfile? get currentUser => _currentUser;

  @override
  Future<UserProfile> signInWithEmail(String email, String password) async {
    try {
      try {
        await AppwriteClient.instance.account.createEmailPasswordSession(
          email: email.trim(),
          password: password,
        );
      } on AppwriteException catch (e) {
        if (e.type == 'user_session_already_exists' ||
            (e.message?.toLowerCase().contains('session is active') ?? false)) {
          try {
            await AppwriteClient.instance.account.deleteSession(sessionId: 'current');
          } catch (_) {}
          await AppwriteClient.instance.account.createEmailPasswordSession(
            email: email.trim(),
            password: password,
          );
        } else {
          rethrow;
        }
      }

      final user = await AppwriteClient.instance.account.get();
      await _fetchProfile(user.$id, user.email, name: user.name);

      return _currentUser ??
          UserProfile(
            id: user.$id,
            email: user.email,
            name: user.name.isNotEmpty
                ? user.name
                : (user.email.split('@').first),
            createdAt: DateTime.now(),
          );
    } catch (e) {
      throw Exception(AppwriteClient.formatError(e));
    }
  }

  @override
  Future<UserProfile> registerWithEmail(
      String email, String password, String name) async {
    try {
      final user = await AppwriteClient.instance.account.create(
        userId: ID.unique(),
        email: email.trim(),
        password: password,
        name: name.trim(),
      );

      // Clear any prior session and log in to establish active session
      try {
        await AppwriteClient.instance.account.deleteSession(sessionId: 'current');
      } catch (_) {}

      await AppwriteClient.instance.account.createEmailPasswordSession(
        email: email.trim(),
        password: password,
      );

      final newProfile = UserProfile(
        id: user.$id,
        email: user.email,
        name: name.trim(),
        hasCompletedOnboarding: false,
        createdAt: DateTime.now(),
      );

      await _createProfileDoc(newProfile);
      _currentUser = newProfile;
      _controller.add(_currentUser);

      return newProfile;
    } catch (e) {
      throw Exception(AppwriteClient.formatError(e));
    }
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    try {
      await AppwriteClient.instance.account.createRecovery(
        email: email.trim(),
        url: '${AppwriteConfig.endpoint}/recovery',
      );
    } catch (e) {
      throw Exception(AppwriteClient.formatError(e));
    }
  }

  @override
  Future<void> updateProfile(UserProfile profile) async {
    _currentUser = profile;
    _controller.add(_currentUser);

    if (!AppwriteConfig.isConfigured) return;

    try {
      String formattedTime = profile.reminderTime;
      if (formattedTime.length == 5) {
        formattedTime = '$formattedTime:00';
      }

      final data = {
        'name': profile.name,
        'goal': profile.goal,
        'height': profile.height,
        'current_weight': profile.currentWeight,
        'target_weight': profile.targetWeight,
        'preferred_reminder_time': formattedTime,
        'workout_streak': profile.workoutStreak,
        'photo_streak': profile.photoStreak,
        'has_completed_onboarding': profile.hasCompletedOnboarding,
      };

      try {
        await AppwriteClient.instance.databases.updateDocument(
          databaseId: AppwriteConfig.databaseId,
          collectionId: AppwriteConfig.profilesCollection,
          documentId: profile.id,
          data: data,
        );
      } on AppwriteException catch (e) {
        if (e.code == 404) {
          await AppwriteClient.instance.databases.createDocument(
            databaseId: AppwriteConfig.databaseId,
            collectionId: AppwriteConfig.profilesCollection,
            documentId: profile.id,
            data: data,
            permissions: [
              Permission.read(Role.user(profile.id)),
              Permission.update(Role.user(profile.id)),
              Permission.delete(Role.user(profile.id)),
            ],
          );
        }
      }
    } catch (_) {
      // Remote sync error caught; local state is preserved
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await AppwriteClient.instance.account.deleteSession(sessionId: 'current');
    } catch (_) {}
    _currentUser = null;
    _controller.add(null);
  }

  @override
  Future<void> deleteAccount() async {
    if (_currentUser != null) {
      try {
        await AppwriteClient.instance.databases.deleteDocument(
          databaseId: AppwriteConfig.databaseId,
          collectionId: AppwriteConfig.profilesCollection,
          documentId: _currentUser!.id,
        );
      } catch (_) {}
    }
    await signOut();
  }

  void dispose() {
    _controller.close();
  }
}

// Global Riverpod Providers
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AppwriteAuthRepository();
});

final authStateChangesProvider = StreamProvider<UserProfile?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authStateChanges();
});

final currentUserProfileProvider = StateProvider<UserProfile?>((ref) {
  final authState = ref.watch(authStateChangesProvider).value;
  return authState;
});
