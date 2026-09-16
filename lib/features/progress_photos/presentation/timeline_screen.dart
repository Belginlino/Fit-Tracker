import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fittrack/app/theme/app_colors.dart';
import 'package:fittrack/app/theme/app_typography.dart';
import 'package:fittrack/core/utils/date_formatter.dart';
import 'package:fittrack/core/widgets/app_card.dart';
import 'package:fittrack/core/widgets/empty_state_view.dart';
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
    final photosAsync = ref.watch(progressPhotosStreamProvider(user?.id ?? 'demo-user-101'));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress Feed'),
        actions: [
          IconButton(
            icon: const Icon(Icons.compare_arrows_rounded, color: AppColors.primary),
            tooltip: 'Before / After Compare',
            onPressed: () => context.push('/progress/compare'),
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded, color: AppColors.primary),
            tooltip: 'Calendar View',
            onPressed: () => context.push('/progress/calendar'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.black,
        elevation: 4,
        onPressed: () => context.push('/camera'),
        child: const Icon(Icons.camera_alt_rounded, size: 28),
      ),
      body: photosAsync.when(
        data: (photos) {
          if (photos.isEmpty) {
            return EmptyStateView(
              icon: Icons.photo_camera_outlined,
              title: 'No Progress Records Yet',
              description: 'Capture your first post-workout photo to establish your baseline.',
              actionLabel: 'Take Progress Photo',
              onAction: () => context.push('/camera'),
            );
          }

          final filtered = _selectedFilter == 'All'
              ? photos
              : photos.where((p) => p.pose == _selectedFilter).toList();

          return Column(
            children: [
              // Filter Chips Row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: ['All', 'Front', 'Side', 'Back', 'Free'].map((filter) {
                    final isSelected = _selectedFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(filter),
                        selected: isSelected,
                        onSelected: (_) => setState(() => _selectedFilter = filter),
                        backgroundColor: AppColors.card,
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.black : AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                        side: BorderSide(
                          color: isSelected ? AppColors.primary : AppColors.divider,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              // Chronological List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final photo = filtered[index];
                    return _buildTimelineCard(photo);
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

  Widget _buildTimelineCard(ProgressPhoto photo) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Date & Pose Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.event_note_rounded, size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      DateFormatter.formatTimelineDate(photo.createdAt),
                      style: AppTypography.titleMedium,
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Text(
                    photo.pose,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Middle: Photo Thumbnail Mock + Details
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail Box
                Container(
                  width: 90,
                  height: 110,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E2436),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Center(
                    child: Icon(Icons.person_rounded, size: 42, color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: 16),

                // Data details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (photo.weightAtCapture != null) ...[
                        Row(
                          children: [
                            const Icon(Icons.scale_rounded, size: 16, color: AppColors.textMuted),
                            const SizedBox(width: 6),
                            Text(
                              '${photo.weightAtCapture} kg',
                              style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                      Row(
                        children: [
                          const Icon(Icons.fitness_center_rounded, size: 16, color: AppColors.accentLime),
                          const SizedBox(width: 6),
                          Text(
                            'Workout Logged',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.accentLime,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      if (photo.notes != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          '"${photo.notes}"',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodySmall.copyWith(
                            fontStyle: FontStyle.italic,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
