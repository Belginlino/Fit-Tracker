import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fittrack/app/theme/app_colors.dart';
import 'package:fittrack/app/theme/app_typography.dart';
import 'package:fittrack/core/constants/app_constants.dart';
import 'package:fittrack/core/utils/date_formatter.dart';
import 'package:fittrack/core/widgets/app_button.dart';
import 'package:fittrack/core/widgets/app_card.dart';
import 'package:fittrack/core/widgets/app_text_field.dart';
import 'package:fittrack/core/widgets/neumorphic_container.dart';
import 'package:fittrack/features/auth/data/auth_repository.dart';
import '../data/measurement_repository.dart';
import '../domain/measurement.dart';

class BodyMeasurementsScreen extends ConsumerStatefulWidget {
  const BodyMeasurementsScreen({super.key});

  @override
  ConsumerState<BodyMeasurementsScreen> createState() =>
      _BodyMeasurementsScreenState();
}

class _BodyMeasurementsScreenState
    extends ConsumerState<BodyMeasurementsScreen> {
  final _valueController = TextEditingController();
  String _selectedPart = 'Chest';

  void _showAddMeasurementModal() {
    _valueController.clear();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: NeumorphicContainer(
                borderRadius: 24,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Log Body Measurement',
                        style: AppTypography.titleLarge,
                        textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    const Text('Body Part', style: AppTypography.labelLarge),
                    const SizedBox(height: 12),
                    NeumorphicContainer(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      borderRadius: 12,
                      style: NeumorphicStyle.inset,
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedPart,
                          dropdownColor: AppColors.surface,
                          icon: const Icon(Icons.arrow_drop_down_rounded,
                              color: AppColors.primary),
                          isExpanded: true,
                          items: AppConstants.measurementTypes
                              .where((t) => t != 'Weight')
                              .map((type) => DropdownMenuItem(
                                  value: type, child: Text(type)))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() => _selectedPart = val);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    AppTextField(
                      label: 'Value (cm)',
                      hint: '104.5',
                      controller: _valueController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      prefixIcon: const Icon(Icons.straighten_rounded,
                          color: AppColors.primary),
                    ),
                    const SizedBox(height: 32),
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
                            label: 'Save',
                            onPressed: () async {
                              final val =
                                  double.tryParse(_valueController.text.trim());
                              if (val == null ||
                                  val.isNaN ||
                                  val.isInfinite ||
                                  val <= 5.0 ||
                                  val >= 300.0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Please enter a valid circumference between 5 and 300 cm'),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                                return;
                              }
                              final user =
                                  ref.read(currentUserProfileProvider);
                              final repo =
                                  ref.read(measurementRepositoryProvider);
                              await repo.saveMeasurement(
                                BodyMeasurement(
                                  id: 'bm-${DateTime.now().millisecondsSinceEpoch}',
                                  userId: user?.id ?? '',
                                  type: _selectedPart,
                                  value: val,
                                  unit: 'cm',
                                  recordedAt: DateTime.now(),
                                ),
                              );
                              if (mounted) Navigator.pop(ctx);
                            },
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProfileProvider);
    final measurementsAsync =
        ref.watch(bodyCircumferenceStreamProvider(user?.id ?? ''));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Body Measurements'),
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
                onPressed: _showAddMeasurementModal,
              ),
            ),
          ),
        ],
      ),
      body: measurementsAsync.when(
        data: (allRecords) {
          final bodyRecords =
              allRecords.where((r) => r.type != 'Weight').toList();

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            children: [
              const Text(
                'Track body circumference to measure muscular development independent of scale weight.',
                style: AppTypography.bodyMedium,
              ),
              const SizedBox(height: 24),
              ...bodyRecords.map((m) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: AppCard(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const NeumorphicContainer(
                              shape: BoxShape.circle,
                              padding: EdgeInsets.all(12),
                              child: Icon(Icons.straighten_rounded,
                                  color: AppColors.primary, size: 24),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(m.type, style: AppTypography.titleLarge),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormatter.formatTimelineDate(
                                      m.recordedAt),
                                  style: AppTypography.bodySmall,
                                ),
                              ],
                            ),
                          ],
                        ),
                        Text(
                          '${m.value} ${m.unit}',
                          style: AppTypography.titleLarge
                              .copyWith(color: AppColors.primary),
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
