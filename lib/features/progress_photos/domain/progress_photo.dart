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
  });

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
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'storagePath': storagePath,
      'downloadUrl': downloadUrl,
      'createdAt': createdAt.toIso8601String(),
      'workoutId': workoutId,
      'pose': pose,
      'weightAtCapture': weightAtCapture,
      'notes': notes,
    };
  }

  factory ProgressPhoto.fromMap(Map<String, dynamic> map, String id) {
    return ProgressPhoto(
      id: id,
      userId: map['userId'] as String? ?? '',
      storagePath: map['storagePath'] as String? ?? '',
      downloadUrl: map['downloadUrl'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      workoutId: map['workoutId'] as String?,
      pose: map['pose'] as String? ?? 'Front',
      weightAtCapture: (map['weightAtCapture'] as num?)?.toDouble(),
      notes: map['notes'] as String?,
    );
  }
}
