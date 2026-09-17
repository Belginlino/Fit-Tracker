import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fittrack/app/theme/app_colors.dart';
import 'package:fittrack/app/theme/app_typography.dart';
import 'package:fittrack/core/utils/date_formatter.dart';
import 'package:fittrack/core/widgets/app_card.dart';
import 'package:fittrack/features/auth/data/auth_repository.dart';
import 'package:fittrack/features/workouts/data/workout_repository.dart';
import '../data/progress_photo_repository.dart';
import '../domain/progress_photo.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _currentMonth = DateTime.now();
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProfileProvider);
    final photosAsync =
        ref.watch(progressPhotosStreamProvider(user?.id ?? ''));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress Calendar'),
      ),
      body: photosAsync.when(
        data: (photos) {
          final workoutsAsync =
              ref.watch(workoutsStreamProvider(user?.id ?? ''));
          final workouts = workoutsAsync.value ?? [];
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Month Selector Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded, size: 28),
                      onPressed: () {
                        setState(() {
                          _currentMonth = DateTime(
                              _currentMonth.year, _currentMonth.month - 1);
                        });
                      },
                    ),
                    Text(
                      '${_getMonthName(_currentMonth.month)} ${_currentMonth.year}',
                      style: AppTypography.titleLarge,
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded, size: 28),
                      onPressed: () {
                        setState(() {
                          _currentMonth = DateTime(
                              _currentMonth.year, _currentMonth.month + 1);
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Calendar Grid
                AppCard(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      // Weekday Headers
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children:
                            ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((day) {
                          return SizedBox(
                            width: 38,
                            child: Text(
                              day,
                              textAlign: TextAlign.center,
                              style: AppTypography.bodySmall.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textMuted,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),

                      // Days of Month
                      _buildMonthDaysGrid(photos, workouts),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Legend
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLegendItem(
                        color: AppColors.accentLime, label: 'Workout'),
                    const SizedBox(width: 16),
                    _buildLegendItem(color: AppColors.primary, label: 'Photo'),
                    const SizedBox(width: 16),
                    _buildLegendItem(
                        color: AppColors.accentAmber, label: 'Both'),
                  ],
                ),
                const SizedBox(height: 24),

                // Selected Date Detail Section
                Text(
                  'Records for ${DateFormatter.formatTimelineDate(_selectedDate)}',
                  style: AppTypography.titleMedium,
                ),
                const SizedBox(height: 12),
                _buildSelectedDateDetails(photos, workouts),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildMonthDaysGrid(
      List<ProgressPhoto> photos, List<dynamic> workouts) {
    final firstDayOfMonth =
        DateTime(_currentMonth.year, _currentMonth.month, 1);
    final daysInMonth =
        DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final startWeekday = firstDayOfMonth.weekday; // 1 = Mon, 7 = Sun

    final totalCells = ((daysInMonth + startWeekday - 1) / 7).ceil() * 7;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: totalCells,
      itemBuilder: (context, index) {
        final dayNumber = index - startWeekday + 2;
        if (dayNumber < 1 || dayNumber > daysInMonth) {
          return const SizedBox.shrink();
        }

        final cellDate =
            DateTime(_currentMonth.year, _currentMonth.month, dayNumber);
        final isSelected = DateFormatter.isSameDay(cellDate, _selectedDate);
        final isToday = DateFormatter.isSameDay(cellDate, DateTime.now());

        // Check if there is photo on this date
        final hasPhoto = photos.any((p) =>
            p.createdAt.year == cellDate.year &&
            p.createdAt.month == cellDate.month &&
            p.createdAt.day == cellDate.day);
        final hasWorkout = workouts.any((w) =>
            w.date.year == cellDate.year &&
            w.date.month == cellDate.month &&
            w.date.day == cellDate.day);

        Color? dotColor;
        if (hasPhoto && hasWorkout) {
          dotColor = AppColors.accentAmber;
        } else if (hasWorkout) {
          dotColor = AppColors.accentLime;
        } else if (hasPhoto) {
          dotColor = AppColors.primary;
        }

        return GestureDetector(
          onTap: () => setState(() => _selectedDate = cellDate),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: isToday
                  ? Border.all(color: AppColors.primary, width: 1.5)
                  : (isSelected ? Border.all(color: AppColors.primary) : null),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$dayNumber',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isToday || isSelected
                        ? FontWeight.w800
                        : FontWeight.w500,
                    color:
                        isSelected ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
                if (dotColor != null) ...[
                  const SizedBox(height: 3),
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSelectedDateDetails(
      List<ProgressPhoto> photos, List<dynamic> workouts) {
    final dayPhotos = photos
        .where((p) =>
            p.createdAt.year == _selectedDate.year &&
            p.createdAt.month == _selectedDate.month &&
            p.createdAt.day == _selectedDate.day)
        .toList();
    final dayWorkouts = workouts
        .where((w) =>
            w.date.year == _selectedDate.year &&
            w.date.month == _selectedDate.month &&
            w.date.day == _selectedDate.day)
        .toList();

    if (dayPhotos.isEmpty && dayWorkouts.isEmpty) {
      return const AppCard(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text('No activity recorded on this date.',
                style: AppTypography.bodyMedium),
          ),
        ),
      );
    }

    return AppCard(
      child: Column(
        children: [
          ...dayWorkouts.map((w) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.accentLime.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.fitness_center_rounded,
                          color: AppColors.accentLime, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(w.title, style: AppTypography.titleMedium),
                          Text(
                              '${w.exercises.length} exercises · ${w.totalSets} sets · ${w.durationMinutes} min',
                              style: AppTypography.bodySmall),
                        ],
                      ),
                    ),
                    const Icon(Icons.check_circle_rounded,
                        color: AppColors.accentLime, size: 20),
                  ],
                ),
              )),
          if (dayWorkouts.isNotEmpty && dayPhotos.isNotEmpty)
            const Divider(height: 24),
          ...dayPhotos.map((p) => InkWell(
                onTap: () => context.push('/progress/preview', extra: {
                  'photoId': p.id,
                  'imagePath': p.localFilePath ?? p.downloadUrl ?? '',
                  'pose': p.pose,
                  'selectedDate': p.createdAt.toIso8601String(),
                  'dayNumber': p.effectiveDayNumber,
                  'notes': p.cleanNotes,
                  'isViewingExisting': true,
                }),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.photo_camera_rounded,
                            color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${p.pose} Pose Photo',
                                style: AppTypography.titleMedium),
                            Text(
                              p.weightAtCapture != null
                                  ? 'Weight: ${p.weightAtCapture!.toStringAsFixed(1)} kg'
                                  : 'Progress photo captured',
                              style: AppTypography.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded,
                            color: AppColors.error, size: 20),
                        tooltip: 'Delete Photo',
                        onPressed: () => _confirmDeletePhoto(p),
                      ),
                    ],
                  ),
                ),
              )),
        ],
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
          'Delete ${photo.dayLabel} (${photo.pose} pose) photo? It will be permanently removed.',
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

  Widget _buildLegendItem({required Color color, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: AppTypography.bodySmall),
      ],
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }
}
