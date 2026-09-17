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
        ref.watch(progressPhotosStreamProvider(user?.id ?? 'athlete-user'));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress Photos'),
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

  Widget _buildGridCard(ProgressPhoto photo) {
    return GestureDetector(
      onTap: () => context.push('/progress/preview', extra: {
        'imagePath': photo.localFilePath,
        'pose': photo.pose,
      }),
      child: Column(
        children: [
          Expanded(
            child: NeumorphicContainer(
              borderRadius: 16,
              padding: EdgeInsets.zero,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AppPhotoImage(
                  localPath: photo.localFilePath,
                  remoteUrl: photo.downloadUrl,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            DateFormatter.formatTimelineDate(photo.createdAt),
            style: AppTypography.labelMedium,
          ),
        ],
      ),
    );
  }
}
