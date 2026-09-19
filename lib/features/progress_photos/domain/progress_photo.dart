class ProgressPhoto {
  final String id;
  final String userId;
  final String storagePath;
  final String? downloadUrl;
  final String? localFilePath;
  final DateTime createdAt;
  final String? workoutId;
  final String pose; // 'Front', 'Side', 'Back', 'Free'
  final double? weightAtCapture; // kg
  final String? notes;
  final int? dayNumber;

  const ProgressPhoto({
    required this.id,
    required this.userId,
    required this.storagePath,
    this.downloadUrl,
    this.localFilePath,
    required this.createdAt,
    this.workoutId,
    this.pose = 'Front',
    this.weightAtCapture,
    this.notes,
    this.dayNumber,
  });

  int get effectiveDayNumber =>
      dayNumber ?? _extractDayNumber(notes) ?? 1;

  String get dayLabel => 'Day $effectiveDayNumber';

  bool get isDayOne => effectiveDayNumber == 1;

  String? get cleanNotes {
    if (notes == null) return null;
    final cleaned = notes!.replaceAll(RegExp(r'\[Day\s*\d+\]\s*'), '').trim();
    return cleaned.isNotEmpty ? cleaned : null;
  }

  static int? extractDayNumber(String? text) => _extractDayNumber(text);

  static int? _extractDayNumber(String? text) {
    if (text == null) return null;
    final match = RegExp(r'\[Day\s*(\d+)\]', caseSensitive: false).firstMatch(text);
    if (match != null) {
      return int.tryParse(match.group(1) ?? '');
    }
    return null;
  }

  ProgressPhoto copyWith({
    String? id,
    String? userId,
    String? storagePath,
    String? downloadUrl,
    String? localFilePath,
    DateTime? createdAt,
    String? workoutId,
    String? pose,
    double? weightAtCapture,
    String? notes,
    int? dayNumber,
  }) {
    return ProgressPhoto(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      storagePath: storagePath ?? this.storagePath,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      localFilePath: localFilePath ?? this.localFilePath,
      createdAt: createdAt ?? this.createdAt,
      workoutId: workoutId ?? this.workoutId,
      pose: pose ?? this.pose,
      weightAtCapture: weightAtCapture ?? this.weightAtCapture,
      notes: notes ?? this.notes,
      dayNumber: dayNumber ?? this.dayNumber,
    );
  }

  Map<String, dynamic> toMap() {
    String? formattedNotes = notes;
    final resolvedDay = dayNumber ?? _extractDayNumber(notes);
    if (resolvedDay != null) {
      final base = cleanNotes ?? '';
      formattedNotes = base.isNotEmpty ? '[Day $resolvedDay] $base' : '[Day $resolvedDay]';
    }

    return {
      'id': id,
      'userId': userId,
      'storagePath': storagePath,
      'downloadUrl': downloadUrl,
      'localFilePath': localFilePath,
      'createdAt': createdAt.toIso8601String(),
      'workoutId': workoutId,
      'pose': pose,
      'weightAtCapture': weightAtCapture,
      'notes': formattedNotes,
      'dayNumber': resolvedDay,
      'day_number': resolvedDay,
    };
  }

  factory ProgressPhoto.fromMap(Map<String, dynamic> map, String id) {
    final notes = map['notes'] as String?;
    final explicitDay = (map['day_number'] ?? map['dayNumber']) as num?;
    final dayNumber = explicitDay?.toInt() ?? _extractDayNumber(notes);

    return ProgressPhoto(
      id: id,
      userId: map['userId'] as String? ?? map['user_id'] as String? ?? '',
      storagePath: map['storagePath'] as String? ?? map['storage_path'] as String? ?? '',
      downloadUrl: map['downloadUrl'] as String?,
      localFilePath: map['localFilePath'] as String? ?? map['local_file_path'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : map['created_at'] != null
              ? DateTime.tryParse(map['created_at'] as String) ?? DateTime.now()
              : DateTime.now(),
      workoutId: map['workoutId'] as String? ?? map['workout_id'] as String?,
      pose: map['pose'] as String? ?? 'Front',
      weightAtCapture: (map['weightAtCapture'] ?? map['weight_at_capture'] as num?)?.toDouble(),
      notes: notes,
      dayNumber: dayNumber,
    );
  }
}
