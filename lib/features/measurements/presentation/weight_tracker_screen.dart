import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fittrack/app/theme/app_colors.dart';
import 'package:fittrack/app/theme/app_typography.dart';
import 'package:fittrack/core/utils/date_formatter.dart';
import 'package:fittrack/core/widgets/app_card.dart';
import 'package:fittrack/core/widgets/app_text_field.dart';
import 'package:fittrack/core/widgets/neumorphic_container.dart';
import 'package:fittrack/features/auth/data/auth_repository.dart';
import '../data/measurement_repository.dart';
import '../domain/measurement.dart';

class WeightTrackerScreen extends ConsumerStatefulWidget {
  const WeightTrackerScreen({super.key});

  @override
  ConsumerState<WeightTrackerScreen> createState() =>
      _WeightTrackerScreenState();
}

class _WeightTrackerScreenState extends ConsumerState<WeightTrackerScreen> {
  final _weightInputController = TextEditingController();

  void _showAddWeightDialog() {
    _weightInputController.clear();
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: NeumorphicContainer(
            padding: const EdgeInsets.all(24),
            borderRadius: 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Log Body Weight',
                    style: AppTypography.titleLarge,
                    textAlign: TextAlign.center),
                const SizedBox(height: 24),
                AppTextField(
                  label: 'Weight (kg)',
                  hint: '74.5',
                  controller: _weightInputController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  prefixIcon:
                      const Icon(Icons.scale_rounded, color: AppColors.primary),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          final weightVal =
                              double.tryParse(_weightInputController.text.trim());
                          if (weightVal == null ||
                              weightVal.isNaN ||
                              weightVal.isInfinite ||
                              weightVal <= 20.0 ||
                              weightVal >= 400.0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Please enter a valid weight between 20 and 400 kg'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                            return;
                          }
                          final user = ref.read(currentUserProfileProvider);
                          final repo = ref.read(measurementRepositoryProvider);
                          final authRepo = ref.read(authRepositoryProvider);

                            final newEntry = BodyMeasurement(
                              id: 'w-${DateTime.now().millisecondsSinceEpoch}',
                              userId: user?.id ?? '',
                              type: 'Weight',
                              value: weightVal,
                              unit: 'kg',
                              recordedAt: DateTime.now(),
                            );
                            await repo.saveMeasurement(newEntry);

                            if (user != null) {
                              await authRepo.updateProfile(
                                  user.copyWith(currentWeight: weightVal));
                            }
                            if (mounted) Navigator.pop(ctx);
                        },
                        child: const Text('Save',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
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
    final user = ref.watch(currentUserProfileProvider);
    final historyAsync =
        ref.watch(weightHistoryStreamProvider(user?.id ?? ''));

    final records = historyAsync.value ?? [];
    final startWeight =
        records.isNotEmpty ? records.last.value : (user?.currentWeight ?? 0.0);
    final currentWeight =
        user?.currentWeight ?? (records.isNotEmpty ? records.first.value : 0.0);
    final targetWeight = user?.targetWeight ?? 0.0;
    final delta = currentWeight - startWeight;
    final deltaStr = records.length >= 2
        ? '${delta >= 0 ? "+" : ""}${delta.toStringAsFixed(1)} kg overall'
        : (records.isNotEmpty ? 'Baseline recorded' : 'Start tracking');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weight Tracker'),
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
          child: NeumorphicContainer(
            borderRadius: 12,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: () => context.pop(),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            child: NeumorphicContainer(
              borderRadius: 12,
              child: IconButton(
                icon: const Icon(Icons.add_rounded,
                    color: AppColors.primary, size: 24),
                onPressed: _showAddWeightDialog,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Start / Current / Target Stat Cards
            Row(
              children: [
                Expanded(
                  child: NeumorphicContainer(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 16),
                    borderRadius: 16,
                    child: Column(
                      children: [
                        const Text('Start', style: AppTypography.bodySmall),
                        const SizedBox(height: 8),
                        Text(
                            startWeight > 0
                                ? startWeight.toStringAsFixed(1)
                                : '--',
                            style: AppTypography.titleMedium),
                        const Text('kg',
                            style: TextStyle(
                                fontSize: 11, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: NeumorphicContainer(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 16),
                    borderRadius: 16,
                    style: NeumorphicStyle.inset,
                    child: Column(
                      children: [
                        Text('Current',
                            style: AppTypography.bodySmall
                                .copyWith(color: AppColors.primary)),
                        const SizedBox(height: 8),
                        Text(
                            currentWeight > 0
                                ? currentWeight.toStringAsFixed(1)
                                : '--',
                            style: AppTypography.titleLarge
                                .copyWith(color: AppColors.primary)),
                        const Text('kg',
                            style: TextStyle(
                                fontSize: 11, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: NeumorphicContainer(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 16),
                    borderRadius: 16,
                    child: Column(
                      children: [
                        const Text('Target', style: AppTypography.bodySmall),
                        const SizedBox(height: 8),
                        Text(
                            targetWeight > 0
                                ? targetWeight.toStringAsFixed(1)
                                : '--',
                            style: AppTypography.titleMedium),
                        const Text('kg',
                            style: TextStyle(
                                fontSize: 11, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Weight Trend Chart
            AppCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Weight Trend', style: AppTypography.titleMedium),
                      NeumorphicContainer(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        style: NeumorphicStyle.inset,
                        borderRadius: 10,
                        child: Text(
                          deltaStr,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (records.isEmpty)
                    Container(
                      height: 140,
                      alignment: Alignment.center,
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.show_chart_rounded,
                              size: 36, color: AppColors.textMuted),
                          SizedBox(height: 8),
                          Text('No weigh-in logs yet.',
                              style: AppTypography.bodyMedium),
                          SizedBox(height: 4),
                          Text('Tap + above to record your current weight',
                              style: AppTypography.bodySmall),
                        ],
                      ),
                    )
                  else
                    SizedBox(
                      height: 190,
                      child: Builder(
                        builder: (context) {
                          final reversed = records.reversed.toList();
                          final spots = List.generate(
                            reversed.length,
                            (i) => FlSpot(i.toDouble(), reversed[i].value),
                          );
                          final weights = reversed.map((r) => r.value).toList();
                          final minW =
                              weights.reduce((a, b) => a < b ? a : b) - 2;
                          final maxW =
                              weights.reduce((a, b) => a > b ? a : b) + 2;

                          return LineChart(
                            LineChartData(
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                getDrawingHorizontalLine: (val) => const FlLine(
                                  color: AppColors.border,
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
                                      style: const TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 11),
                                    ),
                                  ),
                                ),
                                bottomTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false)),
                                topTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false)),
                              ),
                              borderData: FlBorderData(show: false),
                              minY: minW > 0 ? minW : 0,
                              maxY: maxW,
                              lineBarsData: [
                                LineChartBarData(
                                  spots: spots,
                                  isCurved: true,
                                  color: AppColors.primary,
                                  barWidth: 3,
                                  dotData: const FlDotData(show: true),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: AppColors.primary
                                        .withValues(alpha: 0.12),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // History Section
            const Text('Weigh-In History', style: AppTypography.labelLarge),
            const SizedBox(height: 16),
            historyAsync.when(
              data: (records) {
                return Column(
                  children: records.map((record) {
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
                                  child: Icon(Icons.scale_rounded,
                                      size: 20, color: AppColors.primary),
                                ),
                                const SizedBox(width: 16),
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
                              DateFormatter.formatTimelineDate(
                                  record.recordedAt),
                              style: AppTypography.labelMedium,
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
