import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:fittrack/app/theme/app_colors.dart';
import 'package:fittrack/app/theme/app_typography.dart';
import 'package:fittrack/core/widgets/app_button.dart';
import 'package:fittrack/core/widgets/app_text_field.dart';
import 'package:fittrack/core/widgets/neumorphic_container.dart';
import 'package:fittrack/core/widgets/app_photo_image.dart';
import 'package:fittrack/features/auth/data/auth_repository.dart';
import '../data/progress_photo_repository.dart';
import '../domain/progress_photo.dart';

class PhotoItem {
  final String path;
  String pose;

  PhotoItem({required this.path, this.pose = 'Front'});
}

class PhotoPreviewScreen extends ConsumerStatefulWidget {
  final String? imagePath;
  final List<String>? imagePaths;
  final String initialPose;
  final String? initialNotes;
  final DateTime? initialDate;
  final int? initialDayNumber;
  final bool isViewingExisting;

  const PhotoPreviewScreen({
    super.key,
    this.imagePath,
    this.imagePaths,
    this.initialPose = 'Front',
    this.initialNotes,
    this.initialDate,
    this.initialDayNumber,
    this.isViewingExisting = false,
  });

  @override
  ConsumerState<PhotoPreviewScreen> createState() => _PhotoPreviewScreenState();
}

class _PhotoPreviewScreenState extends ConsumerState<PhotoPreviewScreen> {
  final List<PhotoItem> _photos = [];
  int _currentIndex = 0;

  late TextEditingController _weightController;
  late TextEditingController _notesController;
  late DateTime _selectedDate;
  late int _selectedDay;
  bool _isSaving = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();

    // Populate initial photos list
    if (widget.imagePaths != null && widget.imagePaths!.isNotEmpty) {
      final defaultPoses = ['Front', 'Side', 'Back'];
      for (int i = 0; i < widget.imagePaths!.length; i++) {
        final pose = i < defaultPoses.length ? defaultPoses[i] : 'Front';
        _photos.add(PhotoItem(path: widget.imagePaths![i], pose: pose));
      }
    } else if (widget.imagePath != null && widget.imagePath!.isNotEmpty) {
      _photos.add(PhotoItem(path: widget.imagePath!, pose: widget.initialPose));
    }

    _selectedDate = widget.initialDate ?? DateTime.now();
    _selectedDay = widget.initialDayNumber ?? 1;

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

  PhotoItem? get _currentPhoto =>
      _photos.isNotEmpty && _currentIndex < _photos.length
          ? _photos[_currentIndex]
          : null;

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

