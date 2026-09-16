import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fittrack/core/network/api_client.dart';
import 'package:fittrack/core/network/api_endpoints.dart';
import '../domain/user_model.dart';

abstract class AuthRepository {
  Stream<UserProfile?> authStateChanges();
  UserProfile? get currentUser;
  Future<UserProfile> signInWithEmail(String email, String password);
  Future<UserProfile> registerWithEmail(String email, String password, String name);
  Future<void> sendPasswordReset(String email);
  Future<void> updateProfile(UserProfile profile);
  Future<void> signOut();
  Future<void> deleteAccount();
}

/// Cloudflare Workers Auth Repository
class CloudflareAuthRepository implements AuthRepository {
  final _controller = StreamController<UserProfile?>.broadcast();
  UserProfile? _currentUser;

  CloudflareAuthRepository() {
    _initSession();
  }

  Future<void> _initSession() async {
    await ApiClient.instance.init();
    if (ApiClient.instance.isAuthenticated) {
      try {
        final data = await ApiClient.instance.get(ApiEndpoints.me);
        if (data != null) {
          _currentUser = UserProfile.fromMap(data, data['id']);
          _controller.add(_currentUser);
          return;
        }
      } catch (_) {
        await ApiClient.instance.setToken(null);
      }
    }
    _controller.add(null);
  }

  @override
  Stream<UserProfile?> authStateChanges() => _controller.stream;

  @override
  UserProfile? get currentUser => _currentUser;

  @override
  Future<UserProfile> signInWithEmail(String email, String password) async {
    final data = await ApiClient.instance.post(ApiEndpoints.login, body: {
      'email': email,
      'password': password,
    });

    final token = data['token'] as String;
    final userMap = data['user'] as Map<String, dynamic>;

    await ApiClient.instance.setToken(token);
    _currentUser = UserProfile.fromMap(userMap, userMap['id']);
    _controller.add(_currentUser);
    return _currentUser!;
  }

  @override
  Future<UserProfile> registerWithEmail(String email, String password, String name) async {
    final data = await ApiClient.instance.post(ApiEndpoints.register, body: {
      'email': email,
      'password': password,
      'name': name,
    });

    final token = data['token'] as String;
    final userMap = data['user'] as Map<String, dynamic>;

    await ApiClient.instance.setToken(token);
    _currentUser = UserProfile.fromMap(userMap, userMap['id']);
    _controller.add(_currentUser);
    return _currentUser!;
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    await Future.delayed(const Duration(milliseconds: 300));
  }

  @override
  Future<void> updateProfile(UserProfile profile) async {
    await ApiClient.instance.patch(ApiEndpoints.profile, body: profile.toMap());
    _currentUser = profile;
    _controller.add(_currentUser);
  }

  @override
  Future<void> signOut() async {
    await ApiClient.instance.setToken(null);
    _currentUser = null;
    _controller.add(null);
  }

  @override
  Future<void> deleteAccount() async {
    await ApiClient.instance.delete(ApiEndpoints.deleteAccount);
    await ApiClient.instance.setToken(null);
    _currentUser = null;
    _controller.add(null);
  }
}

/// Robust in-memory mock repository for instant offline demo and local fallback
class LocalMockAuthRepository implements AuthRepository {
  final _controller = StreamController<UserProfile?>.broadcast();

  UserProfile? _currentUser = UserProfile(
    id: 'demo-user-101',
    email: 'athlete@fittrack.app',
    name: 'Belgin',
    goal: 'Build Muscle',
    currentWeight: 74.2,
    height: 178.0,
    targetWeight: 78.0,
    preferredWorkoutDays: const ['Mon', 'Tue', 'Wed', 'Fri', 'Sat'],
    reminderTime: '18:30',
    workoutStreak: 12,
    photoStreak: 8,
    hasCompletedOnboarding: true,
    createdAt: DateTime.now().subtract(const Duration(days: 30)),
  );

  LocalMockAuthRepository() {
    Future.microtask(() => _controller.add(_currentUser));
  }

  @override
  Stream<UserProfile?> authStateChanges() => _controller.stream;

  @override
  UserProfile? get currentUser => _currentUser;

  @override
  Future<UserProfile> signInWithEmail(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 400));
    _currentUser = UserProfile(
      id: 'demo-user-101',
      email: email,
      name: email.split('@').first.isNotEmpty ? email.split('@').first : 'Athlete',
      createdAt: DateTime.now().subtract(const Duration(days: 14)),
    );
    _controller.add(_currentUser);
    return _currentUser!;
  }

  @override
  Future<UserProfile> registerWithEmail(String email, String password, String name) async {
    await Future.delayed(const Duration(milliseconds: 400));
    _currentUser = UserProfile(
      id: 'demo-user-101',
      email: email,
      name: name,
      hasCompletedOnboarding: false,
      createdAt: DateTime.now(),
    );
    _controller.add(_currentUser);
    return _currentUser!;
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    await Future.delayed(const Duration(milliseconds: 300));
  }

  @override
  Future<void> updateProfile(UserProfile profile) async {
    _currentUser = profile;
    _controller.add(_currentUser);
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _controller.add(null);
  }

  @override
  Future<void> deleteAccount() async {
    _currentUser = null;
    _controller.add(null);
  }
}

// Global Riverpod Providers
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  // Uses LocalMockAuthRepository by default for seamless offline / demo usage,
  // easily switched to CloudflareAuthRepository() when connecting to live worker.
  return LocalMockAuthRepository();
});

final authStateChangesProvider = StreamProvider<UserProfile?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authStateChanges();
});

final currentUserProfileProvider = StateProvider<UserProfile?>((ref) {
  final authState = ref.watch(authStateChangesProvider).value;
  return authState;
});
