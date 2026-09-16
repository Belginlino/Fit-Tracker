import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fittrack/app/theme/app_colors.dart';
import 'package:fittrack/app/theme/app_typography.dart';
import 'package:fittrack/core/widgets/app_card.dart';
import 'package:fittrack/features/auth/data/auth_repository.dart';
import 'package:fittrack/features/workouts/data/workout_repository.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  String _selectedRange = '30D';
  final List<String> _ranges = ['7D', '30D', '3M', '6M', '1Y', 'ALL'];

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProfileProvider);
    final prsAsync = ref.watch(personalRecordsProvider(user?.id ?? 'demo-user-101'));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics & Records'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Time Range Filter Bar (Section 21)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _ranges.map((range) {
                  final isSelected = _selectedRange == range;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedRange = range),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : AppColors.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.divider,
                          ),
                        ),
                        child: Text(
                          range,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? Colors.black : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),

            // Consistency Score Card (Section 22)
            AppCard(
              gradient: AppColors.cardGradient,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('CONSISTENCY SCORE', style: AppTypography.labelLarge.copyWith(letterSpacing: 1.0)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.accentLime.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Top 10%',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.accentLime),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text('88', style: AppTypography.displayLarge.copyWith(color: AppColors.accentLime)),
                      Text(' / 100', style: AppTypography.titleMedium.copyWith(color: AppColors.textMuted)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildScoreBar('Workout Consistency', 0.92, AppColors.accentOrange),
                  const SizedBox(height: 8),
                  _buildScoreBar('Photo Consistency', 0.85, AppColors.primary),
                  const SizedBox(height: 8),
                  _buildScoreBar('Weigh-In Regularity', 0.88, AppColors.accentLime),
                  const SizedBox(height: 14),
                  Text(
                    '* Motivational consistency index based on weekly activity regularity. Not a medical metric.',
                    style: AppTypography.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Weekly Volume Progression Chart
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Training Volume (kg lifted)', style: AppTypography.titleMedium),
                  const SizedBox(height: 4),
                  Text('Rolling progression across weeks', style: AppTypography.bodySmall),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 180,
                    child: BarChart(
                      BarChartData(
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (val, meta) {
                                switch (val.toInt()) {
                                  case 0:
                                    return const Text('W1', style: TextStyle(color: AppColors.textMuted, fontSize: 11));
                                  case 1:
                                    return const Text('W2', style: TextStyle(color: AppColors.textMuted, fontSize: 11));
                                  case 2:
                                    return const Text('W3', style: TextStyle(color: AppColors.textMuted, fontSize: 11));
                                  case 3:
                                    return const Text('W4', style: TextStyle(color: AppColors.textMuted, fontSize: 11));
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ),
                        ),
                        barGroups: [
                          _makeBarGroup(0, 12400, AppColors.surface),
                          _makeBarGroup(1, 14200, AppColors.surface),
                          _makeBarGroup(2, 16800, AppColors.surface),
                          _makeBarGroup(3, 18500, AppColors.primary),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Personal Records (Section 20)
            Text('Personal Records (PRs)', style: AppTypography.titleMedium),
            const SizedBox(height: 12),
            prsAsync.when(
              data: (prs) {
                if (prs.isEmpty) {
                  return AppCard(
                    child: Text('Complete a workout to record strength PRs!', style: AppTypography.bodyMedium),
                  );
                }

                return Column(
                  children: prs.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: AppCard(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.emoji_events_rounded, color: AppColors.accentAmber, size: 22),
                                const SizedBox(width: 12),
                                Text(entry.key, style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${entry.value} kg',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
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

  Widget _buildScoreBar(String label, double ratio, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTypography.bodySmall),
            Text('${(ratio * 100).toInt()}%', style: AppTypography.labelMedium),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            backgroundColor: AppColors.surface,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  BarChartGroupData _makeBarGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color == AppColors.primary ? AppColors.primary : AppColors.cardElevated,
          width: 28,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
        ),
      ],
    );
  }
}