  Future<void> _addMorePhotos() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Add Another Photo', style: AppTypography.titleMedium),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.camera_alt_outlined,
                      color: AppColors.primary),
                  title: const Text('Take with Camera',
                      style: AppTypography.bodyMedium),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final img = await _picker.pickImage(
                        source: ImageSource.camera,
                        maxWidth: 1920,
                        maxHeight: 1920,
                        imageQuality: 88);
                    if (img != null && mounted) {
                      setState(() {
                        final nextPose = _photos.length == 1
                            ? 'Side'
                            : (_photos.length == 2 ? 'Back' : 'Front');
                        _photos.add(PhotoItem(path: img.path, pose: nextPose));
                        _currentIndex = _photos.length - 1;
                      });
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined,
                      color: AppColors.primary),
                  title: const Text('Choose from Gallery',
                      style: AppTypography.bodyMedium),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final imgs = await _picker.pickMultiImage(
                        maxWidth: 1920, maxHeight: 1920, imageQuality: 88);
                    if (imgs.isNotEmpty && mounted) {
                      setState(() {
                        for (final img in imgs) {
                          final nextPose = _photos.length == 1
                              ? 'Side'
                              : (_photos.length == 2 ? 'Back' : 'Front');
                          _photos.add(PhotoItem(path: img.path, pose: nextPose));
                        }
                        _currentIndex = _photos.length - 1;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _savePhotos() async {
    if (_photos.isEmpty) return;

    setState(() => _isSaving = true);
    final authRepo = ref.read(authRepositoryProvider);
    final user = authRepo.currentUser;
    final photoRepo = ref.read(progressPhotoRepositoryProvider);
    final currentWeight = double.tryParse(_weightController.text) ??
        (user?.currentWeight ?? 70.0);

    final userId = user?.id ?? 'user-local';

    for (int i = 0; i < _photos.length; i++) {
      final p = _photos[i];
      final timestamp = DateTime.now().millisecondsSinceEpoch + i;
      final newPhoto = ProgressPhoto(
        id: 'photo-$timestamp',
        userId: userId,
        storagePath: 'users/$userId/progress_photos/$timestamp.jpg',
        localFilePath: p.path,
        createdAt: _selectedDate,
        dayNumber: _selectedDay,
        pose: p.pose,
        weightAtCapture: currentWeight,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      );

      await photoRepo.savePhoto(newPhoto);
    }

    if (user != null) {
      await authRepo.updateProfile(user.copyWith(
        photoStreak: (user.photoStreak) + _photos.length,
        currentWeight: currentWeight,
      ));
    }

    if (mounted) {
      setState(() => _isSaving = false);
      final countStr = _photos.length == 1
          ? 'Day $_selectedDay progress photo saved! ✓'
          : '${_photos.length} progress photos saved for Day $_selectedDay! ✓';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(countStr),
          backgroundColor: AppColors.success,
        ),
      );
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = _currentPhoto;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isViewingExisting ? 'Photo Details' : 'Review Photo'),
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
          if (!widget.isViewingExisting)
            Padding(
              padding: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
              child: NeumorphicContainer(
                borderRadius: 12,
                child: IconButton(
                  icon: const Icon(Icons.add_photo_alternate_rounded,
                      color: AppColors.primary),
                  tooltip: 'Add More Photos',
                  onPressed: _addMorePhotos,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Multiple Photos Thumbnail Selector (when > 1 photo)
              if (_photos.length > 1) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Photos (${_currentIndex + 1} of ${_photos.length})',
                      style: AppTypography.labelLarge,
                    ),
                    TextButton.icon(
                      onPressed: _addMorePhotos,
                      icon: const Icon(Icons.add, size: 18, color: AppColors.primary),
                      label: const Text('Add More',
                          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 90,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _photos.length + 1,
                    itemBuilder: (context, idx) {
                      if (idx == _photos.length) {
                        return GestureDetector(
                          onTap: _addMorePhotos,
                          child: Container(
                            width: 68,
                            margin: const EdgeInsets.only(right: 12, bottom: 4),
                            child: const NeumorphicContainer(
                              borderRadius: 14,
                              child: Center(
                                child: Icon(Icons.add_a_photo_outlined,
                                    color: AppColors.primary, size: 24),
                              ),
                            ),
                          ),
                        );
                      }

                      final p = _photos[idx];
                      final isSelected = idx == _currentIndex;

                      return GestureDetector(
                        onTap: () => setState(() => _currentIndex = idx),
                        child: Container(
                          width: 68,
                          margin: const EdgeInsets.only(right: 12, bottom: 4),
                          child: Stack(
                            children: [
                              NeumorphicContainer(
                                borderRadius: 14,
                                padding: EdgeInsets.zero,
                                style: isSelected
                                    ? NeumorphicStyle.inset
                                    : NeumorphicStyle.raised,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    border: isSelected
                                        ? Border.all(color: AppColors.primary, width: 2.5)
                                        : null,
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: AppPhotoImage(
                                      localPath: p.path,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                              // Pose Tag on Thumbnail
                              Positioned(
                                bottom: 2,
                                left: 2,
                                right: 2,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.65),
                                    borderRadius: const BorderRadius.vertical(
                                        bottom: Radius.circular(12)),
                                  ),
                                  child: Text(
                                    p.pose,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ),
                              // Remove Thumbnail
                              if (_photos.length > 1 && !widget.isViewingExisting)
                                Positioned(
                                  top: -2,
                                  right: -2,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _photos.removeAt(idx);
                                        if (_currentIndex >= _photos.length) {
                                          _currentIndex = _photos.length - 1;
                                        }
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: const BoxDecoration(
                                        color: Colors.redAccent,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close,
                                          size: 12, color: Colors.white),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Centered Responsive Portrait Photo Box (Fixes the squished/cropped horizontal ribbon)
              if (current != null)
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 420,
                      maxHeight: 460,
                    ),
                    child: AspectRatio(
                      aspectRatio: 3 / 4,
                      child: NeumorphicContainer(
                        borderRadius: 20,
                        padding: EdgeInsets.zero,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              AppPhotoImage(
                                localPath: current.path,
                                fit: BoxFit.cover,
                              ),
                              Positioned(
                                top: 12,
                                right: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    current.pose,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              else
                NeumorphicContainer(
                  height: 280,
                  borderRadius: 20,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_a_photo_outlined,
                            size: 48, color: AppColors.primary),
                        const SizedBox(height: 12),
                        const Text('No Photo Selected',
                            style: AppTypography.titleMedium),
                        const SizedBox(height: 8),
                        AppButton(
                          label: 'Add Photos',
                          onPressed: _addMorePhotos,
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 20),

              // Day & Date Info Card
              NeumorphicContainer(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                borderRadius: 16,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: _selectedDay == 1
                            ? AppColors.primary
                            : AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _selectedDay == 1
                            ? 'Day 1 ★ Baseline'
                            : 'Day $_selectedDay',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: _selectedDay == 1
                              ? Colors.white
                              : AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Recorded For',
                              style: AppTypography.bodySmall),
                          Text(
                            DateFormat('EEE, MMM d, yyyy').format(_selectedDate),
                            style:
                                AppTypography.titleMedium.copyWith(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_calendar_rounded,
                          color: AppColors.primary, size: 22),
                      tooltip: 'Change Date',
                      onPressed: _pickDate,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Pose Selector for current photo
              if (current != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _photos.length > 1
                          ? 'Pose for Photo ${_currentIndex + 1}'
                          : 'Pose',
                      style: AppTypography.labelLarge,
                    ),
                    Text(
                      current.pose,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: ['Front', 'Side', 'Back', 'Free'].map((pose) {
                    final isSelected = current.pose == pose;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: GestureDetector(
                          onTap: () => setState(() => current.pose = pose),
                          child: NeumorphicContainer(
                            padding: const EdgeInsets.symmetric(vertical: 11),
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
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
              ],

              // Weight input
              const Text('Weight', style: AppTypography.labelLarge),
              const SizedBox(height: 10),
              AppTextField(
                hint: '68.5',
                controller: _weightController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                prefixIcon: const Icon(Icons.scale_rounded,
                    color: AppColors.textMuted, size: 20),
              ),
              const SizedBox(height: 20),

              // Notes
              const Text('Notes', style: AppTypography.labelLarge),
              const SizedBox(height: 10),
              AppTextField(
                hint: 'Optional notes or workout link',
                controller: _notesController,
                maxLines: 2,
              ),
              const SizedBox(height: 36),

              // Save Action Button
              AppButton(
                label: _photos.length <= 1
                    ? (widget.isViewingExisting ? 'Update Photo' : 'Save Photo')
                    : 'Save All ${_photos.length} Photos',
                isLoading: _isSaving,
                onPressed: _photos.isNotEmpty ? _savePhotos : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
