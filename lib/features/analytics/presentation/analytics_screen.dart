import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fittrack/app/theme/app_colors.dart';
import 'package:fittrack/app/theme/app_typography.dart';
import 'package:fittrack/core/widgets/app_card.dart';
import 'package:fittrack/core/widgets/neumorphic_container.dart';
import 'package:fittrack/features/auth/data/auth_repository.dart';
import 'package:fittrack/features/workouts/data/workout_repository.dart';
import 'package:fittrack/core/utils/streak_calculator.dart';

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
    final userId = user?.id ?? '';
    final prsAsync = ref.watch(personalRecordsProvider(userId));
    final workoutsAsync = ref.watch(workoutsStreamProvider(userId));

    final workouts = workoutsAsync.value ?? [];
    final calculatedWorkoutStreak = StreakCalculator.calculateStreak(workouts.map((w) => w.date));
    final workoutStreak = calculatedWorkoutStreak > 0
        ? calculatedWorkoutStreak
        : (user?.workoutStreak ?? 0);
    final photoStreak = user?.photoStreak ?? 0;
    final totalDays = workoutStreak + photoStreak;
    final score = (totalDays * 10).clamp(0, 100);
    final tier =
        score >= 80 ? 'Elite' : (score >= 40 ? 'Consistent' : 'Building');

    // Filter workouts by selected range
    final now = DateTime.now();
    DateTime? cutoff;
    switch (_selectedRange) {
      case '7D':
        cutoff = now.subtract(const Duration(days: 7));
        break;
      case '30D':
        cutoff = now.subtract(const Duration(days: 30));
        break;
      case '3M':
        cutoff = now.subtract(const Duration(days: 90));
        break;
      case '6M':
        cutoff = now.subtract(const Duration(days: 180));
        break;
      case '1Y':
        cutoff = now.subtract(const Duration(days: 365));
        break;
      case 'ALL':
      default:
        cutoff = null;
        break;
    }

    final filteredWorkouts = cutoff == null
        ? workouts
        : workouts.where((w) => w.date.isAfter(cutoff!)).toList();

    final sortedWorkouts = List.of(filteredWorkouts)
      ..sort((a, b) => a.date.compareTo(b.date));

    double totalVol = 0;
    for (final w in sortedWorkouts) {
      totalVol += w.totalVolumeKg;
    }

    final displaySessions = sortedWorkouts.length > 7
        ? sortedWorkouts.sublist(sortedWorkouts.length - 7)
        : sortedWorkouts;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics & Records'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Time Range Filter Bar
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              child: Row(
                children: _ranges.map((range) {
                  final isSelected = _selectedRange == range;
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedRange = range),
                      child: NeumorphicContainer(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        borderRadius: 20,
                        style: isSelected
                            ? NeumorphicStyle.inset
                            : NeumorphicStyle.raised,
                        child: Text(
                          range,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 32),

            // Consistency Score Card
            NeumorphicContainer(
              padding: const EdgeInsets.all(24),
              borderRadius: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('CONSISTENCY SCORE',
                          style: AppTypography.labelMedium),
                      NeumorphicContainer(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        style: NeumorphicStyle.inset,
                        borderRadius: 12,
                        child: Text(
                          tier,
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text('$score',
                          style: AppTypography.displayLarge
                              .copyWith(color: AppColors.primary)),
                      Text(' / 100',
                          style: AppTypography.titleMedium
                              .copyWith(color: AppColors.textMuted)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildScoreBar('Workout Consistency',
                      (workoutStreak / 7).clamp(0.0, 1.0), AppColors.primary),
                  const SizedBox(height: 12),
                  _buildScoreBar('Photo Consistency',
                      (photoStreak / 7).clamp(0.0, 1.0), AppColors.primary),
                  const SizedBox(height: 12),
                  _buildScoreBar('Account Activity',
                      (score / 100).clamp(0.0, 1.0), AppColors.primary),
                  const SizedBox(height: 16),
                  const Text(
                    '* Motivational consistency index calculated from real workout and photo check-in streaks.',
                    style: AppTypography.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Weekly Volume Progression Chart
            Text(
              'Training Volume (${totalVol.toInt()} kg in $_selectedRange)',
              style: AppTypography.labelLarge,
            ),
            const SizedBox(height: 16),
            AppCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Volume recorded across ${displaySessions.length} session${displaySessions.length == 1 ? "" : "s"}',
                    style: AppTypography.bodySmall,
                  ),
                  const SizedBox(height: 20),
                  if (displaySessions.isEmpty)
                    Container(
                      height: 120,
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.fitness_center_rounded,
                              size: 32, color: AppColors.textMuted),
                          const SizedBox(height: 8),
                          Text('No workouts in $_selectedRange',
                              style: AppTypography.bodyMedium),
                          const SizedBox(height: 4),
                          const Text(
                              'Log a workout to see training volume progression',
                              style: AppTypography.bodySmall),
                        ],
                      ),
                    )
                  else
                    SizedBox(
                      height: 180,
                      child: BarChart(
                        BarChartData(
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            getDrawingHorizontalLine: (val) => const FlLine(
                              color: AppColors.border,
                              strokeWidth: 1,
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 42,
                                getTitlesWidget: (val, meta) => Text(
                                  val >= 1000 ? '${(val / 1000).toStringAsFixed(1)}k' : val.toInt().toString(),
                                  style: const TextStyle(
                                      color: AppColors.textMuted, fontSize: 10),
                                ),
                              ),
                            ),
                            rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (val, meta) {
                                  final idx = val.toInt();
                                  if (idx >= 0 && idx < displaySessions.length) {
                                    final date = displaySessions[idx].date;
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text(
                                        DateFormat('M/d').format(date),
                                        style: const TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            ),
                          ),
                          barGroups: displaySessions.asMap().entries.map((entry) {
                            final vol = entry.value.totalVolumeKg;
                            return _makeBarGroup(
                              entry.key,
                              vol > 0 ? vol : 10.0,
                              AppColors.primary,
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Personal Records
            const Text('Personal Records (PRs)', style: AppTypography.labelLarge),
            const SizedBox(height: 16),
            prsAsync.when(
              data: (prs) {
                if (prs.isEmpty) {
                  return const AppCard(
                    padding: EdgeInsets.all(20),
                    child: Text('Complete a workout to record strength PRs!',
                        style: AppTypography.bodyMedium),
                  );
                }

                return Column(
                  children: prs.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AppCard(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const NeumorphicContainer(
                                  shape: BoxShape.circle,
                                  padding: EdgeInsets.all(10),
                                  child: Icon(Icons.emoji_events_rounded,
                                      color: AppColors.primary, size: 20),
                                ),
                                const SizedBox(width: 16),
                                Text(entry.key,
                                    style: AppTypography.titleMedium),
                              ],
                            ),
                            NeumorphicContainer(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              style: NeumorphicStyle.inset,
                              borderRadius: 10,
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
            const SizedBox(height: 40),
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
        const SizedBox(height: 8),
        NeumorphicContainer(
          borderRadius: 8,
          style: NeumorphicStyle.inset,
          padding: EdgeInsets.zero,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: ratio,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
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
          color: color,
          width: 32,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
        ),
      ],
    );
  }
}
