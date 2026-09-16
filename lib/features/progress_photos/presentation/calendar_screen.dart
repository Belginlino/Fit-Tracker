import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fittrack/app/theme/app_colors.dart';
import 'package:fittrack/app/theme/app_typography.dart';
import 'package:fittrack/core/utils/date_formatter.dart';
import 'package:fittrack/core/widgets/app_card.dart';
import 'package:fittrack/features/auth/data/auth_repository.dart';
import '../data/progress_photo_repository.dart';

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
    final photosAsync = ref.watch(progressPhotosStreamProvider(user?.id ?? 'demo-user-101'));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress Calendar'),
      ),
      body: photosAsync.when(
        data: (photos) {
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
                          _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
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
                          _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
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
                        children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((day) {
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
                      _buildMonthDaysGrid(photos),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Legend
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLegendItem(color: AppColors.accentLime, label: 'Workout'),
                    const SizedBox(width: 16),
                    _buildLegendItem(color: AppColors.primary, label: 'Photo'),
                    const SizedBox(width: 16),
                    _buildLegendItem(color: AppColors.accentAmber, label: 'Both'),
                  ],
                ),
                const SizedBox(height: 24),

                // Selected Date Detail Section
                Text(
                  'Records for ${DateFormatter.formatTimelineDate(_selectedDate)}',
                  style: AppTypography.titleMedium,
                ),
                const SizedBox(height: 12),
                _buildSelectedDateDetails(photos),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildMonthDaysGrid(List<dynamic> photos) {
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
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

        final cellDate = DateTime(_currentMonth.year, _currentMonth.month, dayNumber);
        final isSelected = DateFormatter.isSameDay(cellDate, _selectedDate);
        final isToday = DateFormatter.isSameDay(cellDate, DateTime.now());

        // Check if there is photo on this date
        final hasPhoto = dayNumber % 3 == 0 || isToday; // demo active activity
        final hasWorkout = dayNumber % 2 == 0 || isToday;

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
              color: isSelected ? AppColors.primary.withOpacity(0.2) : Colors.transparent,
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
                    fontWeight: isToday || isSelected ? FontWeight.w800 : FontWeight.w500,
                    color: isSelected ? AppColors.primary : AppColors.textPrimary,
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

  Widget _buildSelectedDateDetails(List<dynamic> photos) {
    return AppCard(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accentLime.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.fitness_center_rounded, color: AppColors.accentLime, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Chest + Triceps', style: AppTypography.titleMedium),
                    Text('4 exercises · 12 sets · 48 min', style: AppTypography.bodySmall),
                  ],
                ),
              ),
              const Icon(Icons.check_circle_rounded, color: AppColors.accentLime, size: 20),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.photo_camera_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Front Pose Photo', style: AppTypography.titleMedium),
                    Text('Weight: 74.2 kg · Saved to Private Cloud', style: AppTypography.bodySmall),
                  ],
                ),
              ),
              const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
            ],
          ),
        ],
      ),
    );
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
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
}
