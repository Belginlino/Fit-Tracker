import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fittrack/app/theme/app_colors.dart';
import 'package:fittrack/app/theme/app_typography.dart';
import 'package:fittrack/core/widgets/app_button.dart';
import 'package:fittrack/core/widgets/app_card.dart';
import 'package:fittrack/core/widgets/streak_badge.dart';
import 'package:fittrack/features/auth/data/auth_repository.dart';
import 'package:fittrack/features/progress_photos/data/progress_photo_repository.dart';
import 'package:fittrack/features/workouts/data/workout_repository.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProfileProvider);
    final userId = user?.id ?? 'demo-user-101';
    final photosAsync = ref.watch(progressPhotosStreamProvider(userId));

    final name = user?.name ?? 'Athlete';

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Greeting & Profile Avatar Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_getGreeting()},',
                        style: AppTypography.bodyMedium,
                      ),
                      Text(
                        name,
                        style: AppTypography.displayMedium.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => context.go('/profile'),
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary, width: 1.5),
                      ),
                      child: const Center(
                        child: Icon(Icons.person_rounded, color: AppColors.primary, size: 24),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Consistency Streaks Row (Section 9 & 23)
              Row(
                children: [
                  Expanded(
                    child: StreakBadge(
                      streakDays: user?.workoutStreak ?? 12,
                      type: StreakType.workout,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StreakBadge(
                      streakDays: user?.photoStreak ?? 8,
                      type: StreakType.photo,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Weight Trend Quick Card
              AppCard(
                onTap: () => context.push('/measurements/weight'),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.scale_rounded, color: AppColors.primary, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${user?.currentWeight ?? 74.2} kg',
                              style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w800),
                            ),
                            Text('Current Weight · View Trend', style: AppTypography.bodySmall),
                          ],
                        ),
                      ],
                    ),
                    const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Today's Workout Card (Section 9)
              AppCard(
                border: Border.all(color: AppColors.accentLime.withOpacity(0.4), width: 1.2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.accentLime.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            "TODAY'S WORKOUT",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.accentLime,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        Text('Day 16 of Goal', style: AppTypography.bodySmall),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('Chest + Triceps', style: AppTypography.titleLarge),
                    const SizedBox(height: 4),
                    Text(
                      'Bench Press · Incline Dumbbell · Tricep Pushdown',
                      style: AppTypography.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    AppButton(
                      label: 'Start Workout',
                      icon: Icons.play_arrow_rounded,
                      onPressed: () => context.push('/workouts/new', extra: {'templateTitle': 'Chest + Triceps'}),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Fast Progress Photo CTA (Section 9 & 46)
              AppCard(
                gradient: const LinearGradient(
                  colors: [Color(0xFF192338), Color(0xFF131926)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt_rounded, color: AppColors.primary, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Today's Progress Photo", style: AppTypography.titleMedium),
                          const SizedBox(height: 2),
                          Text('Maintain your 8-day photo streak', style: AppTypography.bodySmall),
                        ],
                      ),
                    ),
                    AppButton(
                      label: 'Capture',
                      width: 96,
                      height: 42,
                      onPressed: () => context.push('/camera'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Recent Progress Photos Carousel (Section 9)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Recent Progress', style: AppTypography.titleMedium),
                  GestureDetector(
                    onTap: () => context.go('/progress'),
                    child: Text(
                      'View Timeline',
                      style: AppTypography.labelMedium.copyWith(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              photosAsync.when(
                data: (photos) {
                  if (photos.isEmpty) {
                    return AppCard(
                      child: Center(
                        child: Text(
                          'No progress photos yet. Tap Capture above!',
                          style: AppTypography.bodyMedium,
                        ),
                      ),
                    );
                  }

                  return SizedBox(
                    height: 130,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: photos.length,
                      itemBuilder: (context, index) {
                        final photo = photos[index];
                        return Container(
                          width: 100,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A2234),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Center(
                                  child: Icon(
                                    Icons.person_rounded,
                                    size: 40,
                                    color: AppColors.primary.withOpacity(0.6),
                                  ),
                                ),
                                Positioned(
                                  bottom: 6,
                                  left: 6,
                                  right: 6,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${photo.weightAtCapture ?? "--"} kg',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
