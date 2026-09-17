import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fittrack/core/supabase/supabase_config.dart';
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

/// Supabase Auth & Profiles Repository
class SupabaseAuthRepository implements AuthRepository {
  final _controller = StreamController<UserProfile?>.broadcast();
  UserProfile? _currentUser;
  StreamSubscription<AuthState>? _authSub;

  SupabaseAuthRepository() {
    _init();
  }

  void _init() {
    if (!SupabaseConfig.isConfigured) {
      _controller.add(null);
      return;
    }

    try {
      final client = Supabase.instance.client;
      final initialSession = client.auth.currentSession;
      if (initialSession != null) {
        _fetchProfile(initialSession.user.id, initialSession.user.email);
      } else {
        _controller.add(null);
      }

      _authSub = client.auth.onAuthStateChange.listen((data) async {
        final session = data.session;
        if (session != null) {
          await _fetchProfile(session.user.id, session.user.email);
        } else {
          _currentUser = null;
          _controller.add(null);
        }
      });
    } catch (_) {
      _controller.add(null);
    }
  }

  Future<void> _fetchProfile(String userId, String? email) async {
    try {
      final client = Supabase.instance.client;
      final response =
          await client.from('profiles').select().eq('id', userId).maybeSingle();

      if (response != null) {
        final map = Map<String, dynamic>.from(response);
        map['email'] = email ?? '';
        _currentUser = UserProfile.fromMap(map, userId);
      } else {
        _currentUser = UserProfile(
          id: userId,
          email: email ?? '',
          name: email?.split('@').first ?? 'Athlete',
          createdAt: DateTime.now(),
        );
      }
      _controller.add(_currentUser);
    } catch (_) {
      _controller.add(_currentUser);
    }
  }

  @override
  Stream<UserProfile?> authStateChanges() => _controller.stream;

  @override
  UserProfile? get currentUser => _currentUser;

  @override
  Future<UserProfile> signInWithEmail(String email, String password) async {
    final client = Supabase.instance.client;
    final res = await client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    final user = res.user;
    if (user == null) {
      throw Exception('Failed to sign in. Please verify your credentials.');
    }
    await _fetchProfile(user.id, user.email);
    return _currentUser ??
        UserProfile(
          id: user.id,
          email: user.email ?? email,
          name: user.email?.split('@').first ?? 'Athlete',
          createdAt: DateTime.now(),
        );
  }

  @override
  Future<UserProfile> registerWithEmail(
      String email, String password, String name) async {
    final client = Supabase.instance.client;
    final res = await client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'name': name},
    );
    final user = res.user;
    if (user == null) {
      throw Exception('Registration failed.');
    }

    // Wait briefly for PostgreSQL trigger on_auth_user_created to run
    await Future.delayed(const Duration(milliseconds: 500));
    await _fetchProfile(user.id, user.email);

    return _currentUser ??
        UserProfile(
          id: user.id,
          email: user.email ?? email,
          name: name,
          hasCompletedOnboarding: false,
          createdAt: DateTime.now(),
        );
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    final client = Supabase.instance.client;
    await client.auth.resetPasswordForEmail(email.trim());
  }

  @override
  Future<void> updateProfile(UserProfile profile) async {
    _currentUser = profile;
    _controller.add(_currentUser);

    if (!SupabaseConfig.isConfigured) return;

    try {
      final client = Supabase.instance.client;
      if (client.auth.currentSession != null) {
        String formattedTime = profile.reminderTime;
        if (formattedTime.length == 5) {
          formattedTime = '$formattedTime:00';
        }

        await client.from('profiles').upsert({
          'id': profile.id,
          'name': profile.name,
          'goal': profile.goal,
          'height': profile.height,
          'current_weight': profile.currentWeight,
          'target_weight': profile.targetWeight,
          'preferred_reminder_time': formattedTime,
          'workout_streak': profile.workoutStreak,
          'photo_streak': profile.photoStreak,
          'has_completed_onboarding': profile.hasCompletedOnboarding,
        });
      }
    } catch (e) {
      // Remote sync error caught; local state is preserved
    }
  }

  @override
  Future<void> signOut() async {
    final client = Supabase.instance.client;
    await client.auth.signOut();
    _currentUser = null;
    _controller.add(null);
  }

  @override
  Future<void> deleteAccount() async {
    final client = Supabase.instance.client;
    if (_currentUser != null) {
      await client.from('profiles').delete().eq('id', _currentUser!.id);
    }
    await signOut();
  }

  void dispose() {
    _authSub?.cancel();
    _controller.close();
  }
}

// Global Riverpod Providers
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return SupabaseAuthRepository();
});

final authStateChangesProvider = StreamProvider<UserProfile?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authStateChanges();
});

final currentUserProfileProvider = StateProvider<UserProfile?>((ref) {
  final authState = ref.watch(authStateChangesProvider).value;
  return authState;
});
