import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fittrack/app/theme/app_colors.dart';
import 'package:fittrack/app/theme/app_typography.dart';
import 'package:fittrack/core/widgets/neumorphic_container.dart';
import 'package:fittrack/core/services/pin_service.dart';
import '../../data/auth_repository.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkSessionAndNavigate();
  }

  Future<void> _checkSessionAndNavigate() async {
    // Wait for the auth repository to finish session verification
    final repo = ref.read(authRepositoryProvider);
    await repo.initializationDone;

    // Small delay for smooth visual transition
    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

    final currentUser = repo.currentUser;
    if (currentUser == null) {
      context.go('/login');
      return;
    }

    if (!currentUser.hasCompletedOnboarding) {
      context.go('/onboarding');
      return;
    }

    final pinState = ref.read(pinServiceProvider);
    if (pinState.isPinEnabled && !pinState.isUnlocked) {
      context.go('/pin-lock');
      return;
    }

    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Neumorphic App Emblem
            NeumorphicContainer(
              width: 100,
              height: 100,
              shape: BoxShape.circle,
              padding: EdgeInsets.all(20),
              style: NeumorphicStyle.raised,
              child: Icon(
                Icons.fitness_center_rounded,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: 28),

            // App Name
            Text(
              'FitTrack',
              style: AppTypography.displayLarge,
            ),
            SizedBox(height: 8),

            // Tagline
            Text(
              'Your Transformation Journal',
              style: AppTypography.bodyMedium,
            ),
            SizedBox(height: 48),

            // Loading indicator
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
