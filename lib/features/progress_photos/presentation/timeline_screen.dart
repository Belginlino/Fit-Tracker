import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fittrack/app/theme/app_colors.dart';
import 'package:fittrack/app/theme/app_typography.dart';
import 'package:fittrack/core/widgets/empty_state_view.dart';
import 'package:fittrack/core/widgets/neumorphic_container.dart';
import 'package:fittrack/features/auth/data/auth_repository.dart';
import '../data/progress_photo_repository.dart';
import '../domain/day_photo_group.dart';
import '../domain/progress_photo.dart';
import 'widgets/day_folder_card.dart';

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

          final List<DayPhotoGroup> dayGroups;
          if (_selectedFilter == 'All') {
            dayGroups = DayPhotoGroup.groupPhotos(photos);
          } else {
            final matching = photos
                .where((p) =>
                    p.pose.toLowerCase() == _selectedFilter.toLowerCase())
                .toList();
            dayGroups = matching
                .map((p) => DayPhotoGroup(
                      dayNumber: p.effectiveDayNumber,
                      date: p.createdAt,
                      photos: [p],
                    ))
                .toList()
              ..sort((a, b) => b.dayNumber.compareTo(a.dayNumber));
          }

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
                child: dayGroups.isEmpty
                    ? Center(
                        child: Text(
                          'No $_selectedFilter photos found',
                          style: AppTypography.bodyMedium,
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 24,
                          childAspectRatio: 0.65,
                        ),
                        itemCount: dayGroups.length,
                        itemBuilder: (context, index) {
                          final group = dayGroups[index];
                          return DayFolderCard(
                            group: group,
                            onDelete: group.isFolder
                                ? null
                                : () =>
                                    _confirmDeletePhoto(group.photos.first),
                          );
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
}
