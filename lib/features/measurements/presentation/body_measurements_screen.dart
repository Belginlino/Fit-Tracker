import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fittrack/app/theme/app_colors.dart';
import 'package:fittrack/app/theme/app_typography.dart';
import 'package:fittrack/core/constants/app_constants.dart';
import 'package:fittrack/core/utils/date_formatter.dart';
import 'package:fittrack/core/widgets/app_card.dart';
import 'package:fittrack/core/widgets/app_text_field.dart';
import 'package:fittrack/features/auth/data/auth_repository.dart';
import '../data/measurement_repository.dart';
import '../domain/measurement.dart';

class BodyMeasurementsScreen extends ConsumerStatefulWidget {
  const BodyMeasurementsScreen({super.key});

  @override
  ConsumerState<BodyMeasurementsScreen> createState() => _BodyMeasurementsScreenState();
}

class _BodyMeasurementsScreenState extends ConsumerState<BodyMeasurementsScreen> {
  final _valueController = TextEditingController();
  String _selectedPart = 'Chest';

  void _showAddMeasurementModal() {
    _valueController.clear();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Log Body Circumference', style: AppTypography.titleLarge),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedPart,
                    dropdownColor: AppColors.card,
                    decoration: const InputDecoration(labelText: 'Body Part'),
                    items: AppConstants.measurementTypes
                        .where((t) => t != 'Weight')
                        .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => _selectedPart = val);
                    },
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Measurement Value (cm)',
                    hint: '104.5',
                    controller: _valueController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    prefixIcon: const Icon(Icons.straighten_rounded, color: AppColors.primary),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () async {
                      final val = double.tryParse(_valueController.text);
                      if (val != null) {
                        final user = ref.read(currentUserProfileProvider);
                        final repo = ref.read(measurementRepositoryProvider);
                        await repo.saveMeasurement(
                          BodyMeasurement(
                            id: 'bm-${DateTime.now().millisecondsSinceEpoch}',
                            userId: user?.id ?? 'demo-user-101',
                            type: _selectedPart,
                            value: val,
                            unit: 'cm',
                            recordedAt: DateTime.now(),
                          ),
                        );
                        if (mounted) Navigator.pop(ctx);
                      }
                    },
                    child: const Text('Save Measurement'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProfileProvider);
    final measurementsAsync = ref.watch(bodyCircumferenceStreamProvider(user?.id ?? 'demo-user-101'));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Body Measurements'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.primary, size: 28),
            onPressed: _showAddMeasurementModal,
          ),
        ],
      ),
      body: measurementsAsync.when(
        data: (allRecords) {
          final bodyRecords = allRecords.where((r) => r.type != 'Weight').toList();

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              Text(
                'Track body circumference to measure muscular development independent of scale weight.',
                style: AppTypography.bodyMedium,
              ),
              const SizedBox(height: 20),

              ...bodyRecords.map((m) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AppCard(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.straighten_rounded, color: AppColors.primary, size: 20),
                            ),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(m.type, style: AppTypography.titleMedium),
                                Text(
                                  DateFormatter.formatTimelineDate(m.recordedAt),
                                  style: AppTypography.bodySmall,
                                ),
                              ],
                            ),
                          ],
                        ),
                        Text(
                          '${m.value} ${m.unit}',
                          style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
