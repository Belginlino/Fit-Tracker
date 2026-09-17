import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fittrack/app/theme/app_colors.dart';
import 'package:fittrack/app/theme/app_typography.dart';
import 'package:fittrack/core/widgets/app_button.dart';
import 'package:fittrack/core/widgets/app_text_field.dart';
import 'package:fittrack/core/widgets/neumorphic_container.dart';
import 'package:fittrack/features/auth/data/auth_repository.dart';
import 'package:fittrack/core/widgets/app_photo_image.dart';
import '../data/progress_photo_repository.dart';
import '../domain/progress_photo.dart';

class PhotoPreviewScreen extends ConsumerStatefulWidget {
  final String imagePath;
  final String initialPose;
  final String? initialNotes;

  const PhotoPreviewScreen({
    super.key,
    required this.imagePath,
    this.initialPose = 'Front',
    this.initialNotes,
  });

  @override
  ConsumerState<PhotoPreviewScreen> createState() => _PhotoPreviewScreenState();
}

class _PhotoPreviewScreenState extends ConsumerState<PhotoPreviewScreen> {
  late String _selectedPose;
  late TextEditingController _weightController;
  late TextEditingController _notesController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedPose = widget.initialPose;
    final initialWeight =
        ref.read(currentUserProfileProvider)?.currentWeight ?? 70.0;
    _weightController =
        TextEditingController(text: initialWeight.toStringAsFixed(1));
    _notesController = TextEditingController(text: widget.initialNotes ?? '');
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
    final currentWeight = double.tryParse(_weightController.text) ??
        (user?.currentWeight ?? 70.0);

    final newPhoto = ProgressPhoto(
      id: 'photo-${DateTime.now().millisecondsSinceEpoch}',
      userId: user?.id ?? 'athlete-user',
      storagePath:
          'users/${user?.id ?? 'athlete-user'}/progress_photos/${DateTime.now().millisecondsSinceEpoch}.jpg',
      localFilePath: widget.imagePath,
      createdAt: DateTime.now(),
      pose: _selectedPose,
      weightAtCapture: currentWeight,
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
    );

    await photoRepo.savePhoto(newPhoto);

    if (user != null) {
      await authRepo.updateProfile(user.copyWith(
        photoStreak: (user.photoStreak) + 1,
        currentWeight: currentWeight,
      ));
    }

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Progress photo recorded successfully! ✓'),
          backgroundColor: AppColors.success,
        ),
      );
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Photo'),
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
              // Photo Box
              NeumorphicContainer(
                height: 380,
                borderRadius: 20,
                padding: EdgeInsets.zero,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: AppPhotoImage(
                    localPath: widget.imagePath,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Pose Selector (readonly looking but tappable)
              const Text('Pose', style: AppTypography.labelLarge),
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
              const SizedBox(height: 24),

              // Weight input
              const Text('Weight', style: AppTypography.labelLarge),
              const SizedBox(height: 12),
              AppTextField(
                hint: '68.5',
                controller: _weightController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                prefixIcon: const Icon(Icons.scale_rounded,
                    color: AppColors.textMuted, size: 20),
              ),
              const SizedBox(height: 24),

              // Notes
              const Text('Notes', style: AppTypography.labelLarge),
              const SizedBox(height: 12),
              AppTextField(
                hint: 'Optional',
                controller: _notesController,
                maxLines: 2,
              ),
              const SizedBox(height: 48),

              AppButton(
                label: 'Save Photo',
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
