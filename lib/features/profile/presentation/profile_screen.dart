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
                'This action permanently purges your account, progress photos, workout logs, and weight history from Cloudflare D1 and R2 storage. This cannot be undone.',
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
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Physical Metrics Overview
            Row(
              children: [
                Expanded(
                  child: NeumorphicContainer(
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 12),
                    borderRadius: 16,
                    child: Column(
                      children: [
                        const Text('Current', style: AppTypography.bodySmall),
                        const SizedBox(height: 8),
                        Text('${user?.currentWeight ?? 74.2} kg',
                            style: AppTypography.titleMedium),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: NeumorphicContainer(
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 12),
                    borderRadius: 16,
                    child: Column(
                      children: [
                        const Text('Target', style: AppTypography.bodySmall),
                        const SizedBox(height: 8),
                        Text('${user?.targetWeight ?? 78.0} kg',
                            style: AppTypography.titleMedium),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: NeumorphicContainer(
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 12),
                    borderRadius: 16,
                    child: Column(
                      children: [
                        const Text('Height', style: AppTypography.bodySmall),
                        const SizedBox(height: 8),
                        Text('${user?.height.toInt() ?? 178} cm',
                            style: AppTypography.titleMedium),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),

            // Settings List
            const Text('Account & Preferences', style: AppTypography.labelLarge),
            const SizedBox(height: 16),

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
              subtitle: 'Daily check-in at ${user?.reminderTime ?? "18:30"}',
              onTap: () {},
            ),
            _buildSettingTile(
              icon: Icons.lock_outline_rounded,
              title: 'Photo Privacy & Storage',
              subtitle: 'Private user-isolated Cloudflare R2 vault',
              onTap: () {},
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
