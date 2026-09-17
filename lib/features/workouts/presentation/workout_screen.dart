import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fittrack/app/theme/app_colors.dart';
import 'package:fittrack/app/theme/app_typography.dart';
import 'package:fittrack/core/constants/app_constants.dart';
import 'package:fittrack/core/utils/date_formatter.dart';
import 'package:fittrack/core/widgets/app_button.dart';
import 'package:fittrack/core/widgets/app_card.dart';
import 'package:fittrack/core/widgets/neumorphic_container.dart';
import 'package:fittrack/features/auth/data/auth_repository.dart';
import '../data/workout_repository.dart';
import '../domain/workout.dart';

class WorkoutScreen extends ConsumerWidget {
  const WorkoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProfileProvider);
    final workoutsAsync =
        ref.watch(workoutsStreamProvider(user?.id ?? ''));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workouts'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Start Workout Banner
            NeumorphicContainer(
              padding: const EdgeInsets.all(24),
              borderRadius: 24,
              style: NeumorphicStyle.inset,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ready to Train?',
                    style: AppTypography.displayMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Track sets, reps, and weights to unlock personal records.',
                    style: AppTypography.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  AppButton(
                    label: 'Start Blank Workout',
                    icon: Icons.add_rounded,
                    onPressed: () => context.push('/workouts/new'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Workout Templates Carousel
            const Text('Quick Templates', style: AppTypography.labelLarge),
            const SizedBox(height: 16),
            SizedBox(
              height: 110,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                itemCount: AppConstants.defaultTemplates.length,
                itemBuilder: (context, index) {
                  final template = AppConstants.defaultTemplates[index];
                  return Container(
                    width: 140,
                    margin: const EdgeInsets.only(right: 16),
                    child: GestureDetector(
                      onTap: () => context.push('/workouts/new',
                          extra: {'templateTitle': template}),
                      child: NeumorphicContainer(
                        padding: const EdgeInsets.all(16),
                        borderRadius: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Icon(Icons.fitness_center_rounded,
                                size: 24, color: AppColors.primary),
                            Text(
                              template,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.labelMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),

            // Workout History
            const Text('Past Sessions', style: AppTypography.labelLarge),
            const SizedBox(height: 16),
            workoutsAsync.when(
              data: (workouts) {
                if (workouts.isEmpty) {
                  return const AppCard(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'No workouts logged yet. Tap above to begin!',
                          style: AppTypography.bodyMedium,
                        ),
                      ),
                    ),
                  );
                }

                return Column(
                  children: workouts
                      .map((w) => _buildWorkoutCard(context, w))
                      .toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutCard(BuildContext context, Workout workout) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AppCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    workout.title,
                    style: AppTypography.titleLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  DateFormatter.formatTimelineDate(workout.date),
                  style: AppTypography.labelMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  '${workout.exercises.length} Exercises · ${workout.totalSets} Sets · ${workout.durationMinutes} min',
                  style: AppTypography.bodySmall,
                ),
                const Spacer(),
                Text(
                  '${workout.totalVolumeKg.toStringAsFixed(0)} kg Vol',
                  style: AppTypography.titleMedium
                      .copyWith(color: AppColors.primary),
                ),
              ],
            ),
            if (workout.exercises.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(color: AppColors.border),
              const SizedBox(height: 8),
              ...workout.exercises.take(2).map((ex) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(ex.name, style: AppTypography.bodyMedium),
                      Text('${ex.sets.length} sets',
                          style: AppTypography.bodySmall),
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
