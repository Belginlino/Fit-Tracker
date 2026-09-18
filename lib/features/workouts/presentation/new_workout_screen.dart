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
import 'package:fittrack/core/utils/streak_calculator.dart';

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

  final List<String> _popularExercises = const [
    'Barbell Bench Press',
    'Incline Dumbbell Press',
    'Barbell Squat',
    'Deadlift',
    'Overhead Press',
    'Pull-Ups',
    'Barbell Row',
    'Dumbbell Lateral Raise',
    'Bicep Curl',
    'Tricep Pushdown',
    'Leg Press',
    'Lat Pulldown',
  ];

  void _addExercise() {
    _showExerciseSelectionDialog();
  }

  void _showExerciseSelectionDialog({int? editIndex}) {
    final isEditing = editIndex != null;
    final initialName = isEditing ? _exercises[editIndex].name : '';
    final nameCtrl = TextEditingController(text: initialName);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(isEditing ? 'Edit Exercise' : 'Add Exercise',
            style: AppTypography.titleLarge),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Exercise Name',
                  hintText: 'e.g. Bulgarian Split Squat',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Quick Select:', style: AppTypography.bodySmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _popularExercises.map((ex) {
                  return ActionChip(
                    label: Text(ex, style: const TextStyle(fontSize: 12)),
                    backgroundColor: AppColors.surface,
                    onPressed: () {
                      nameCtrl.text = ex;
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              final chosenName = nameCtrl.text.trim().isNotEmpty
                  ? nameCtrl.text.trim()
                  : (isEditing ? initialName : 'Exercise ${_exercises.length + 1}');
              if (isEditing) {
                setState(() {
                  _exercises[editIndex] = _exercises[editIndex].copyWith(name: chosenName);
                });
              } else {
                setState(() {
                  _exercises.add(
                    Exercise(
                      name: chosenName,
                      sets: const [WorkoutSet(setNumber: 1, weight: 20.0, reps: 10)],
                    ),
                  );
                });
              }
              Navigator.pop(ctx);
            },
            child: Text(isEditing ? 'Update' : 'Add'),
          ),
        ],
      ),
    );
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
    if (_isSaving) return;
    setState(() => _isSaving = true);
    final authRepo = ref.read(authRepositoryProvider);
    final user = authRepo.currentUser;
    final workoutRepo = ref.read(workoutRepositoryProvider);

    final now = DateTime.now();
    final workout = Workout(
      id: 'workout-${now.millisecondsSinceEpoch}',
      userId: user?.id ?? 'user-local',
      title: _titleController.text.trim().isNotEmpty
          ? _titleController.text.trim()
          : 'Workout',
      date: now,
      durationMinutes: 45,
      exercises: _exercises,
    );

    await workoutRepo.saveWorkout(workout);

    // Calculate accurate consecutive workout streak from all workouts
    if (user != null) {
      final existingWorkouts = await workoutRepo.getWorkouts(user.id);
      final allDates = [now, ...existingWorkouts.map((w) => w.date)];
      final accurateStreak = StreakCalculator.calculateStreak(allDates);

      await authRepo.updateProfile(user.copyWith(
        workoutStreak: accurateStreak,
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
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => _showExerciseSelectionDialog(editIndex: exIndex),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(exercise.name, style: AppTypography.titleMedium),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.edit_outlined, size: 16, color: AppColors.textMuted),
                        ],
                      ),
                    ),
                  ),
                ),
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
