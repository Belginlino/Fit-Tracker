import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fittrack/app/theme/app_colors.dart';
import 'package:fittrack/app/theme/app_typography.dart';
import 'package:fittrack/core/utils/date_formatter.dart';
import 'package:fittrack/core/widgets/app_photo_image.dart';
import 'package:fittrack/core/widgets/neumorphic_container.dart';
import 'package:fittrack/features/progress_photos/domain/day_photo_group.dart';
import 'day_album_sheet.dart';

/// Reusable folder-style card for progress photos grouped by day
class DayFolderCard extends StatelessWidget {
  final DayPhotoGroup group;
  final bool isCompact;
  final VoidCallback? onDelete;

  const DayFolderCard({
    super.key,
    required this.group,
    this.isCompact = false,
    this.onDelete,
  });

  void _handleTap(BuildContext context) {
    if (group.isFolder) {
      // Multiple photos for this day: open the Day Album sheet/folder
      DayAlbumSheet.show(context, group);
    } else {
      // Single photo: open photo preview directly
      final photo = group.photos.first;
      context.push('/progress/preview', extra: {
        'photoId': photo.id,
        'imagePath': photo.localFilePath ?? photo.downloadUrl ?? '',
        'pose': photo.pose,
        'selectedDate': photo.createdAt.toIso8601String(),
        'dayNumber': photo.effectiveDayNumber,
        'weight': photo.weightAtCapture,
        'notes': photo.cleanNotes,
        'isViewingExisting': true,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return _buildCompact(context);
    }
    return _buildGridCard(context);
  }

  /// Compact card for Dashboard horizontal carousel
  Widget _buildCompact(BuildContext context) {
    final cover = group.coverPhoto;

    return GestureDetector(
      onTap: () => _handleTap(context),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Stacked background folder layer
          if (group.isFolder) ...[
            Positioned(
              top: -3,
              right: -3,
              left: 3,
              bottom: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
          NeumorphicContainer(
            borderRadius: 16,
            padding: EdgeInsets.zero,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  AppPhotoImage(
                    localPath: cover.localFilePath,
                    remoteUrl: cover.downloadUrl,
                    fit: BoxFit.cover,
                  ),
                  // Day Badge (Top Left)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: group.isDayOne
                            ? const Color(0xFFD97706)
                            : Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        group.isDayOne ? '★ Day 1' : group.dayLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  // Folder Count Badge (Top Right)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: group.isFolder
                            ? AppColors.primary
                            : Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (group.isFolder) ...[
                            const Icon(
                              Icons.folder_rounded,
                              color: Colors.white,
                              size: 10,
                            ),
                            const SizedBox(width: 3),
                          ],
                          Text(
                            group.isFolder
                                ? '${group.photoCount}'
                                : cover.pose,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Bottom Pose Summary
                  if (group.isFolder)
                    Positioned(
                      bottom: 6,
                      left: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          group.posesSummary,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Full Grid Card for Timeline Screen
  Widget _buildGridCard(BuildContext context) {
    final cover = group.coverPhoto;

    return GestureDetector(
      onTap: () => _handleTap(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Layered folder cards background
                if (group.isFolder) ...[
                  if (group.photoCount >= 3)
                    Positioned(
                      top: -6,
                      right: -6,
                      left: 6,
                      bottom: 6,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    top: -3,
                    right: -3,
                    left: 3,
                    bottom: 3,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                ],
                NeumorphicContainer(
                  borderRadius: 16,
                  padding: EdgeInsets.zero,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        AppPhotoImage(
                          localPath: cover.localFilePath,
                          remoteUrl: cover.downloadUrl,
                          fit: BoxFit.cover,
                        ),
                        // Day Tag (Top Left)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: group.isDayOne
                                  ? const Color(0xFFD97706)
                                  : Colors.black.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: Text(
                              group.isDayOne ? '★ Day 1' : group.dayLabel,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        // Folder / Pose Badge (Top Right)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 3.5),
                                decoration: BoxDecoration(
                                  color: group.isFolder
                                      ? AppColors.primary
                                      : Colors.black.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.2),
                                      blurRadius: 3,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (group.isFolder) ...[
                                      const Icon(
                                        Icons.folder_copy_rounded,
                                        color: Colors.white,
                                        size: 12,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${group.photoCount} Photos',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ] else ...[
                                      Text(
                                        cover.pose,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (!group.isFolder && onDelete != null) ...[
                                const SizedBox(width: 4),
                                GestureDetector(
                                  onTap: onDelete,
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
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Day Title & Summary
          Text(
            group.isFolder
                ? '${group.dayLabel} • ${group.photoCount} Photos'
                : (group.isDayOne
                    ? 'Day 1 • Baseline'
                    : '${group.dayLabel} • ${cover.pose}'),
            style: AppTypography.labelMedium.copyWith(
              color: group.isDayOne ? AppColors.primary : AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            group.isFolder
                ? group.posesSummary
                : DateFormatter.formatTimelineDate(cover.createdAt),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
