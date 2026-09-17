import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fittrack/app/theme/app_colors.dart';
import 'package:fittrack/app/theme/app_typography.dart';
import 'package:fittrack/core/widgets/app_button.dart';
import 'package:fittrack/core/widgets/neumorphic_container.dart';
import 'package:fittrack/core/widgets/app_card.dart';
import 'package:fittrack/core/widgets/app_text_field.dart';
import 'package:fittrack/features/auth/data/auth_repository.dart';
import 'package:fittrack/features/auth/domain/user_model.dart';

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
  bool _isLoading = false;

  final List<String> _goals = [
    'Build Muscle',
    'Lose Fat',
    'Improve Strength',
    'Maintain Fitness',
    'General Fitness',
  ];

  final List<String> _weekDays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun'
  ];

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _targetWeightController.dispose();
    super.dispose();
  }

  String _getReminderPeriodLabel(String timeStr) {
    try {
      final parts = timeStr.split(':');
      final hour = int.parse(parts[0]);
      if (hour < 12) return 'Morning Check-In';
      if (hour < 17) return 'Afternoon Check-In';
      return 'Evening Check-In';
    } catch (_) {
      return 'Daily Check-In';
    }
  }

  Future<void> _pickReminderTime(BuildContext context) async {
    int initialHour = 18;
    int initialMinute = 30;
    try {
      final parts = _reminderTime.split(':');
      initialHour = int.parse(parts[0]);
      initialMinute = int.parse(parts[1]);
    } catch (_) {}

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initialHour, minute: initialMinute),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
            dialogTheme:
                const DialogThemeData(backgroundColor: AppColors.surface),
            timePickerTheme: const TimePickerThemeData(
              backgroundColor: AppColors.surface,
              hourMinuteColor: AppColors.background,
              hourMinuteTextColor: AppColors.textPrimary,
              dayPeriodColor: AppColors.background,
              dayPeriodTextColor: AppColors.textPrimary,
              dialBackgroundColor: AppColors.background,
              dialHandColor: AppColors.primary,
              dialTextColor: AppColors.textPrimary,
              entryModeIconColor: AppColors.primary,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (picked != null) {
      final h = picked.hour.toString().padLeft(2, '0');
      final m = picked.minute.toString().padLeft(2, '0');
      setState(() {
        _reminderTime = '$h:$m';
      });
    }
  }

  Future<void> _completeOnboarding() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final repo = ref.read(authRepositoryProvider);
      final current = repo.currentUser;
      final base = current ??
          UserProfile(
            id: 'athlete-user',
            email: 'athlete@fittrack.local',
            name: 'Athlete',
            createdAt: DateTime.now(),
          );

      final updated = base.copyWith(
        goal: _selectedGoal,
        currentWeight: double.tryParse(_weightController.text) ?? 74.2,
        height: double.tryParse(_heightController.text) ?? 178.0,
        targetWeight: double.tryParse(_targetWeightController.text) ?? 78.0,
        preferredWorkoutDays: _selectedDays,
        reminderTime: _reminderTime,
        hasCompletedOnboarding: true,
      );
      await repo.updateProfile(updated);
    } catch (e) {
      debugPrint('Error completing onboarding: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        context.go('/home');
      }
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
                        color: index <= _currentStep
                            ? AppColors.primary
                            : AppColors.divider,
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
                        onPressed: _isLoading
                            ? null
                            : () => setState(() => _currentStep--),
                      ),
                    ),
                    const SizedBox(width: 14),
                  ],
                  Expanded(
                    flex: 2,
                    child: AppButton(
                      label: _currentStep == 2 ? 'Get Started' : 'Next',
                      isLoading: _isLoading,
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
          const Text('What is your primary goal?',
              style: AppTypography.displayMedium),
          const SizedBox(height: 8),
          const Text('FitTrack adjusts timeline insights to match your focus.',
              style: AppTypography.bodyMedium),
          const SizedBox(height: 28),
          ..._goals.map((goal) {
            final isSelected = _selectedGoal == goal;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppCard(
                onTap: () => setState(() => _selectedGoal = goal),
                style:
                    isSelected ? NeumorphicStyle.inset : NeumorphicStyle.raised,
                child: Row(
                  children: [
                    Icon(
                      isSelected
                          ? Icons.check_circle_rounded
                          : Icons.circle_outlined,
                      color:
                          isSelected ? AppColors.primary : AppColors.textMuted,
                      size: 22,
                    ),
                    const SizedBox(width: 14),
                    Text(
                      goal,
                      style: AppTypography.titleMedium.copyWith(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textPrimary,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
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
          const Text('Your Baseline', style: AppTypography.displayMedium),
          const SizedBox(height: 8),
          const Text('Record your initial metrics to benchmark progress.',
              style: AppTypography.bodyMedium),
          const SizedBox(height: 28),
          AppTextField(
            label: 'Current Weight (kg)',
            hint: '74.2',
            controller: _weightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            prefixIcon: const Icon(Icons.scale_rounded,
                color: AppColors.textMuted, size: 20),
          ),
          const SizedBox(height: 20),
          AppTextField(
            label: 'Target Weight (kg)',
            hint: '78.0',
            controller: _targetWeightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            prefixIcon: const Icon(Icons.flag_rounded,
                color: AppColors.textMuted, size: 20),
          ),
          const SizedBox(height: 20),
          AppTextField(
            label: 'Height (cm)',
            hint: '178',
            controller: _heightController,
            keyboardType: TextInputType.number,
            prefixIcon: const Icon(Icons.height_rounded,
                color: AppColors.textMuted, size: 20),
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
          const Text('Consistency Setup', style: AppTypography.displayMedium),
          const SizedBox(height: 8),
          const Text('Pick your active workout days & daily reminder time.',
              style: AppTypography.bodyMedium),
          const SizedBox(height: 28),
          const Text('Preferred Workout Days', style: AppTypography.labelMedium),
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
                child: NeumorphicContainer(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  borderRadius: 12,
                  style: isSelected
                      ? NeumorphicStyle.inset
                      : NeumorphicStyle.raised,
                  child: Text(
                    day,
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 28),
          const Text('Daily Reminder Time', style: AppTypography.labelMedium),
          const SizedBox(height: 12),
          AppCard(
            onTap: () => _pickReminderTime(context),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.notifications_active_rounded,
                        color: AppColors.primary),
                    const SizedBox(width: 12),
                    Text(_getReminderPeriodLabel(_reminderTime),
                        style: AppTypography.titleMedium),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      _reminderTime,
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.access_time_rounded,
                        size: 18, color: AppColors.textMuted),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
