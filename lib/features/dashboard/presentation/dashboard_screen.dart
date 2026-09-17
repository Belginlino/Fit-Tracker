import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fittrack/app/theme/app_colors.dart';
import 'package:fittrack/app/theme/app_typography.dart';
import 'package:fittrack/core/widgets/app_card.dart';
import 'package:fittrack/core/widgets/app_photo_image.dart';
import 'package:fittrack/core/widgets/neumorphic_container.dart';
import 'package:fittrack/features/auth/data/auth_repository.dart';
import 'package:fittrack/features/progress_photos/data/progress_photo_repository.dart';
import 'package:fittrack/features/workouts/data/workout_repository.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProfileProvider);
    final userId = user?.id ?? '';
    final photosAsync = ref.watch(progressPhotosStreamProvider(userId));
    final workoutsAsync = ref.watch(workoutsStreamProvider(userId));

    final name = (user?.name != null && user!.name.isNotEmpty)
        ? user.name
        : (user?.email != null && user!.email.isNotEmpty)
            ? user.email.split('@').first
            : 'Champion';
    final now = DateTime.now();

    final workouts = workoutsAsync.value ?? [];

    final photos = photosAsync.value ?? [];
    final hasPhotoToday = photos.any((p) =>
        p.createdAt.year == now.year &&
        p.createdAt.month == now.month &&
        p.createdAt.day == now.day);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_getGreeting()},\n$name 👋',
                        style: AppTypography.displayMedium,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Let's continue your progress.",
                        style: AppTypography.bodyMedium,
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const NeumorphicContainer(
                        shape: BoxShape.circle,
                        padding: EdgeInsets.all(10),
                        child: Icon(Icons.notifications_none_rounded,
                            color: AppColors.primary, size: 22),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => context.go('/profile'),
                        child: const NeumorphicContainer(
                          shape: BoxShape.circle,
                          style: NeumorphicStyle.inset,
                          padding: EdgeInsets.all(4),
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: AppColors.primary,
                            child: Icon(Icons.person,
                                color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Today's Overview
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      'Day Streak',
                      '${user?.workoutStreak ?? 0}',
                      Icons.local_fire_department_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      'Workouts',
                      '${workouts.length}',
                      Icons.fitness_center_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      'Weight (kg)',
                      user?.currentWeight != null
                          ? user!.currentWeight.toStringAsFixed(1)
                          : '--',
                      Icons.scale_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Today's Goal
              const Text("Today's Goal", style: AppTypography.labelLarge),
              const SizedBox(height: 12),
              AppCard(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hasPhotoToday
                                ? "Photo Uploaded!"
                                : "Upload your progress photo\nafter workout",
                            style: AppTypography.titleMedium,
                          ),
                          if (!hasPhotoToday) ...[
                            const SizedBox(height: 8),
                            const Text("Keep your streak alive.",
                                style: AppTypography.bodySmall),
                          ]
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    NeumorphicContainer(
                      shape: BoxShape.circle,
                      padding: const EdgeInsets.all(16),
                      child: GestureDetector(
                        onTap: () => context.push('/camera'),
                        child: const Icon(Icons.camera_alt_outlined,
                            color: AppColors.primary, size: 28),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Quick Actions
              const Text("Quick Actions", style: AppTypography.labelLarge),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildQuickActionCard(
                      'Log Workout',
                      Icons.fitness_center_outlined,
                      () => context.push('/workouts/new'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildQuickActionCard(
                      'Add Photo',
                      Icons.camera_alt_outlined,
                      () => context.push('/camera'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildQuickActionCard(
                      'Add Weight',
                      Icons.scale_outlined,
                      () => context.push('/measurements/weight'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildQuickActionCard(
                      'View Stats',
                      Icons.insights_outlined,
                      () => context.go('/analytics'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // This Week
              const Text("This Week", style: AppTypography.labelLarge),
              const SizedBox(height: 12),
              AppCard(
                padding:
                    const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                      .asMap()
                      .entries
                      .map((entry) {
                    final isCompleted = entry.key <
                        2; // Mocking slightly for visual, ideally calculated
                    return Column(
                      children: [
                        Text(entry.value, style: AppTypography.labelMedium),
                        const SizedBox(height: 12),
                        NeumorphicContainer(
                          width: 28,
                          height: 28,
                          shape: BoxShape.circle,
                          style: isCompleted
                              ? NeumorphicStyle.inset
                              : NeumorphicStyle.flat,
                          child: Icon(
                            isCompleted ? Icons.check : Icons.circle_outlined,
                            size: 16,
                            color: isCompleted
                                ? AppColors.primary
                                : AppColors.divider,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 32),

              // Recent Progress
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Recent Progress', style: AppTypography.labelLarge),
                  GestureDetector(
                    onTap: () => context.go('/progress'),
                    child: Text(
                      'View All',
                      style: AppTypography.labelMedium
                          .copyWith(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              photosAsync.when(
                data: (photosList) {
                  if (photosList.isEmpty) {
                    return AppCard(
                      onTap: () => context.push('/camera'),
                      child: Column(
                        children: [
                          const Icon(Icons.add_a_photo_outlined,
                              color: AppColors.primary, size: 32),
                          const SizedBox(height: 8),
                          const Text(
                            'Capture Your Day 1 Baseline Photo',
                            style: AppTypography.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Start tracking your transformation from day one.',
                            style: AppTypography.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              '+ Add Day 1 Photo',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return SizedBox(
                    height: 145,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: photosList.length,
                      itemBuilder: (context, index) {
                        final photo = photosList[index];
                        return Container(
                          width: 110,
                          margin: const EdgeInsets.only(right: 16),
                          child: GestureDetector(
                            onTap: () => context.push('/progress/preview', extra: {
                              'imagePath': photo.localFilePath ?? photo.downloadUrl ?? '',
                              'pose': photo.pose,
                              'selectedDate': photo.createdAt.toIso8601String(),
                              'dayNumber': photo.effectiveDayNumber,
                              'notes': photo.cleanNotes,
                            }),
                            child: NeumorphicContainer(
                              borderRadius: 16,
                              padding: EdgeInsets.zero,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    AppPhotoImage(
                                      localPath: photo.localFilePath,
                                      remoteUrl: photo.downloadUrl,
                                      fit: BoxFit.cover,
                                    ),
                                    Positioned(
                                      top: 6,
                                      left: 6,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: photo.isDayOne
                                              ? const Color(0xFFD97706)
                                              : Colors.black.withValues(alpha: 0.65),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          photo.isDayOne ? '★ Day 1' : photo.dayLabel,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(height: 12),
          Text(value, style: AppTypography.titleLarge),
          const SizedBox(height: 4),
          Text(label, style: AppTypography.bodySmall),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(
      String label, IconData icon, VoidCallback onTap) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 28),
          const SizedBox(height: 12),
          Text(label, style: AppTypography.labelMedium),
        ],
      ),
    );
  }
}
