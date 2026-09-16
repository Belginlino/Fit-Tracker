class WorkoutSet {
  final int setNumber;
  final double weight; // kg
  final int reps;
  final bool isCompleted;

  const WorkoutSet({
    required this.setNumber,
    required this.weight,
    required this.reps,
    this.isCompleted = true,
  });

  WorkoutSet copyWith({
    int? setNumber,
    double? weight,
    int? reps,
    bool? isCompleted,
  }) {
    return WorkoutSet(
      setNumber: setNumber ?? this.setNumber,
      weight: weight ?? this.weight,
      reps: reps ?? this.reps,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'setNumber': setNumber,
      'weight': weight,
      'reps': reps,
      'isCompleted': isCompleted,
    };
  }

  factory WorkoutSet.fromMap(Map<String, dynamic> map) {
    return WorkoutSet(
      setNumber: (map['setNumber'] as num?)?.toInt() ?? 1,
      weight: (map['weight'] as num?)?.toDouble() ?? 0.0,
      reps: (map['reps'] as num?)?.toInt() ?? 0,
      isCompleted: map['isCompleted'] as bool? ?? true,
    );
  }
}

class Exercise {
  final String name;
  final List<WorkoutSet> sets;
  final String? notes;

  const Exercise({
    required this.name,
    required this.sets,
    this.notes,
  });

  double get maxWeight {
    if (sets.isEmpty) return 0.0;
    return sets.map((s) => s.weight).reduce((a, b) => a > b ? a : b);
  }

  double get totalVolume {
    return sets.fold(0.0, (sum, s) => sum + (s.weight * s.reps));
  }

  Exercise copyWith({
    String? name,
    List<WorkoutSet>? sets,
    String? notes,
  }) {
    return Exercise(
      name: name ?? this.name,
      sets: sets ?? this.sets,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'sets': sets.map((s) => s.toMap()).toList(),
      'notes': notes,
    };
  }

  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      name: map['name'] as String? ?? 'Exercise',
      sets: (map['sets'] as List<dynamic>?)
              ?.map((e) => WorkoutSet.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      notes: map['notes'] as String?,
    );
  }
}

class Workout {
  final String id;
  final String userId;
  final String title;
  final DateTime date;
  final int durationMinutes;
  final List<Exercise> exercises;
  final String? notes;

  const Workout({
    required this.id,
    required this.userId,
    required this.title,
    required this.date,
    this.durationMinutes = 45,
    required this.exercises,
    this.notes,
  });

  double get totalVolumeKg {
    return exercises.fold(0.0, (sum, ex) => sum + ex.totalVolume);
  }

  int get totalSets {
    return exercises.fold(0, (sum, ex) => sum + ex.sets.length);
  }

  Workout copyWith({
    String? id,
    String? userId,
    String? title,
    DateTime? date,
    int? durationMinutes,
    List<Exercise>? exercises,
    String? notes,
  }) {
    return Workout(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      date: date ?? this.date,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      exercises: exercises ?? this.exercises,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'date': date.toIso8601String(),
      'durationMinutes': durationMinutes,
      'exercises': exercises.map((e) => e.toMap()).toList(),
      'notes': notes,
    };
  }

  factory Workout.fromMap(Map<String, dynamic> map, String id) {
    return Workout(
      id: id,
      userId: map['userId'] as String? ?? '',
      title: map['title'] as String? ?? 'Workout',
      date: map['date'] != null ? DateTime.tryParse(map['date'] as String) ?? DateTime.now() : DateTime.now(),
      durationMinutes: (map['durationMinutes'] as num?)?.toInt() ?? 45,
      exercises: (map['exercises'] as List<dynamic>?)
              ?.map((e) => Exercise.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      notes: map['notes'] as String?,
    );
  }
}
