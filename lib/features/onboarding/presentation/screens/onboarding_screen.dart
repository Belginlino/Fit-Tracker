import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fittrack/app/theme/app_colors.dart';
import 'package:fittrack/app/theme/app_typography.dart';
import 'package:fittrack/core/widgets/app_button.dart';
import 'package:fittrack/core/widgets/app_card.dart';
import 'package:fittrack/core/widgets/app_text_field.dart';
import 'package:fittrack/features/auth/data/auth_repository.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _currentStep = 0;
  String _selectedGoal = 'Build Muscle';
  final _weightController = TextEditingController(text: '74.2');
  final _heightController = TextEditingController(text: '178');
  final _targetWeightController = TextEditingController(text: '78.0');
  final List<String> _selectedDays = ['Mon', 'Tue', 'Thu', 'Fri'];
  String _reminderTime = '18:30';

  final List<String> _goals = [
    'Build Muscle',
    'Lose Fat',
    'Improve Strength',
    'Maintain Fitness',
    'General Fitness',
  ];

  final List<String> _weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _targetWeightController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final repo = ref.read(authRepositoryProvider);
    final current = repo.currentUser;
    if (current != null) {
      final updated = current.copyWith(
        goal: _selectedGoal,
        currentWeight: double.tryParse(_weightController.text) ?? 74.2,
        height: double.tryParse(_heightController.text) ?? 178.0,
        targetWeight: double.tryParse(_targetWeightController.text) ?? 78.0,
        preferredWorkoutDays: _selectedDays,
        reminderTime: _reminderTime,
        hasCompletedOnboarding: true,
      );
      await repo.updateProfile(updated);
    }
    if (mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Progress Bar
              Row(
                children: List.generate(3, (index) {
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: index <= _currentStep ? AppColors.primary : AppColors.divider,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 32),

              Expanded(
                child: _buildCurrentStep(),
              ),

              Row(
                children: [
                  if (_currentStep > 0) ...[
                    Expanded(
                      flex: 1,
                      child: AppButton(
                        label: 'Back',
                        type: AppButtonType.outline,
                        onPressed: () => setState(() => _currentStep--),
                      ),
                    ),
                    const SizedBox(width: 14),
                  ],
                  Expanded(
                    flex: 2,
                    child: AppButton(
                      label: _currentStep == 2 ? 'Get Started' : 'Next',
                      onPressed: () {
                        if (_currentStep < 2) {
                          setState(() => _currentStep++);
                        } else {
                          _completeOnboarding();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildGoalStep();
      case 1:
        return _buildBodyMetricsStep();
      case 2:
        return _buildHabitsStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildGoalStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('What is your primary goal?', style: AppTypography.displayMedium),
          const SizedBox(height: 8),
          Text('FitTrack adjusts timeline insights to match your focus.', style: AppTypography.bodyMedium),
          const SizedBox(height: 28),
          ..._goals.map((goal) {
            final isSelected = _selectedGoal == goal;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppCard(
                onTap: () => setState(() => _selectedGoal = goal),
                color: isSelected ? AppColors.primary.withOpacity(0.12) : AppColors.card,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.divider,
                  width: isSelected ? 1.5 : 1,
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
                      color: isSelected ? AppColors.primary : AppColors.textMuted,
                      size: 22,
                    ),
                    const SizedBox(width: 14),
                    Text(
                      goal,
                      style: AppTypography.titleMedium.copyWith(
                        color: isSelected ? AppColors.primary : AppColors.textPrimary,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBodyMetricsStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your Baseline', style: AppTypography.displayMedium),
          const SizedBox(height: 8),
          Text('Record your initial metrics to benchmark progress.', style: AppTypography.bodyMedium),
          const SizedBox(height: 28),
          AppTextField(
            label: 'Current Weight (kg)',
            hint: '74.2',
            controller: _weightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            prefixIcon: const Icon(Icons.scale_rounded, color: AppColors.textMuted, size: 20),
          ),
          const SizedBox(height: 20),
          AppTextField(
            label: 'Target Weight (kg)',
            hint: '78.0',
            controller: _targetWeightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            prefixIcon: const Icon(Icons.flag_rounded, color: AppColors.textMuted, size: 20),
          ),
          const SizedBox(height: 20),
          AppTextField(
            label: 'Height (cm)',
            hint: '178',
            controller: _heightController,
            keyboardType: TextInputType.number,
            prefixIcon: const Icon(Icons.height_rounded, color: AppColors.textMuted, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitsStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Consistency Setup', style: AppTypography.displayMedium),
          const SizedBox(height: 8),
          Text('Pick your active workout days & daily reminder time.', style: AppTypography.bodyMedium),
          const SizedBox(height: 28),
          Text('Preferred Workout Days', style: AppTypography.labelMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _weekDays.map((day) {
              final isSelected = _selectedDays.contains(day);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedDays.remove(day);
                    } else {
                      _selectedDays.add(day);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.divider,
                    ),
                  ),
                  child: Text(
                    day,
                    style: TextStyle(
                      color: isSelected ? Colors.black : AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 28),
          Text('Daily Reminder Time', style: AppTypography.labelMedium),
          const SizedBox(height: 12),
          AppCard(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.notifications_active_rounded, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Text('Evening Check-In', style: AppTypography.titleMedium),
                  ],
                ),
                Text(
                  _reminderTime,
                  style: AppTypography.titleMedium.copyWith(color: AppColors.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
