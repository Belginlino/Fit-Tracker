import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fittrack/app/theme/app_colors.dart';
import 'package:fittrack/app/theme/app_typography.dart';
import 'package:fittrack/core/utils/date_formatter.dart';
import 'package:fittrack/core/widgets/app_photo_image.dart';
import 'package:fittrack/core/widgets/empty_state_view.dart';
import 'package:fittrack/core/widgets/neumorphic_container.dart';
import 'package:fittrack/features/auth/data/auth_repository.dart';
import '../data/progress_photo_repository.dart';
import '../domain/progress_photo.dart';

class TimelineScreen extends ConsumerStatefulWidget {
  const TimelineScreen({super.key});

  @override
  ConsumerState<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends ConsumerState<TimelineScreen> {
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProfileProvider);
    final photosAsync =
        ref.watch(progressPhotosStreamProvider(user?.id ?? ''));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress Photos'),
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
          child: NeumorphicContainer(
            borderRadius: 12,
            child: IconButton(
              icon: Icon(
                context.canPop()
                    ? Icons.arrow_back_ios_new_rounded
                    : Icons.calendar_month_rounded,
                size: 20,
                color: AppColors.primary,
              ),
              tooltip: context.canPop() ? 'Back' : 'Calendar View',
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.push('/progress/calendar');
                }
              },
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            child: NeumorphicContainer(
              borderRadius: 12,
              child: IconButton(
                icon: const Icon(Icons.compare_arrows_rounded,
                    color: AppColors.primary),
                tooltip: 'Before / After Compare',
                onPressed: () => context.push('/progress/compare'),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: NeumorphicContainer(
        shape: BoxShape.circle,
        child: FloatingActionButton(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          onPressed: () => context.push('/camera'),
          child: const Icon(Icons.camera_alt_rounded, size: 28),
        ),
      ),
      body: photosAsync.when(
        data: (photos) {
          if (photos.isEmpty) {
            return EmptyStateView(
              icon: Icons.photo_camera_outlined,
              title: 'No Progress Photos',
              description: 'Take your first photo after your next workout.',
              actionLabel: 'Take Photo',
              onAction: () => context.push('/camera'),
            );
          }

          final filtered = _selectedFilter == 'All'
              ? photos
              : photos.where((p) => p.pose == _selectedFilter).toList();

          return Column(
            children: [
              const SizedBox(height: 16),
              // Filter Segmented Control
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: ['All', 'Front', 'Side', 'Back'].map((filter) {
                    final isSelected = _selectedFilter == filter;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedFilter = filter),
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        child: NeumorphicContainer(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          borderRadius: 20,
                          style: isSelected
                              ? NeumorphicStyle.inset
                              : NeumorphicStyle.raised,
                          child: Text(
                            filter,
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
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),

              // Photo Grid
              Expanded(
                child: GridView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 24,
                    childAspectRatio: 0.65,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final photo = filtered[index];
                    return _buildGridCard(photo);
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Future<void> _confirmDeletePhoto(ProgressPhoto photo) async {
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
        content: Text(
          'Delete ${photo.dayLabel} (${photo.pose} pose) photo? It will be permanently removed from cloud storage.',
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

    try {
      final user = ref.read(currentUserProfileProvider);
      await ref
          .read(progressPhotoRepositoryProvider)
          .deletePhoto(photo.id, userId: user?.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Progress photo deleted ✓'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete photo: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Widget _buildGridCard(ProgressPhoto photo) {
    return GestureDetector(
      onTap: () => context.push('/progress/preview', extra: {
        'photoId': photo.id,
        'imagePath': photo.localFilePath ?? photo.downloadUrl ?? '',
        'pose': photo.pose,
        'selectedDate': photo.createdAt.toIso8601String(),
        'dayNumber': photo.effectiveDayNumber,
        'weight': photo.weightAtCapture,
        'notes': photo.cleanNotes,
        'isViewingExisting': true,
      }),
      onLongPress: () => _confirmDeletePhoto(photo),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: NeumorphicContainer(
              borderRadius: 16,
              padding: EdgeInsets.zero,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AppPhotoImage(
                      localPath: photo.localFilePath,
                      remoteUrl: photo.downloadUrl,
                      fit: BoxFit.cover,
                    ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: photo.isDayOne
                              ? const Color(0xFFD97706) // Warm gold for Day 1
                              : Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Text(
                          photo.isDayOne ? '★ Day 1' : photo.dayLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              photo.pose,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () => _confirmDeletePhoto(photo),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.65),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.delete_outline_rounded,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            photo.isDayOne
                ? 'Day 1 • Baseline'
                : '${photo.dayLabel} • ${photo.pose}',
            style: AppTypography.labelMedium.copyWith(
              color: photo.isDayOne ? AppColors.primary : AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            DateFormatter.formatTimelineDate(photo.createdAt),
            style: AppTypography.bodySmall.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }
}
