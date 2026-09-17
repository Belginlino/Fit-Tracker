import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fittrack/app/theme/app_colors.dart';
import 'package:fittrack/app/theme/app_typography.dart';
import 'package:fittrack/core/widgets/app_button.dart';
import 'package:fittrack/core/widgets/app_card.dart';
import 'package:fittrack/core/widgets/app_text_field.dart';
import 'package:fittrack/core/widgets/neumorphic_container.dart';
import 'package:fittrack/features/auth/data/auth_repository.dart';
import '../data/progress_photo_repository.dart';

import 'package:intl/intl.dart';

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen> {
  final ImagePicker _picker = ImagePicker();
  String _selectedPose = 'Front';
  final _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  int _selectedDay = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(currentUserProfileProvider);
      if (user != null) {
        final photos =
            ref.read(progressPhotosStreamProvider(user.id)).value ?? [];
        if (photos.isNotEmpty) {
          final maxDay = photos
              .map((p) => p.effectiveDayNumber)
              .reduce((a, b) => a > b ? a : b);
          setState(() {
            _selectedDay = maxDay + 1;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
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
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _capture(ImageSource source) async {
    try {
      if (source == ImageSource.gallery) {
        final List<XFile> images = await _picker.pickMultiImage(
          maxWidth: 1920,
          maxHeight: 1920,
          imageQuality: 88,
        );
        if (images.isNotEmpty && mounted) {
          context.push('/progress/preview', extra: {
            'imagePaths': images.map((e) => e.path).toList(),
            'imagePath': images.first.path,
            'pose': _selectedPose,
            'notes': _notesController.text,
            'selectedDate': _selectedDate.toIso8601String(),
            'dayNumber': _selectedDay,
          });
        }
      } else {
        final XFile? image = await _picker.pickImage(
          source: source,
          maxWidth: 1920,
          maxHeight: 1920,
          imageQuality: 88,
        );
        if (image != null && mounted) {
          context.push('/progress/preview', extra: {
            'imagePaths': [image.path],
            'imagePath': image.path,
            'pose': _selectedPose,
            'notes': _notesController.text,
            'selectedDate': _selectedDate.toIso8601String(),
            'dayNumber': _selectedDay,
          });
        }
      }
    } catch (e) {
      debugPrint('Image capture error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProfileProvider);
    final weightStr = user?.currentWeight != null
        ? '${user!.currentWeight.toStringAsFixed(1)} kg'
        : 'Not set';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Progress Photo'),
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
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Main Camera Button
              AppCard(
                onTap: () => _capture(ImageSource.camera),
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: const Column(
                  children: [
                    NeumorphicContainer(
                      shape: BoxShape.circle,
                      padding: EdgeInsets.all(16),
                      child: Icon(Icons.camera_alt_outlined,
                          color: AppColors.primary, size: 36),
                    ),
                    SizedBox(height: 20),
                    Text('Take a Photo', style: AppTypography.titleLarge),
                    SizedBox(height: 8),
                    Text('Front, Side or Back', style: AppTypography.bodySmall),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // OR divider
              const Row(
                children: [
                  Expanded(child: Divider(color: AppColors.border)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('OR', style: AppTypography.bodySmall),
                  ),
                  Expanded(child: Divider(color: AppColors.border)),
                ],
              ),
              const SizedBox(height: 24),

              // Gallery Button
              AppButton(
                label: 'Choose from Gallery',
                type: AppButtonType.outline,
                onPressed: () => _capture(ImageSource.gallery),
              ),
              const SizedBox(height: 32),

              // Day & Date Selection (From Day 1 onwards)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Day & Date', style: AppTypography.labelLarge),
                  if (_selectedDay == 1)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '★ Baseline',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Date Picker Card
              GestureDetector(
                onTap: _pickDate,
                child: NeumorphicContainer(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  borderRadius: 14,
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month_rounded,
                          color: AppColors.primary, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Photo Date', style: AppTypography.bodySmall),
                            Text(
                              DateFormat('EEEE, MMM d, yyyy').format(_selectedDate),
                              style: AppTypography.titleMedium.copyWith(fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.edit_calendar_rounded,
                          color: AppColors.textMuted, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Day Stepper & Quick Presets
              NeumorphicContainer(
                padding: const EdgeInsets.all(14),
                borderRadius: 14,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Transformation Day:', style: AppTypography.bodyMedium),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                if (_selectedDay > 1) {
                                  setState(() => _selectedDay--);
                                }
                              },
                              child: const NeumorphicContainer(
                                width: 36,
                                height: 36,
                                shape: BoxShape.circle,
                                child: Icon(Icons.remove, size: 18, color: AppColors.primary),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'Day $_selectedDay',
                                style: AppTypography.titleLarge.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() => _selectedDay++);
                              },
                              child: const NeumorphicContainer(
                                width: 36,
                                height: 36,
                                shape: BoxShape.circle,
                                child: Icon(Icons.add, size: 18, color: AppColors.primary),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [1, 7, 14, 30, 60, 90, 180].map((d) {
                          final isSelected = _selectedDay == d;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedDay = d),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.surface,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.border,
                                  ),
                                ),
                                child: Text(
                                  d == 1 ? 'Day 1 (Start)' : 'Day $d',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected
                                        ? Colors.white
                                        : AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Photo Type
              const Text('Photo Type', style: AppTypography.labelLarge),
              const SizedBox(height: 12),
              Row(
                children: ['Front', 'Side', 'Back'].map((pose) {
                  final isSelected = _selectedPose == pose;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedPose = pose),
                        child: NeumorphicContainer(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          style: isSelected
                              ? NeumorphicStyle.inset
                              : NeumorphicStyle.raised,
                          borderRadius: 12,
                          child: Center(
                            child: Text(
                              pose,
                              style: TextStyle(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),

              // Weight display
              const Text('Weight', style: AppTypography.labelLarge),
              const SizedBox(height: 12),
              NeumorphicContainer(
                style: NeumorphicStyle.inset,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  children: [
                    const Icon(Icons.scale_rounded,
                        color: AppColors.primary, size: 20),
                    const SizedBox(width: 12),
                    Text(weightStr, style: AppTypography.bodyLarge),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Notes
              const Text('Notes (optional)', style: AppTypography.labelLarge),
              const SizedBox(height: 12),
              AppTextField(
                hint: 'How was your workout today?',
                controller: _notesController,
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
