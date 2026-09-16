/// Abstract interface for progress observations and insights.
/// Designed so AI or on-device heuristic providers can be plugged in
/// without modifying UI components.
abstract class ProgressInsightService {
  Future<String> generateWorkoutInsight({
    required int workoutsThisWeek,
    required double totalVolumeKg,
    required int streakDays,
  });

  Future<String> generateVisualProgressTip({
    required int totalPhotos,
    required int daysSinceFirstPhoto,
  });
}

/// Production local heuristic implementation that operates 100% offline
/// with zero AI dependencies.
class LocalProgressInsightService implements ProgressInsightService {
  const LocalProgressInsightService();

  @override
  Future<String> generateWorkoutInsight({
    required int workoutsThisWeek,
    required double totalVolumeKg,
    required int streakDays,
  }) async {
    if (workoutsThisWeek == 0) {
      return "Ready to kick off this week's momentum? Log your first session today.";
    } else if (workoutsThisWeek >= 4) {
      return "Phenomenal consistency! You've logged $workoutsThisWeek workouts with a solid $streakDays-day streak.";
    } else {
      return "Steady pace! $workoutsThisWeek workouts logged so far this week. Keep your form sharp and rest well.";
    }
  }

  @override
  Future<String> generateVisualProgressTip({
    required int totalPhotos,
    required int daysSinceFirstPhoto,
  }) async {
    if (totalPhotos == 0) {
      return "Tip: Take your photo right after your workout in the same spot with consistent lighting for accurate visual comparisons.";
    } else if (totalPhotos < 5) {
      return "Standardizing your pose and distance between captures makes transformations unmistakable over time.";
    } else {
      return "Great visual history! Check out the Before/After comparator to inspect changes across your milestones.";
    }
  }
}
