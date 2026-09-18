import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fittrack/app/theme/app_colors.dart';
import 'package:fittrack/app/theme/app_typography.dart';
import 'package:fittrack/core/widgets/app_button.dart';
import 'package:fittrack/core/widgets/app_card.dart';
import 'package:fittrack/core/widgets/app_photo_image.dart';
import 'package:fittrack/core/widgets/neumorphic_container.dart';
import 'package:fittrack/features/auth/data/auth_repository.dart';
import 'package:fittrack/features/progress_photos/data/progress_photo_repository.dart';
import 'package:fittrack/features/workouts/data/workout_repository.dart';
import 'package:fittrack/features/workouts/domain/workout.dart';
import 'package:fittrack/core/utils/streak_calculator.dart';

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

    final realStreak = StreakCalculator.calculateStreak(workouts.map((w) => w.date));
    final displayStreak = realStreak > 0 ? realStreak : (user?.workoutStreak ?? 0);

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
                      '$displayStreak',
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
                                ? "Today's Photo Logged!"
                                : "Upload your progress photo\nafter workout",
                            style: AppTypography.titleMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            hasPhotoToday
                                ? "Tap camera to add more poses (Side, Back)."
                                : "Keep your streak alive.",
                            style: AppTypography.bodySmall,
                          ),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("This Week", style: AppTypography.labelLarge),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${workouts.where((w) {
                        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
                        final start = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
                        final end = start.add(const Duration(days: 7));
                        return !w.date.isBefore(start) && w.date.isBefore(end);
                      }).map((w) => '${w.date.year}-${w.date.month}-${w.date.day}').toSet().length} / ${(user?.preferredWorkoutDays.isNotEmpty ?? false) ? user!.preferredWorkoutDays.length : 4} completed',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AppCard(
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(7, (index) {
                    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
                    final dayDate = DateTime(
                        startOfWeek.year, startOfWeek.month, startOfWeek.day + index);
                    final dayWorkouts = workouts.where((w) =>
                        w.date.year == dayDate.year &&
                        w.date.month == dayDate.month &&
                        w.date.day == dayDate.day).toList();
                    final isCompleted = dayWorkouts.isNotEmpty;
                    final isToday = dayDate.year == now.year &&
                        dayDate.month == now.month &&
                        dayDate.day == now.day;
                    final dayAbbrs = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                    final daySingle = ['M', 'T', 'W', 'T', 'F', 'S', 'S'][index];
                    final isPlanned = (user?.preferredWorkoutDays ??
                            ['Mon', 'Tue', 'Thu', 'Fri'])
                        .contains(dayAbbrs[index]);

                    return Expanded(
                      child: GestureDetector(
                        onTap: () => _showDaySummaryModal(
                          context,
                          dayDate,
                          dayWorkouts,
                          isToday,
                          isPlanned,
                        ),
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 2, vertical: 8),
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: isToday
                              ? BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: AppColors.primary.withOpacity(0.4),
                                    width: 1.5,
                                  ),
                                )
                              : null,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                daySingle,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isToday
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  color: isToday
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${dayDate.day}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isToday
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isToday
                                      ? AppColors.primary
                                      : AppColors.textMuted,
                                ),
                              ),
                              const SizedBox(height: 8),
                              NeumorphicContainer(
                                width: 30,
                                height: 30,
                                shape: BoxShape.circle,
                                style: isCompleted
                                    ? NeumorphicStyle.inset
                                    : NeumorphicStyle.flat,
                                child: Center(
                                  child: isCompleted
                                      ? const Icon(Icons.check_rounded,
                                          size: 16, color: AppColors.primary)
                                      : (isToday
                                          ? const Icon(Icons.add_rounded,
                                              size: 15,
                                              color: AppColors.primary)
                                          : Icon(
                                              isPlanned
                                                  ? Icons.circle_outlined
                                                  : Icons.remove_rounded,
                                              size: 13,
                                              color: AppColors.divider,
                                            )),
                                ),
                              ),
                              const SizedBox(height: 5),
                              if (isToday)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'TODAY',
                                    style: TextStyle(
                                      fontSize: 7,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                )
                              else if (isCompleted)
                                const Icon(Icons.check,
                                    size: 9, color: AppColors.primary)
                              else
                                const SizedBox(height: 11),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
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
                      itemCount: photosList.length + 1,
                      itemBuilder: (context, index) {
                        if (index == photosList.length) {
                          return Container(
                            width: 110,
                            margin: const EdgeInsets.only(right: 16),
                            child: GestureDetector(
                              onTap: () => context.push('/camera'),
                              child: const NeumorphicContainer(
                                borderRadius: 16,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_a_photo_outlined,
                                        color: AppColors.primary, size: 28),
                                    SizedBox(height: 8),
                                    Text(
                                      '+ Add Photo',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }

                        final photo = photosList[index];
                        return Container(
                          width: 110,
                          margin: const EdgeInsets.only(right: 16),
                          child: GestureDetector(
                            onTap: () => context.push('/progress/preview', extra: {
                              'photoId': photo.id,
                              'imagePath': photo.localFilePath ?? photo.downloadUrl ?? '',
                              'pose': photo.pose,
                              'selectedDate': photo.createdAt.toIso8601String(),
                              'dayNumber': photo.effectiveDayNumber,
                              'notes': photo.cleanNotes,
                              'isViewingExisting': true,
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

  void _showDaySummaryModal(
    BuildContext context,
    DateTime date,
    List<Workout> dayWorkouts,
    bool isToday,
    bool isPlannedWorkoutDay,
  ) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final dayNames = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];
    final dateStr =
        '${dayNames[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textMuted.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(dateStr, style: AppTypography.titleLarge),
                    const SizedBox(height: 4),
                    Text(
                      isToday
                          ? 'Today • ${dayWorkouts.isEmpty ? (isPlannedWorkoutDay ? "Scheduled Workout Day" : "Rest Day") : "${dayWorkouts.length} Session(s) Completed"}'
                          : dayWorkouts.isEmpty
                              ? (isPlannedWorkoutDay
                                  ? 'Scheduled Training Day'
                                  : 'Rest Day')
                              : '${dayWorkouts.length} Workout(s) Completed',
                      style: AppTypography.bodySmall.copyWith(
                        color: dayWorkouts.isNotEmpty
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (dayWorkouts.isNotEmpty)
                  const NeumorphicContainer(
                    shape: BoxShape.circle,
                    padding: EdgeInsets.all(10),
                    style: NeumorphicStyle.inset,
                    child: Icon(Icons.check_circle_rounded,
                        color: AppColors.primary, size: 24),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            if (dayWorkouts.isNotEmpty) ...[
              ...dayWorkouts.map((w) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AppCard(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const NeumorphicContainer(
                            shape: BoxShape.circle,
                            padding: EdgeInsets.all(10),
                            child: Icon(Icons.fitness_center_rounded,
                                color: AppColors.primary, size: 20),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(w.title, style: AppTypography.titleMedium),
                                const SizedBox(height: 4),
                                Text(
                                  '${w.exercises.length} exercises • ${w.durationMinutes} min • ${w.totalVolumeKg.toInt()} kg volume',
                                  style: AppTypography.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )),
              const SizedBox(height: 12),
              AppButton(
                label: 'Log Another Workout',
                icon: Icons.add_rounded,
                type: AppButtonType.secondary,
                onPressed: () {
                  Navigator.pop(ctx);
                  context.push('/workouts/new');
                },
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(
                      isPlannedWorkoutDay
                          ? Icons.fitness_center_outlined
                          : Icons.bed_outlined,
                      size: 40,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isPlannedWorkoutDay
                          ? (isToday
                              ? 'No workout logged yet today!'
                              : 'No workout recorded for this day.')
                          : 'Marked as a rest day.',
                      style: AppTypography.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              AppButton(
                label: isToday
                    ? 'Log Workout Now'
                    : 'Log Workout for this Date',
                icon: Icons.add_rounded,
                onPressed: () {
                  Navigator.pop(ctx);
                  context.push('/workouts/new');
                },
              ),
            ],
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
