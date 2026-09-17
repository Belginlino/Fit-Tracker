import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import 'neumorphic_container.dart';

enum StreakType { workout, photo }

class StreakBadge extends StatelessWidget {
  final int streakDays;
  final StreakType type;
  final bool compact;

  const StreakBadge({
    super.key,
    required this.streakDays,
    this.type = StreakType.workout,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isWorkout = type == StreakType.workout;
    final icon = isWorkout
        ? Icons.local_fire_department_rounded
        : Icons.photo_camera_rounded;
    const color = AppColors.primary; // Unify to primary teal for premium look
    final label = isWorkout ? 'Workout Streak' : 'Photo Streak';

    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              '$streakDays d',
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700, color: color),
            ),
          ],
        ),
      );
    }

    return NeumorphicContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: 16,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$streakDays Days',
                style: AppTypography.titleMedium
                    .copyWith(fontWeight: FontWeight.w800),
              ),
              Text(
                label,
                style: AppTypography.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
