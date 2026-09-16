import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fittrack/app/theme/app_colors.dart';
import 'package:fittrack/app/theme/app_typography.dart';
import 'package:fittrack/core/widgets/app_button.dart';
import 'package:fittrack/core/widgets/app_card.dart';
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
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Exported Personal Data', style: AppTypography.titleLarge),
        content: SingleChildScrollView(
          child: Text(
            exportedJson,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: AppColors.textSecondary),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete Account & Photos?'),
        content: const Text(
          'This action permanently purges your account, progress photos, workout logs, and weight history from Cloudflare D1 and R2 storage. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authRepositoryProvider).deleteAccount();
              if (context.mounted) {
                context.go('/login');
              }
            },
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User Header Card
            AppCard(
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(Icons.person_rounded, size: 34, color: Colors.black),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user?.name ?? 'Athlete', style: AppTypography.titleLarge),
                        const SizedBox(height: 2),
                        Text(user?.email ?? '', style: AppTypography.bodySmall),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            user?.goal ?? 'Build Muscle',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Physical Metrics Overview
            Row(
              children: [
                Expanded(
                  child: AppCard(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Text('Current', style: AppTypography.bodySmall),
                        const SizedBox(height: 4),
                        Text('${user?.currentWeight ?? 74.2} kg', style: AppTypography.titleMedium),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppCard(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Text('Target', style: AppTypography.bodySmall),
                        const SizedBox(height: 4),
                        Text('${user?.targetWeight ?? 78.0} kg', style: AppTypography.titleMedium),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppCard(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Text('Height', style: AppTypography.bodySmall),
                        const SizedBox(height: 4),
                        Text('${user?.height.toInt() ?? 178} cm', style: AppTypography.titleMedium),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Settings List
            Text('Account & Preferences', style: AppTypography.titleMedium),
            const SizedBox(height: 12),

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
            const SizedBox(height: 20),

            // Sign Out & Delete
            AppButton(
              label: 'Log Out',
              type: AppButtonType.outline,
              onPressed: () async {
                await ref.read(authRepositoryProvider).signOut();
                if (context.mounted) context.go('/login');
              },
            ),
            const SizedBox(height: 12),
            AppButton(
              label: 'Delete Account',
              type: AppButtonType.danger,
              onPressed: () => _confirmDeleteAccount(context, ref),
            ),
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
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.titleMedium.copyWith(fontSize: 15)),
                  Text(subtitle, style: AppTypography.bodySmall),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}
