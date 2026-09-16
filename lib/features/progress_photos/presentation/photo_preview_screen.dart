import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fittrack/app/theme/app_colors.dart';
import 'package:fittrack/app/theme/app_typography.dart';
import 'package:fittrack/core/constants/app_constants.dart';
import 'package:fittrack/core/widgets/app_button.dart';
import 'package:fittrack/core/widgets/app_text_field.dart';
import 'package:fittrack/features/auth/data/auth_repository.dart';
import '../data/progress_photo_repository.dart';
import '../domain/progress_photo.dart';

class PhotoPreviewScreen extends ConsumerStatefulWidget {
  final String imagePath;
  final String initialPose;

  const PhotoPreviewScreen({
    super.key,
    required this.imagePath,
    this.initialPose = 'Front',
  });

  @override
  ConsumerState<PhotoPreviewScreen> createState() => _PhotoPreviewScreenState();
}

class _PhotoPreviewScreenState extends ConsumerState<PhotoPreviewScreen> {
  late String _selectedPose;
  final _weightController = TextEditingController(text: '74.2');
  final _notesController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedPose = widget.initialPose;
  }

  @override
  void dispose() {
    _weightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _savePhoto() async {
    setState(() => _isSaving = true);
    final authRepo = ref.read(authRepositoryProvider);
    final user = authRepo.currentUser;
    final photoRepo = ref.read(progressPhotoRepositoryProvider);

    final newPhoto = ProgressPhoto(
      id: 'photo-${DateTime.now().millisecondsSinceEpoch}',
      userId: user?.id ?? 'demo-user-101',
      storagePath: 'users/${user?.id ?? 'demo-user-101'}/progress_photos/${DateTime.now().millisecondsSinceEpoch}.jpg',
      localFilePath: widget.imagePath,
      createdAt: DateTime.now(),
      pose: _selectedPose,
      weightAtCapture: double.tryParse(_weightController.text) ?? 74.2,
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
    );

    await photoRepo.savePhoto(newPhoto);

    // Increment photo streak on user profile
    if (user != null) {
      await authRepo.updateProfile(user.copyWith(
        photoStreak: user.photoStreak + 1,
        currentWeight: newPhoto.weightAtCapture ?? user.currentWeight,
      ));
    }

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Progress photo saved successfully! Streak increased 🔥'),
          backgroundColor: AppColors.success,
        ),
      );
      context.go('/progress');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Save Progress Photo'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Photo Preview Card
              Container(
                height: 280,
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.divider),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        color: const Color(0xFF1E2436),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.person_rounded, size: 72, color: AppColors.primary),
                              const SizedBox(height: 8),
                              Text(
                                'Pose: $_selectedPose',
                                style: AppTypography.titleMedium.copyWith(color: AppColors.primary),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xBD000000),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'High Quality',
                            style: AppTypography.bodySmall.copyWith(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Pose Selector
              Text('Select Pose', style: AppTypography.labelMedium),
              const SizedBox(height: 10),
              Row(
                children: AppConstants.photoPoses.map((pose) {
                  final isSelected = _selectedPose == pose;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedPose = pose),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : AppColors.card,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : AppColors.divider,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            pose,
                            style: TextStyle(
                              color: isSelected ? Colors.black : AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Weight input at capture
              AppTextField(
                label: 'Weight at Capture (kg)',
                hint: '74.2',
                controller: _weightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                prefixIcon: const Icon(Icons.scale_rounded, color: AppColors.textMuted, size: 20),
              ),
              const SizedBox(height: 18),

              // Notes
              AppTextField(
                label: 'Notes (Optional)',
                hint: 'Felt strong today, good pump...',
                controller: _notesController,
                maxLines: 2,
                prefixIcon: const Icon(Icons.edit_note_rounded, color: AppColors.textMuted, size: 20),
              ),
              const SizedBox(height: 32),

              AppButton(
                label: 'Save Progress Record',
                isLoading: _isSaving,
                onPressed: _savePhoto,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
