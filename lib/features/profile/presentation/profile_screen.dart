import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fittrack/app/theme/app_colors.dart';
import 'package:fittrack/app/theme/app_typography.dart';
import 'package:fittrack/core/widgets/app_button.dart';
import 'package:fittrack/core/widgets/app_card.dart';
import 'package:fittrack/core/widgets/app_text_field.dart';
import 'package:fittrack/core/widgets/neumorphic_container.dart';
import 'package:fittrack/features/auth/data/auth_repository.dart';
import 'package:fittrack/features/auth/domain/user_model.dart';
import 'package:fittrack/features/measurements/data/measurement_repository.dart';
import 'package:fittrack/features/measurements/domain/measurement.dart';
import 'package:fittrack/core/services/pin_service.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _managePinDialog(BuildContext context, WidgetRef ref) async {
    final pinState = ref.read(pinServiceProvider);
    final pinNotifier = ref.read(pinServiceProvider.notifier);

    if (pinState.isPinEnabled) {
      // Option to disable or change PIN
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.cardBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('PIN Security Settings'),
          content: const Text(
              'PIN protection is currently enabled on this device.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                await pinNotifier.disablePin();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('PIN protection disabled.'),
                      backgroundColor: AppColors.textSecondary,
                    ),
                  );
                }
              },
              child: const Text('Disable PIN',
                  style: TextStyle(color: AppColors.error)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                _promptSetPin(context, ref);
              },
              child: const Text('Change PIN'),
            ),
          ],
        ),
      );
    } else {
      _promptSetPin(context, ref);
    }
  }

  Future<void> _promptSetPin(BuildContext context, WidgetRef ref) async {
    final pinNotifier = ref.read(pinServiceProvider.notifier);
    final pinController = TextEditingController();
    final confirmController = TextEditingController();
    String? pinError;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.cardBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.shield_outlined, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Set 4-Digit PIN', style: TextStyle(fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter a 4-digit security PIN to protect your app.',
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Enter 4-digit PIN',
                hint: '••••',
                controller: pinController,
                keyboardType: TextInputType.number,
                isPassword: true,
                maxLength: 4,
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Confirm PIN',
                hint: '••••',
                controller: confirmController,
                keyboardType: TextInputType.number,
                isPassword: true,
                maxLength: 4,
              ),
              if (pinError != null) ...[
                const SizedBox(height: 8),
                Text(
                  pinError!,
                  style: const TextStyle(color: AppColors.error, fontSize: 12),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                final pin = pinController.text.trim();
                final confirm = confirmController.text.trim();
                if (pin.length != 4 || int.tryParse(pin) == null) {
                  setDialogState(() => pinError = 'PIN must be exactly 4 digits');
                  return;
                }
                if (pin != confirm) {
                  setDialogState(() => pinError = 'PINs do not match');
                  return;
                }

                await pinNotifier.enablePin(pin);
                if (ctx.mounted) Navigator.of(ctx).pop();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('PIN protection enabled! ✓'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              },
              child: const Text('Save PIN'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editSingleMetric(
    BuildContext context,
    WidgetRef ref,
    UserProfile? user, {
    required String title,
    required double currentVal,
    required String unit,
    required double minVal,
    required double maxVal,
    required Future<void> Function(double newVal) onSaved,
  }) async {
    final controller = TextEditingController(
      text: currentVal.truncateToDouble() == currentVal
          ? currentVal.toInt().toString()
          : currentVal.toString(),
    );
    String? errorText;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.cardBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.edit_note_rounded, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('Edit $title', style: const TextStyle(fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Enter your updated $title ($unit):',
                  style: AppTypography.bodySmall),
              const SizedBox(height: 16),
              AppTextField(
                label: '$title ($unit)',
                hint: currentVal.toString(),
                controller: controller,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              if (errorText != null) ...[
                const SizedBox(height: 8),
                Text(errorText!,
                    style:
                        const TextStyle(color: AppColors.error, fontSize: 12)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                final text = controller.text.trim();
                final val = double.tryParse(text);
                if (val == null || val.isNaN || val < minVal || val > maxVal) {
                  setDialogState(() {
                    errorText =
                        'Please enter a value between $minVal and $maxVal $unit';
                  });
                  return;
                }

                await onSaved(val);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$title updated to $val $unit ✓'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProfileModal(
      BuildContext context, WidgetRef ref, UserProfile? user) {
    final nameController = TextEditingController(text: user?.name ?? '');
    final currentWeightController = TextEditingController(
        text: (user?.currentWeight ?? 74.2).toString());
    final targetWeightController = TextEditingController(
        text: (user?.targetWeight ?? 78.0).toString());
    final heightController = TextEditingController(
        text: (user?.height.toInt() ?? 178).toString());

    String selectedGoal = user?.goal ?? 'Build Muscle';
    final goals = [
      'Build Muscle',
      'Lose Fat',
      'Improve Strength',
      'Endurance',
      'Tone & Maintain',
    ];

    final List<String> selectedDays = List.from(
        user?.preferredWorkoutDays ?? ['Mon', 'Tue', 'Thu', 'Fri']);
    final allDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    String? errorMessage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            top: 20,
            left: 24,
            right: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
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
                const Text('Edit Profile & Goals',
                    style: AppTypography.titleLarge,
                    textAlign: TextAlign.center),
                const SizedBox(height: 20),

                // Name field
                AppTextField(
                  label: 'Full Name',
                  hint: 'Enter your name',
                  controller: nameController,
                ),
                const SizedBox(height: 16),

                // Goal selection
                const Text('Fitness Goal', style: AppTypography.labelLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: goals.map((g) {
                    final isSelected = selectedGoal == g;
                    return GestureDetector(
                      onTap: () => setModalState(() => selectedGoal = g),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.divider,
                          ),
                        ),
                        child: Text(
                          g,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Physical metrics row
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        label: 'Current (kg)',
                        hint: '74.2',
                        controller: currentWeightController,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppTextField(
                        label: 'Target (kg)',
                        hint: '78.0',
                        controller: targetWeightController,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppTextField(
                        label: 'Height (cm)',
                        hint: '178',
                        controller: heightController,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Preferred Workout Days
                const Text('Target Workout Days',
                    style: AppTypography.labelLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: allDays.map((day) {
                    final isSelected = selectedDays.contains(day);
                    return FilterChip(
                      label: Text(day),
                      selected: isSelected,
                      selectedColor: AppColors.primary.withOpacity(0.2),
                      checkmarkColor: AppColors.primary,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.normal,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                      onSelected: (selected) {
                        setModalState(() {
                          if (selected) {
                            selectedDays.add(day);
                          } else {
                            selectedDays.remove(day);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),

                if (errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    errorMessage!,
                    style: const TextStyle(
                        color: AppColors.error, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],

                const SizedBox(height: 24),
                AppButton(
                  label: 'Save Changes',
                  onPressed: () async {
                    final name = nameController.text.trim();
                    final currentW =
                        double.tryParse(currentWeightController.text.trim());
                    final targetW =
                        double.tryParse(targetWeightController.text.trim());
                    final height =
                        double.tryParse(heightController.text.trim());

                    if (name.isEmpty) {
                      setModalState(
                          () => errorMessage = 'Name cannot be empty');
                      return;
                    }
                    if (currentW == null || currentW < 20 || currentW > 400) {
                      setModalState(() => errorMessage =
                          'Current weight must be between 20 and 400 kg');
                      return;
                    }
                    if (targetW == null || targetW < 20 || targetW > 400) {
                      setModalState(() => errorMessage =
                          'Target weight must be between 20 and 400 kg');
                      return;
                    }
                    if (height == null || height < 50 || height > 300) {
                      setModalState(() => errorMessage =
                          'Height must be between 50 and 300 cm');
                      return;
                    }

                    final updated = (user ??
                            UserProfile(
                              id: '',
                              email: '',
                              name: name,
                              createdAt: DateTime.now(),
                            ))
                        .copyWith(
                      name: name,
                      goal: selectedGoal,
                      currentWeight: currentW,
                      targetWeight: targetW,
                      height: height,
                      preferredWorkoutDays: selectedDays,
                    );

                    await ref
                        .read(authRepositoryProvider)
                        .updateProfile(updated);
                    ref.read(currentUserProfileProvider.notifier).state =
                        updated;

                    // If current weight changed, record measurement log
                    if (user != null &&
                        user.id.isNotEmpty &&
                        currentW != user.currentWeight) {
                      try {
                        await ref
                            .read(measurementRepositoryProvider)
                            .saveMeasurement(BodyMeasurement(
                              id: 'w-${DateTime.now().millisecondsSinceEpoch}',
                              userId: user.id,
                              type: 'Weight',
                              value: currentW,
                              unit: 'kg',
                              recordedAt: DateTime.now(),
                            ));
                      } catch (_) {}
                    }

                    if (ctx.mounted) Navigator.pop(ctx);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Profile updated successfully! ✓'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickReminderTime(
      BuildContext context, WidgetRef ref, UserProfile? user) async {
    final currentStr = user?.reminderTime ?? '18:30';
    final parts = currentStr.split(':');
    final initialHour = parts.isNotEmpty ? (int.tryParse(parts[0]) ?? 18) : 18;
    final initialMinute =
        parts.length > 1 ? (int.tryParse(parts[1]) ?? 30) : 30;

    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initialHour, minute: initialMinute),
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.cardBackground,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && user != null) {
      final hourStr = picked.hour.toString().padLeft(2, '0');
      final minuteStr = picked.minute.toString().padLeft(2, '0');
      final newTime = '$hourStr:$minuteStr';

      final updated = user.copyWith(reminderTime: newTime);
      await ref.read(authRepositoryProvider).updateProfile(updated);
      ref.read(currentUserProfileProvider.notifier).state = updated;

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Daily check-in reminder set to $newTime ✓'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  void _showPrivacyInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.shield_outlined, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Photo Privacy & Vault', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your physique and progress photos are stored in an encrypted private vault.',
              style: AppTypography.bodyMedium,
            ),
            SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check_circle_rounded,
                    color: AppColors.success, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Zero-trust access permissions: Only your authenticated user session can read or view your photos.',
                    style: AppTypography.bodySmall,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check_circle_rounded,
                    color: AppColors.success, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Isolated Appwrite Storage bucket with file-level security enforced.',
                    style: AppTypography.bodySmall,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check_circle_rounded,
                    color: AppColors.success, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Photos are never made public or accessible without direct session credentials.',
                    style: AppTypography.bodySmall,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _exportUserData(BuildContext context, dynamic user) {
    final exportedJson = const JsonEncoder.withIndent('  ').convert({
      'exportDate': DateTime.now().toIso8601String(),
      'profile': user?.toMap(),
    });

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: NeumorphicContainer(
          padding: const EdgeInsets.all(24),
          borderRadius: 24,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Exported Personal Data',
                  style: AppTypography.titleLarge, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              SizedBox(
                height: 200,
                child: SingleChildScrollView(
                  child: Text(
                    exportedJson,
                    style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: AppColors.textSecondary),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              AppButton(
                label: 'Done',
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: NeumorphicContainer(
          padding: const EdgeInsets.all(24),
          borderRadius: 24,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Delete Account & Photos?',
                  style: AppTypography.titleLarge, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              const Text(
                'This action permanently purges your account, progress photos, workout logs, and weight history from Appwrite Cloud database and storage. This cannot be undone.',
                style: AppTypography.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel',
                          style: TextStyle(color: AppColors.textMuted)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AppButton(
                      label: 'Delete',
                      type: AppButtonType.danger,
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await ref.read(authRepositoryProvider).deleteAccount();
                        if (context.mounted) {
                          context.go('/login');
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Settings'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Profile & Goals',
            onPressed: () => _showEditProfileModal(context, ref, user),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User Header Card
            NeumorphicContainer(
              padding: const EdgeInsets.all(24),
              borderRadius: 24,
              child: Row(
                children: [
                  const NeumorphicContainer(
                    width: 64,
                    height: 64,
                    shape: BoxShape.circle,
                    padding: EdgeInsets.all(12),
                    style: NeumorphicStyle.inset,
                    child: Icon(Icons.person_rounded,
                        size: 36, color: AppColors.primary),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (user?.name != null && user!.name.isNotEmpty)
                              ? user.name
                              : (user?.email != null && user!.email.isNotEmpty)
                                  ? user.email.split('@').first
                                  : 'Champion',
                          style: AppTypography.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(user?.email ?? '',
                            style: AppTypography.bodyMedium),
                        const SizedBox(height: 8),
                        NeumorphicContainer(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          borderRadius: 8,
                          style: NeumorphicStyle.inset,
                          child: Text(
                            user?.goal ?? 'Build Muscle',
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined,
                        color: AppColors.primary, size: 22),
                    tooltip: 'Edit Profile',
                    onPressed: () => _showEditProfileModal(context, ref, user),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Physical Metrics Overview (Interactive Cards with tap-to-edit)
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _editSingleMetric(
                      context,
                      ref,
                      user,
                      title: 'Current Weight',
                      currentVal: user?.currentWeight ?? 74.2,
                      unit: 'kg',
                      minVal: 20.0,
                      maxVal: 400.0,
                      onSaved: (val) async {
                        final updated = (user ??
                                UserProfile(
                                  id: '',
                                  email: '',
                                  name: 'Champion',
                                  createdAt: DateTime.now(),
                                ))
                            .copyWith(currentWeight: val);
                        await ref
                            .read(authRepositoryProvider)
                            .updateProfile(updated);
                        ref.read(currentUserProfileProvider.notifier).state =
                            updated;

                        if (user != null && user.id.isNotEmpty) {
                          try {
                            await ref
                                .read(measurementRepositoryProvider)
                                .saveMeasurement(BodyMeasurement(
                                  id: 'w-${DateTime.now().millisecondsSinceEpoch}',
                                  userId: user.id,
                                  type: 'Weight',
                                  value: val,
                                  unit: 'kg',
                                  recordedAt: DateTime.now(),
                                ));
                          } catch (_) {}
                        }
                      },
                    ),
                    child: NeumorphicContainer(
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 12),
                      borderRadius: 16,
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Current',
                                  style: AppTypography.bodySmall),
                              const SizedBox(width: 4),
                              Icon(Icons.edit_outlined,
                                  size: 13,
                                  color: AppColors.textMuted.withOpacity(0.8)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('${user?.currentWeight ?? 74.2} kg',
                              style: AppTypography.titleMedium),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _editSingleMetric(
                      context,
                      ref,
                      user,
                      title: 'Target Weight',
                      currentVal: user?.targetWeight ?? 78.0,
                      unit: 'kg',
                      minVal: 20.0,
                      maxVal: 400.0,
                      onSaved: (val) async {
                        final updated = (user ??
                                UserProfile(
                                  id: '',
                                  email: '',
                                  name: 'Champion',
                                  createdAt: DateTime.now(),
                                ))
                            .copyWith(targetWeight: val);
                        await ref
                            .read(authRepositoryProvider)
                            .updateProfile(updated);
                        ref.read(currentUserProfileProvider.notifier).state =
                            updated;
                      },
                    ),
                    child: NeumorphicContainer(
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 12),
                      borderRadius: 16,
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Target',
                                  style: AppTypography.bodySmall),
                              const SizedBox(width: 4),
                              Icon(Icons.edit_outlined,
                                  size: 13,
                                  color: AppColors.textMuted.withOpacity(0.8)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('${user?.targetWeight ?? 78.0} kg',
                              style: AppTypography.titleMedium),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _editSingleMetric(
                      context,
                      ref,
                      user,
                      title: 'Height',
                      currentVal: user?.height ?? 178.0,
                      unit: 'cm',
                      minVal: 50.0,
                      maxVal: 300.0,
                      onSaved: (val) async {
                        final updated = (user ??
                                UserProfile(
                                  id: '',
                                  email: '',
                                  name: 'Champion',
                                  createdAt: DateTime.now(),
                                ))
                            .copyWith(height: val);
                        await ref
                            .read(authRepositoryProvider)
                            .updateProfile(updated);
                        ref.read(currentUserProfileProvider.notifier).state =
                            updated;
                      },
                    ),
                    child: NeumorphicContainer(
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 12),
                      borderRadius: 16,
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Height',
                                  style: AppTypography.bodySmall),
                              const SizedBox(width: 4),
                              Icon(Icons.edit_outlined,
                                  size: 13,
                                  color: AppColors.textMuted.withOpacity(0.8)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('${user?.height.toInt() ?? 178} cm',
                              style: AppTypography.titleMedium),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),

            // Settings List
            const Text('Account & Preferences',
                style: AppTypography.labelLarge),
            const SizedBox(height: 16),

            _buildSettingTile(
              icon: Icons.tune_rounded,
              title: 'Edit Profile & Fitness Goals',
              subtitle: 'Update your name, target weight, height, and fitness goals',
              onTap: () => _showEditProfileModal(context, ref, user),
            ),
            Consumer(
              builder: (context, ref, child) {
                final pinState = ref.watch(pinServiceProvider);
                return _buildSettingTile(
                  icon: Icons.shield_outlined,
                  title: 'PIN Protection Lock',
                  subtitle: pinState.isPinEnabled
                      ? 'Enabled • 4-digit PIN active on this device'
                      : 'Disabled • Tap to setup PIN lock',
                  onTap: () => _managePinDialog(context, ref),
                );
              },
            ),
            _buildSettingTile(
              icon: Icons.scale_rounded,
              title: 'Body Circumference Measurements',
              subtitle: 'Track chest, waist, and arms',
              onTap: () => context.push('/measurements/body'),
            ),
            _buildSettingTile(
              icon: Icons.notifications_none_rounded,
              title: 'Notifications & Reminders',
              subtitle: 'Daily check-in at ${user?.reminderTime ?? "18:30"} (Tap to change)',
              onTap: () => _pickReminderTime(context, ref, user),
            ),
            _buildSettingTile(
              icon: Icons.lock_outline_rounded,
              title: 'Photo Privacy & Storage',
              subtitle: 'Private zero-trust Appwrite vault',
              onTap: () => _showPrivacyInfoDialog(context),
            ),
            _buildSettingTile(
              icon: Icons.file_download_outlined,
              title: 'Export Personal Data (JSON)',
              subtitle: 'Download structured records',
              onTap: () => _exportUserData(context, user),
            ),
            const SizedBox(height: 32),

            // Sign Out & Delete
            AppButton(
              label: 'Log Out',
              type: AppButtonType.outline,
              onPressed: () async {
                await ref.read(authRepositoryProvider).signOut();
                if (context.mounted) context.go('/login');
              },
            ),
            const SizedBox(height: 16),
            AppButton(
              label: 'Delete Account',
              type: AppButtonType.danger,
              onPressed: () => _confirmDeleteAccount(context, ref),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            NeumorphicContainer(
              shape: BoxShape.circle,
              padding: const EdgeInsets.all(10),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppTypography.titleMedium.copyWith(fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: AppTypography.bodySmall),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}
