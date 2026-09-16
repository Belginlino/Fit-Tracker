import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fittrack/app/theme/app_colors.dart';
import 'package:fittrack/app/theme/app_typography.dart';
import 'package:fittrack/core/constants/app_constants.dart';
import 'package:fittrack/core/utils/date_formatter.dart';
import 'package:fittrack/core/widgets/app_button.dart';
import 'package:fittrack/core/widgets/app_card.dart';
import 'package:fittrack/features/auth/data/auth_repository.dart';
import '../data/workout_repository.dart';
import '../domain/workout.dart';

class WorkoutScreen extends ConsumerWidget {
  const WorkoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProfileProvider);
    final workoutsAsync = ref.watch(workoutsStreamProvider(user?.id ?? 'demo-user-101'));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workouts'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Start Workout Banner
            AppCard(
              gradient: AppColors.primaryGradient,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ready to Train?',
                    style: AppTypography.titleLarge.copyWith(color: Colors.black),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Track sets, reps, and weights to unlock personal records.',
                    style: AppTypography.bodyMedium.copyWith(color: Colors.black87),
                  ),
                  const SizedBox(height: 16),
                  AppButton(
                    label: 'Start Blank Workout',
                    icon: Icons.add_rounded,
                    type: AppButtonType.secondary,
                    onPressed: () => context.push('/workouts/new'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Workout Templates Carousel (Section 19)
            Text('Quick Templates', style: AppTypography.titleMedium),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: AppConstants.defaultTemplates.length,
                itemBuilder: (context, index) {
                  final template = AppConstants.defaultTemplates[index];
                  return Container(
                    width: 140,
                    margin: const EdgeInsets.only(right: 12),
                    child: AppCard(
                      padding: const EdgeInsets.all(12),
                      onTap: () => context.push('/workouts/new', extra: {'templateTitle': template}),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Icon(Icons.fitness_center_rounded, size: 22, color: AppColors.primary),
                          Text(
                            template,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.labelLarge,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 28),

            // Workout History
            Text('Past Sessions', style: AppTypography.titleMedium),
            const SizedBox(height: 12),
            workoutsAsync.when(
              data: (workouts) {
                if (workouts.isEmpty) {
                  return AppCard(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'No workouts logged yet. Tap above to begin!',
                          style: AppTypography.bodyMedium,
                        ),
                      ),
                    ),
                  );
                }

                return Column(
                  children: workouts.map((w) => _buildWorkoutCard(context, w)).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutCard(BuildContext context, Workout workout) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(workout.title, style: AppTypography.titleMedium),
                Text(
                  DateFormatter.formatTimelineDate(workout.date),
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '${workout.exercises.length} Exercises · ${workout.totalSets} Sets · ${workout.durationMinutes} min',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
                const Spacer(),
                Text(
                  '${workout.totalVolumeKg.toStringAsFixed(0)} kg Vol',
                  style: AppTypography.labelMedium.copyWith(color: AppColors.primary),
                ),
              ],
            ),
            if (workout.exercises.isNotEmpty) ...[
              const Divider(height: 20),
              ...workout.exercises.take(2).map((ex) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(ex.name, style: AppTypography.bodyMedium),
                      Text('${ex.sets.length} sets', style: AppTypography.bodySmall),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}
