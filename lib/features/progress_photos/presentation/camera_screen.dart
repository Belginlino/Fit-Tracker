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

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen> {
  final ImagePicker _picker = ImagePicker();
  String _selectedPose = 'Front';
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _capture(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 88,
      );
      if (image != null && mounted) {
        context.push('/progress/preview', extra: {
          'imagePath': image.path,
          'pose': _selectedPose,
          'notes': _notesController.text,
        });
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
              const SizedBox(height: 36),

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
