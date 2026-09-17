import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fittrack/app/theme/app_colors.dart';
import 'package:fittrack/app/theme/app_typography.dart';
import 'package:fittrack/core/widgets/app_button.dart';
import 'package:fittrack/core/widgets/app_card.dart';
import 'package:fittrack/core/widgets/neumorphic_container.dart';
import 'package:fittrack/features/auth/data/auth_repository.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

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
                        Text(user?.name ?? 'Athlete',
                            style: AppTypography.titleLarge),
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
