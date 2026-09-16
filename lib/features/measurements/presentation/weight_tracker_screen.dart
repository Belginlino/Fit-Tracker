import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fittrack/app/theme/app_colors.dart';
import 'package:fittrack/app/theme/app_typography.dart';
import 'package:fittrack/core/utils/date_formatter.dart';
import 'package:fittrack/core/widgets/app_button.dart';
import 'package:fittrack/core/widgets/app_card.dart';
import 'package:fittrack/core/widgets/app_text_field.dart';
import 'package:fittrack/features/auth/data/auth_repository.dart';
import '../data/measurement_repository.dart';
import '../domain/measurement.dart';

class WeightTrackerScreen extends ConsumerStatefulWidget {
  const WeightTrackerScreen({super.key});

  @override
  ConsumerState<WeightTrackerScreen> createState() => _WeightTrackerScreenState();
}

class _WeightTrackerScreenState extends ConsumerState<WeightTrackerScreen> {
  final _weightInputController = TextEditingController();

  void _showAddWeightDialog() {
    _weightInputController.clear();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Log Body Weight', style: AppTypography.titleLarge),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                label: 'Weight (kg)',
                hint: '74.5',
                controller: _weightInputController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                prefixIcon: const Icon(Icons.scale_rounded, color: AppColors.primary),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.black),
              onPressed: () async {
                final weightVal = double.tryParse(_weightInputController.text);
                if (weightVal != null) {
                  final user = ref.read(currentUserProfileProvider);
                  final repo = ref.read(measurementRepositoryProvider);
                  final authRepo = ref.read(authRepositoryProvider);

                  final newEntry = BodyMeasurement(
                    id: 'w-${DateTime.now().millisecondsSinceEpoch}',
                    userId: user?.id ?? 'demo-user-101',
                    type: 'Weight',
                    value: weightVal,
                    unit: 'kg',
                    recordedAt: DateTime.now(),
                  );
                  await repo.saveMeasurement(newEntry);

                  if (user != null) {
                    await authRepo.updateProfile(user.copyWith(currentWeight: weightVal));
                  }
                  if (mounted) Navigator.pop(ctx);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProfileProvider);
    final historyAsync = ref.watch(weightHistoryStreamProvider(user?.id ?? 'demo-user-101'));

    final startWeight = 71.0;
    final currentWeight = user?.currentWeight ?? 74.2;
    final targetWeight = user?.targetWeight ?? 78.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weight Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.primary, size: 28),
            onPressed: _showAddWeightDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Start / Current / Target Stat Cards
            Row(
              children: [
                Expanded(
                  child: AppCard(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    child: Column(
                      children: [
                        Text('Start', style: AppTypography.bodySmall),
                        const SizedBox(height: 4),
                        Text('$startWeight', style: AppTypography.titleMedium),
                        Text('kg', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppCard(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    border: Border.all(color: AppColors.primary, width: 1.5),
                    child: Column(
                      children: [
                        Text('Current', style: AppTypography.bodySmall.copyWith(color: AppColors.primary)),
                        const SizedBox(height: 4),
                        Text('$currentWeight', style: AppTypography.titleLarge.copyWith(color: AppColors.primary)),
                        Text('kg', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppCard(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    child: Column(
                      children: [
                        Text('Target', style: AppTypography.bodySmall),
                        const SizedBox(height: 4),
                        Text('$targetWeight', style: AppTypography.titleMedium),
                        Text('kg', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Weight Trend Chart (fl_chart)
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Weight Trend', style: AppTypography.titleMedium),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.accentLime.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '+3.2 kg overall',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.accentLime),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 190,
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (val) => FlLine(
                            color: AppColors.divider,
                            strokeWidth: 1,
                          ),
                        ),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 34,
                              getTitlesWidget: (val, meta) => Text(
                                '${val.toInt()}',
                                style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                              ),
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 22,
                              getTitlesWidget: (val, meta) {
                                switch (val.toInt()) {
                                  case 0:
                                    return const Text('Day 1', style: TextStyle(color: AppColors.textMuted, fontSize: 10));
                                  case 1:
                                    return const Text('Day 10', style: TextStyle(color: AppColors.textMuted, fontSize: 10));
                                  case 2:
                                    return const Text('Day 20', style: TextStyle(color: AppColors.textMuted, fontSize: 10));
                                  case 3:
                                    return const Text('Today', style: TextStyle(color: AppColors.textMuted, fontSize: 10));
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: false),
                        minY: 69,
                        maxY: 77,
                        lineBarsData: [
                          LineChartBarData(
                            spots: const [
                              FlSpot(0, 71.0),
                              FlSpot(1, 72.4),
                              FlSpot(2, 73.1),
                              FlSpot(3, 74.2),
                            ],
                            isCurved: true,
                            color: AppColors.primary,
                            barWidth: 3,
                            dotData: const FlDotData(show: true),
                            belowBarData: BarAreaData(
                              show: true,
                              color: AppColors.primary.withOpacity(0.12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // History Section
            Text('Weigh-In History', style: AppTypography.titleMedium),
            const SizedBox(height: 12),
            historyAsync.when(
              data: (records) {
                return Column(
                  children: records.map((record) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: AppCard(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.scale_rounded, size: 20, color: AppColors.primary),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${record.value} kg',
                                      style: AppTypography.titleMedium,
                                    ),
                                    if (record.note != null)
                                      Text(
                                        record.note!,
                                        style: AppTypography.bodySmall,
                                      ),
                                  ],
                                ),
                              ],
                            ),
                            Text(
                              DateFormatter.formatTimelineDate(record.recordedAt),
                              style: AppTypography.bodySmall,
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
}
