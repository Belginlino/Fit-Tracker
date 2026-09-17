class UserProfile {
  final String id;
  final String email;
  final String name;
  final String goal; // "Build Muscle", "Lose Fat", "Improve Strength", etc.
  final double currentWeight; // kg
  final double height; // cm
  final double targetWeight; // kg
  final List<String> preferredWorkoutDays;
  final String reminderTime; // "18:00"
  final int workoutStreak;
  final int photoStreak;
  final bool hasCompletedOnboarding;
  final DateTime createdAt;

  const UserProfile({
    required this.id,
    required this.email,
    required this.name,
    this.goal = 'Build Muscle',
    this.currentWeight = 74.2,
    this.height = 178.0,
    this.targetWeight = 78.0,
    this.preferredWorkoutDays = const ['Mon', 'Tue', 'Thu', 'Fri'],
    this.reminderTime = '18:00',
    this.workoutStreak = 0,
    this.photoStreak = 0,
    this.hasCompletedOnboarding = true,
    required this.createdAt,
  });

  UserProfile copyWith({
    String? id,
    String? email,
    String? name,
    String? goal,
    double? currentWeight,
    double? height,
    double? targetWeight,
    List<String>? preferredWorkoutDays,
    String? reminderTime,
    int? workoutStreak,
    int? photoStreak,
    bool? hasCompletedOnboarding,
    DateTime? createdAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      goal: goal ?? this.goal,
      currentWeight: currentWeight ?? this.currentWeight,
      height: height ?? this.height,
      targetWeight: targetWeight ?? this.targetWeight,
      preferredWorkoutDays: preferredWorkoutDays ?? this.preferredWorkoutDays,
      reminderTime: reminderTime ?? this.reminderTime,
      workoutStreak: workoutStreak ?? this.workoutStreak,
      photoStreak: photoStreak ?? this.photoStreak,
      hasCompletedOnboarding:
          hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'goal': goal,
      'currentWeight': currentWeight,
      'height': height,
      'targetWeight': targetWeight,
      'preferredWorkoutDays': preferredWorkoutDays,
      'reminderTime': reminderTime,
      'workoutStreak': workoutStreak,
      'photoStreak': photoStreak,
      'hasCompletedOnboarding': hasCompletedOnboarding,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map, String id) {
    final daysRaw = map['preferredWorkoutDays'] ??
        map['preferred_days'] ??
        map['preferred_workout_days'];
    List<String> days = const ['Mon', 'Tue', 'Thu', 'Fri'];
    if (daysRaw is List) {
      days = daysRaw.map((e) => e.toString()).toList();
    } else if (daysRaw is String) {
      try {
        final decoded = daysRaw
            .replaceAll('[', '')
            .replaceAll(']', '')
            .replaceAll('"', '')
            .split(',');
        days = decoded.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      } catch (_) {}
    }

    return UserProfile(
      id: id,
      email: map['email'] as String? ?? '',
      name: map['name'] as String? ?? 'Athlete',
      goal: map['goal'] as String? ?? 'Build Muscle',
      currentWeight: ((map['currentWeight'] ?? map['current_weight']) as num?)
              ?.toDouble() ??
          74.2,
      height: (map['height'] as num?)?.toDouble() ?? 178.0,
      targetWeight:
          ((map['targetWeight'] ?? map['target_weight']) as num?)?.toDouble() ??
              78.0,
      preferredWorkoutDays: days,
      reminderTime: (map['reminderTime'] ??
              map['preferred_reminder_time'] ??
              map['reminder_time']) as String? ??
          '18:00',
      workoutStreak:
          ((map['workoutStreak'] ?? map['workout_streak']) as num?)?.toInt() ??
              0,
      photoStreak:
          ((map['photoStreak'] ?? map['photo_streak']) as num?)?.toInt() ?? 0,
      hasCompletedOnboarding: (map['hasCompletedOnboarding'] ??
                  map['has_completed_onboarding']) ==
              1 ||
          (map['hasCompletedOnboarding'] ?? map['has_completed_onboarding']) ==
              true,
      createdAt: (map['createdAt'] ?? map['created_at']) != null
          ? DateTime.tryParse(
                  (map['createdAt'] ?? map['created_at']) as String) ??
              DateTime.now()
          : DateTime.now(),
    );
  }
}
