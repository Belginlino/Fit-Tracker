import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fittrack/app/theme/app_colors.dart';
import 'package:fittrack/app/theme/app_typography.dart';
import 'package:fittrack/core/widgets/app_button.dart';
import 'package:fittrack/core/widgets/app_card.dart';
import 'package:fittrack/core/widgets/neumorphic_container.dart';
import 'package:fittrack/features/auth/data/auth_repository.dart';
import '../data/workout_repository.dart';
import '../domain/workout.dart';

class NewWorkoutScreen extends ConsumerStatefulWidget {
  final String? templateTitle;

  const NewWorkoutScreen({super.key, this.templateTitle});

  @override
  ConsumerState<NewWorkoutScreen> createState() => _NewWorkoutScreenState();
}

class _NewWorkoutScreenState extends ConsumerState<NewWorkoutScreen> {
  late TextEditingController _titleController;
  final List<Exercise> _exercises = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.templateTitle ?? 'Chest + Triceps');
    _initializeDefaultExercises();
  }

  void _initializeDefaultExercises() {
    _exercises.addAll([
      const Exercise(
        name: 'Barbell Bench Press',
        sets: [
          WorkoutSet(setNumber: 1, weight: 60.0, reps: 10),
          WorkoutSet(setNumber: 2, weight: 65.0, reps: 8),
          WorkoutSet(setNumber: 3, weight: 70.0, reps: 6),
        ],
      ),
      const Exercise(
        name: 'Incline Dumbbell Press',
        sets: [
          WorkoutSet(setNumber: 1, weight: 22.0, reps: 10),
          WorkoutSet(setNumber: 2, weight: 24.0, reps: 8),
        ],
      ),
    ]);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _addExercise() {
    setState(() {
      _exercises.add(
        Exercise(
          name: 'Exercise ${_exercises.length + 1}',
          sets: const [WorkoutSet(setNumber: 1, weight: 20.0, reps: 10)],
        ),
      );
    });
  }

  void _addSet(int exerciseIndex) {
    setState(() {
      final currentSets = _exercises[exerciseIndex].sets;
      final lastWeight =
          currentSets.isNotEmpty ? currentSets.last.weight : 20.0;
      final lastReps = currentSets.isNotEmpty ? currentSets.last.reps : 10;
      final newSet = WorkoutSet(
        setNumber: currentSets.length + 1,
        weight: lastWeight,
        reps: lastReps,
      );
      _exercises[exerciseIndex] = _exercises[exerciseIndex].copyWith(
        sets: [...currentSets, newSet],
      );
    });
  }

  void _updateSetWeight(int exerciseIndex, int setIndex, double delta) {
    setState(() {
      final currentSets = List<WorkoutSet>.from(_exercises[exerciseIndex].sets);
      final currentWeight = currentSets[setIndex].weight;
      final updatedWeight = (currentWeight + delta).clamp(0.0, 500.0);
      currentSets[setIndex] =
          currentSets[setIndex].copyWith(weight: updatedWeight);
      _exercises[exerciseIndex] =
          _exercises[exerciseIndex].copyWith(sets: currentSets);
    });
  }

  void _updateSetReps(int exerciseIndex, int setIndex, int delta) {
    setState(() {
      final currentSets = List<WorkoutSet>.from(_exercises[exerciseIndex].sets);
      final currentReps = currentSets[setIndex].reps;
      final updatedReps = (currentReps + delta).clamp(1, 100);
      currentSets[setIndex] = currentSets[setIndex].copyWith(reps: updatedReps);
      _exercises[exerciseIndex] =
          _exercises[exerciseIndex].copyWith(sets: currentSets);
    });
  }

  Future<void> _finishWorkout() async {
    setState(() => _isSaving = true);
    final authRepo = ref.read(authRepositoryProvider);
    final user = authRepo.currentUser;
    final workoutRepo = ref.read(workoutRepositoryProvider);

    final workout = Workout(
      id: 'workout-${DateTime.now().millisecondsSinceEpoch}',
      userId: user?.id ?? 'athlete-user',
      title: _titleController.text.trim().isNotEmpty
          ? _titleController.text.trim()
          : 'Workout',
      date: DateTime.now(),
      durationMinutes: 45,
      exercises: _exercises,
    );

    await workoutRepo.saveWorkout(workout);

    // Increment workout streak on profile
    if (user != null) {
      await authRepo.updateProfile(user.copyWith(
        workoutStreak: user.workoutStreak + 1,
      ));
    }

    if (mounted) {
      setState(() => _isSaving = false);
      _showPostWorkoutPhotoPrompt();
    }
  }

  // Fast Post-Workout Photo Prompt (Section 46)
  void _showPostWorkoutPhotoPrompt() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isDismissible: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.celebration_rounded,
                      color: AppColors.primary, size: 36),
                ),
                const SizedBox(height: 16),
                const Text('Great Workout!', style: AppTypography.displayMedium),
                const SizedBox(height: 8),
                const Text(
                  'Record today’s post-workout progress photo while you have a great pump.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium,
                ),
                const SizedBox(height: 24),
                AppButton(
                  label: 'Take Progress Photo',
                  icon: Icons.camera_alt_rounded,
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.push('/camera');
                  },
                ),
                const SizedBox(height: 12),
                AppButton(
                  label: 'Done for Today',
                  type: AppButtonType.outline,
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.go('/workouts');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _titleController,
          style: AppTypography.titleLarge,
          decoration: const InputDecoration(
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            fillColor: Colors.transparent,
            contentPadding: EdgeInsets.zero,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _finishWorkout,
            child: Text(
              'Finish',
              style:
                  AppTypography.labelLarge.copyWith(color: AppColors.primary),
            ),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: _exercises.length + 1,
        itemBuilder: (context, index) {
          if (index == _exercises.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: AppButton(
                label: 'Add Exercise',
                type: AppButtonType.outline,
                icon: Icons.add_rounded,
                onPressed: _addExercise,
              ),
            );
          }

          final exercise = _exercises[index];
          return _buildExerciseCard(index, exercise);
        },
      ),
    );
  }

  Widget _buildExerciseCard(int exIndex, Exercise exercise) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(exercise.name, style: AppTypography.titleMedium),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                      size: 20, color: AppColors.textMuted),
                  onPressed: () {
                    setState(() => _exercises.removeAt(exIndex));
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Sets Header
            const Row(
              children: [
                SizedBox(
                  width: 36,
                  child: Text('SET', style: AppTypography.bodySmall),
                ),
                Expanded(
                  child: Text('WEIGHT (KG)',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall),
                ),
                Expanded(
                  child: Text('REPS',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall),
                ),
              ],
            ),
            const Divider(height: 16),

            // Sets List
            ...exercise.sets.asMap().entries.map((entry) {
              final setIndex = entry.key;
              final set = entry.value;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 36,
                      child: Text('${set.setNumber}',
                          style: AppTypography.labelMedium),
                    ),

                    // Weight stepper
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline,
                                size: 20, color: AppColors.textMuted),
                            onPressed: () =>
                                _updateSetWeight(exIndex, setIndex, -2.5),
                          ),
                          NeumorphicContainer(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            style: NeumorphicStyle.inset,
                            borderRadius: 8,
                            child: Text('${set.weight}',
                                style: AppTypography.bodyLarge),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline,
                                size: 20, color: AppColors.primary),
                            onPressed: () =>
                                _updateSetWeight(exIndex, setIndex, 2.5),
                          ),
                        ],
                      ),
                    ),

                    // Reps stepper
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline,
                                size: 20, color: AppColors.textMuted),
                            onPressed: () =>
                                _updateSetReps(exIndex, setIndex, -1),
                          ),
                          NeumorphicContainer(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            style: NeumorphicStyle.inset,
                            borderRadius: 8,
                            child: Text('${set.reps}',
                                style: AppTypography.bodyLarge),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline,
                                size: 20, color: AppColors.primary),
                            onPressed: () =>
                                _updateSetReps(exIndex, setIndex, 1),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),

            // Add Set Button
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                icon: const Icon(Icons.add, size: 16, color: AppColors.primary),
                label: const Text('Add Set',
                    style: TextStyle(fontSize: 13, color: AppColors.primary)),
                onPressed: () => _addSet(exIndex),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
