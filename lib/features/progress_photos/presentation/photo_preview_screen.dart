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
import 'package:fittrack/core/utils/streak_calculator.dart';

class PhotoItem {
  final String path;
  String pose;

  PhotoItem({required this.path, this.pose = 'Front'});
}

class PhotoPreviewScreen extends ConsumerStatefulWidget {
  final String? photoId;
  final String? imagePath;
  final List<String>? imagePaths;
  final String initialPose;
  final String? initialNotes;
  final DateTime? initialDate;
  final int? initialDayNumber;
  final double? initialWeight;
  final bool isViewingExisting;

  const PhotoPreviewScreen({
    super.key,
    this.photoId,
    this.imagePath,
    this.imagePaths,
    this.initialPose = 'Front',
    this.initialNotes,
    this.initialDate,
    this.initialDayNumber,
    this.initialWeight,
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
  bool _isDeleting = false;
  final ImagePicker _picker = ImagePicker();

  DateTime? _baselineDate;

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

    final user = ref.read(currentUserProfileProvider);
    final initialWeight = widget.initialWeight ?? user?.currentWeight ?? 70.0;
    _weightController =
        TextEditingController(text: initialWeight.toStringAsFixed(1));
    _notesController = TextEditingController(text: widget.initialNotes ?? '');

    Future.microtask(() => _initBaseline());
  }

  Future<void> _initBaseline() async {
    final user = ref.read(currentUserProfileProvider);
    final repo = ref.read(progressPhotoRepositoryProvider);
    final photos = await repo.getPhotos(user?.id ?? 'user-local');
    if (photos.isNotEmpty && mounted) {
      final earliest = photos
          .map((p) => p.createdAt)
          .reduce((a, b) => a.isBefore(b) ? a : b);
      setState(() {
        _baselineDate = DateTime(earliest.year, earliest.month, earliest.day);
      });
    } else if (mounted) {
      setState(() {
        _baselineDate =
            DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
      });
    }
  }

  void _setDay(int newDay, {bool updateDate = false}) {
    if (newDay < 1) return;
    setState(() {
      _selectedDay = newDay;
      if (updateDate && _baselineDate != null) {
        _selectedDate = _baselineDate!.add(Duration(days: newDay - 1));
      }
    });
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
    if (picked != null && mounted) {
      final user = ref.read(currentUserProfileProvider);
      final repo = ref.read(progressPhotoRepositoryProvider);
      final photos = await repo.getPhotos(user?.id ?? 'user-local');
      DateTime base =
          _baselineDate ?? DateTime(picked.year, picked.month, picked.day);
      if (photos.isNotEmpty) {
        final earliest = photos
            .map((p) => p.createdAt)
            .reduce((a, b) => a.isBefore(b) ? a : b);
        base = DateTime(earliest.year, earliest.month, earliest.day);
      }
      final diff = DateTime(picked.year, picked.month, picked.day)
              .difference(base)
              .inDays +
          1;

      setState(() {
        _selectedDate = picked;
        _baselineDate = base;
        _selectedDay = diff >= 1 ? diff : 1;
      });
    }
  }

  Future<void> _showCustomDayDialog() async {
    final controller = TextEditingController(text: _selectedDay.toString());
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Enter Day Number', style: AppTypography.titleMedium),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: 'e.g. 1, 30, 90',
            labelText: 'Day Number',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final val = int.tryParse(controller.text.trim());
              if (val != null && val >= 1) {
                Navigator.pop(ctx, val);
              } else {
                Navigator.pop(ctx);
              }
            },
            child: const Text('Set'),
          ),
        ],
      ),
    );
    if (result != null && mounted) {
      _setDay(result, updateDate: true);
    }
  }

  Future<void> _replacePhoto() async {
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
                const Text('Replace Photo', style: AppTypography.titleMedium),
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
                        if (_photos.isNotEmpty) {
                          _photos[_currentIndex] = PhotoItem(
                            path: img.path,
                            pose: _photos[_currentIndex].pose,
                          );
                        } else {
                          _photos.add(PhotoItem(
                              path: img.path, pose: widget.initialPose));
                          _currentIndex = 0;
                        }
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
                    final img = await _picker.pickImage(
                        source: ImageSource.gallery,
                        maxWidth: 1920,
                        maxHeight: 1920,
                        imageQuality: 88);
                    if (img != null && mounted) {
                      setState(() {
                        if (_photos.isNotEmpty) {
                          _photos[_currentIndex] = PhotoItem(
                            path: img.path,
                            pose: _photos[_currentIndex].pose,
                          );
                        } else {
                          _photos.add(PhotoItem(
                              path: img.path, pose: widget.initialPose));
                          _currentIndex = 0;
                        }
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

    if (widget.isViewingExisting &&
        widget.photoId != null &&
        widget.photoId!.isNotEmpty) {
      // UPDATE EXISTING PHOTO: Update in-place, DO NOT create duplicates
      final existingPhotos = await photoRepo.getPhotos(userId);
      final existing =
          existingPhotos.where((p) => p.id == widget.photoId).firstOrNull;

      final currentItem = _currentPhoto;
      final currentPath = currentItem?.path ?? widget.imagePath;

      final isNewLocalFile = currentPath != null &&
          !currentPath.startsWith('http') &&
          currentPath != existing?.localFilePath &&
          currentPath != existing?.downloadUrl;

      final baseNotes = _notesController.text.trim();
      final notesWithDay = baseNotes.isNotEmpty
          ? '[Day $_selectedDay] $baseNotes'
          : '[Day $_selectedDay]';

      final updatedPhoto = ProgressPhoto(
        id: widget.photoId!,
        userId: userId,
        storagePath: isNewLocalFile
            ? 'users/$userId/progress_photos/${DateTime.now().millisecondsSinceEpoch}.jpg'
            : (existing?.storagePath ?? currentPath ?? ''),
        downloadUrl: isNewLocalFile ? null : existing?.downloadUrl,
        localFilePath: isNewLocalFile
            ? currentPath
            : (existing?.localFilePath ?? currentPath),
        createdAt: _selectedDate,
        dayNumber: _selectedDay,
        pose: currentItem?.pose ?? widget.initialPose,
        weightAtCapture: currentWeight,
        notes: notesWithDay,
        workoutId: existing?.workoutId,
      );

      await photoRepo.savePhoto(updatedPhoto);
    } else {
      // SAVE NEW PHOTOS: Create new entries for new session
      final baseNotes = _notesController.text.trim();
      final notesWithDay = baseNotes.isNotEmpty
          ? '[Day $_selectedDay] $baseNotes'
          : '[Day $_selectedDay]';

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
          notes: notesWithDay,
        );

        await photoRepo.savePhoto(newPhoto);
      }
    }

    ref.invalidate(progressPhotosStreamProvider(userId));

    if (user != null) {
      final existingPhotos = await photoRepo.getPhotos(user.id);
      final allPhotoDates = [
        _selectedDate,
        ...existingPhotos.map((p) => p.createdAt)
      ];
      final accurateStreak = StreakCalculator.calculateStreak(allPhotoDates);

      await authRepo.updateProfile(user.copyWith(
        photoStreak: accurateStreak,
        currentWeight: currentWeight,
      ));
    }

    if (mounted) {
      setState(() => _isSaving = false);
      final msg = widget.isViewingExisting
          ? 'Day $_selectedDay progress photo updated! ✓'
          : (_photos.length == 1
              ? 'Day $_selectedDay progress photo saved! ✓'
              : '${_photos.length} progress photos saved for Day $_selectedDay! ✓');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: AppColors.success,
        ),
      );
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/home');
      }
    }
  }

  Future<void> _confirmDeletePhoto() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 24),
            SizedBox(width: 8),
            Text('Delete Photo?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete this progress photo? It will be permanently removed from your progress history and cloud storage.',
          style: AppTypography.bodySmall,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isDeleting = true);

    try {
      final user = ref.read(currentUserProfileProvider);
      final repo = ref.read(progressPhotoRepositoryProvider);

      String? idToDelete = widget.photoId;
      if (idToDelete == null || idToDelete.isEmpty) {
        final path = _currentPhoto?.path ?? widget.imagePath ?? '';
        final match =
            RegExp(r'/files/([^/]+)/(?:view|preview)').firstMatch(path);
        if (match != null) {
          idToDelete = match.group(1);
        } else if (path.contains('photo-')) {
          final pMatch = RegExp(r'(photo-\d+)').firstMatch(path);
          idToDelete = pMatch?.group(1);
        } else if (!path.contains('/') && path.isNotEmpty) {
          idToDelete = path;
        }
      }

      if (idToDelete != null && idToDelete.isNotEmpty) {
        await repo.deletePhoto(idToDelete, userId: user?.id);
      }

      if (mounted) {
        setState(() => _isDeleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Progress photo deleted ✓'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDeleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete photo: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
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
          if (widget.isViewingExisting)
            Padding(
              padding: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
              child: NeumorphicContainer(
                borderRadius: 12,
                child: IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: AppColors.error),
                  tooltip: 'Delete Photo',
                  onPressed: _isDeleting ? null : _confirmDeletePhoto,
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
                              if (widget.isViewingExisting)
                                Positioned(
                                  bottom: 12,
                                  right: 12,
                                  child: GestureDetector(
                                    onTap: _replacePhoto,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.75),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: Colors.white.withValues(alpha: 0.2),
                                        ),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.camera_alt_outlined,
                                              color: Colors.white, size: 14),
                                          SizedBox(width: 4),
                                          Text(
                                            'Change Photo',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
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

              // Interactive Transformation Day & Date Card
              NeumorphicContainer(
                padding: const EdgeInsets.all(16),
                borderRadius: 18,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        const Text('Transformation Day',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            )),
                        const SizedBox(width: 8),
                        if (_selectedDay == 1)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD97706),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              '★ Baseline',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _selectedDay == 1
                          ? 'Day 1 is your baseline starting point'
                          : 'Day $_selectedDay milestone of your fitness journey',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Dedicated Stepper Bar
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Decrement button
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                if (_selectedDay > 1) {
                                  _setDay(_selectedDay - 1, updateDate: true);
                                }
                              },
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: _selectedDay > 1
                                      ? AppColors.primary
                                          .withValues(alpha: 0.12)
                                      : Colors.grey.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.remove_rounded,
                                  color: _selectedDay > 1
                                      ? AppColors.primary
                                      : AppColors.textMuted,
                                  size: 22,
                                ),
                              ),
                            ),
                          ),
                          // Day Display (Clickable to edit)
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: _showCustomDayDialog,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Day $_selectedDay',
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Icon(Icons.edit_outlined,
                                        size: 14,
                                        color: AppColors.textSecondary),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _selectedDay == 1
                                      ? '★ Baseline Day'
                                      : DateFormat('EEE, MMM d, yyyy')
                                          .format(_selectedDate),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _selectedDay == 1
                                        ? const Color(0xFFD97706)
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Increment button
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                _setDay(_selectedDay + 1, updateDate: true);
                              },
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.primary
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.add_rounded,
                                  color: AppColors.primary,
                                  size: 22,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Quick Milestone Preset Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [1, 7, 14, 30, 60, 90, 180].map((d) {
                          final isSelected = _selectedDay == d;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () => _setDay(d, updateDate: true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 7),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.cardBackground,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.border,
                                    width: isSelected ? 1.5 : 1.0,
                                  ),
                                ),
                                child: Text(
                                  d == 1 ? 'Day 1 (Baseline)' : 'Day $d',
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : AppColors.textPrimary,
                                    fontWeight: isSelected
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Divider(color: AppColors.border, height: 1),
                    const SizedBox(height: 12),

                    // Recorded Date Row
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _pickDate,
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_month_rounded,
                              color: AppColors.primary, size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Recorded Date',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary)),
                                Text(
                                  DateFormat('EEEE, MMM d, yyyy')
                                      .format(_selectedDate),
                                  style: AppTypography.titleMedium
                                      .copyWith(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.edit_calendar_rounded,
                                    size: 15, color: AppColors.primary),
                                SizedBox(width: 4),
                                Text(
                                  'Change Date',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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
              if (widget.isViewingExisting) ...[
                const SizedBox(height: 14),
                AppButton(
                  label: 'Delete Photo',
                  type: AppButtonType.danger,
                  icon: Icons.delete_outline_rounded,
                  isLoading: _isDeleting,
                  onPressed: _isDeleting ? null : _confirmDeletePhoto,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
