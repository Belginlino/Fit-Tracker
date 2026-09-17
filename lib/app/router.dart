import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/widgets/neumorphic_container.dart';
import 'package:go_router/go_router.dart';
import '../features/analytics/presentation/analytics_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/measurements/presentation/body_measurements_screen.dart';
import '../features/measurements/presentation/weight_tracker_screen.dart';
import '../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/progress_photos/presentation/calendar_screen.dart';
import '../features/progress_photos/presentation/camera_screen.dart';
import '../features/progress_photos/presentation/comparison_screen.dart';
import '../features/progress_photos/presentation/photo_preview_screen.dart';
import '../features/progress_photos/presentation/timeline_screen.dart';
import '../features/workouts/presentation/new_workout_screen.dart';
import '../features/workouts/presentation/workout_screen.dart';

import '../core/services/pin_service.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/presentation/screens/pin_lock_screen.dart';

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen(authStateChangesProvider, (_, __) => notifyListeners());
    _ref.listen(pinServiceProvider, (_, __) => notifyListeners());
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authRepo = ref.read(authRepositoryProvider);
      final isLoggedIn = authRepo.currentUser != null;

      final pinState = ref.read(pinServiceProvider);
      final currentLoc = state.matchedLocation;
      final isAuthRoute =
          currentLoc == '/login' || currentLoc == '/register';

      // 1. If not logged in, enforce login/register
      if (!isLoggedIn) {
        return isAuthRoute ? null : '/login';
      }

      // 2. If logged in, check PIN protection
      if (pinState.isPinEnabled && !pinState.isUnlocked) {
        return currentLoc == '/pin-lock' ? null : '/pin-lock';
      }

      // 3. If logged in and unlocked (or no PIN), prevent staying on auth or pin-lock
      if (isAuthRoute || currentLoc == '/pin-lock') {
        return '/home';
      }

      return null;
    },
    routes: [
      // Auth & Onboarding Routes
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/pin-lock',
        builder: (context, state) => const PinLockScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      // Camera Modal Route
      GoRoute(
        path: '/camera',
        builder: (context, state) => const CameraScreen(),
      ),
      GoRoute(
        path: '/progress/preview',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final dynamic rawPaths = extra?['imagePaths'];
          List<String>? imagePaths;
          if (rawPaths is List) {
            imagePaths = rawPaths.map((e) => e.toString()).toList();
          }
          return PhotoPreviewScreen(
            photoId: extra?['photoId'] as String?,
            imagePaths: imagePaths,
            imagePath: extra?['imagePath'] as String?,
            initialPose: extra?['pose'] ?? 'Front',
            initialNotes: extra?['notes'],
            initialDate: extra?['selectedDate'] != null
                ? DateTime.tryParse(extra!['selectedDate'] as String)
                : null,
            initialDayNumber: extra?['dayNumber'] as int?,
            isViewingExisting: extra?['isViewingExisting'] as bool? ?? false,
          );
        },
      ),

      // Dedicated Comparison & Calendar Routes
      GoRoute(
        path: '/progress/compare',
        builder: (context, state) => const ComparisonScreen(),
      ),
      GoRoute(
        path: '/progress/calendar',
        builder: (context, state) => const CalendarScreen(),
      ),

      // Workout Logging Route
      GoRoute(
        path: '/workouts/new',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return NewWorkoutScreen(
            templateTitle: extra?['templateTitle'],
          );
        },
      ),

      // Measurements Routes
      GoRoute(
        path: '/measurements/weight',
        builder: (context, state) => const WeightTrackerScreen(),
      ),
      GoRoute(
        path: '/measurements/body',
        builder: (context, state) => const BodyMeasurementsScreen(),
      ),

      // Main App Shell with Bottom Navigation (Section 6)
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return Scaffold(
            body: navigationShell,
            bottomNavigationBar: NeumorphicContainer(
              borderRadius: 0,
              padding: const EdgeInsets.only(top: 8),
              style: NeumorphicStyle.raised, // Or flat with outer shadow
              child: BottomNavigationBar(
                currentIndex: navigationShell.currentIndex,
                elevation: 0,
                backgroundColor: Colors.transparent,
                onTap: (index) => navigationShell.goBranch(
                  index,
                  initialLocation: index == navigationShell.currentIndex,
                ),
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home_outlined),
                    activeIcon: Icon(Icons.home_filled),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.auto_graph_outlined),
                    activeIcon: Icon(Icons.auto_graph_rounded),
                    label: 'Progress',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.fitness_center_outlined),
                    activeIcon: Icon(Icons.fitness_center_rounded),
                    label: 'Workout',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.insights_rounded),
                    activeIcon: Icon(Icons.insights_rounded),
                    label: 'Analytics',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.person_outline_rounded),
                    activeIcon: Icon(Icons.person_rounded),
                    label: 'Profile',
                  ),
                ],
              ),
            ),
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/progress',
                builder: (context, state) => const TimelineScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/workouts',
                builder: (context, state) => const WorkoutScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/analytics',
                builder: (context, state) => const AnalyticsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
