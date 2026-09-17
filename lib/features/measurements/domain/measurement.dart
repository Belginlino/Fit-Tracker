class BodyMeasurement {
  final String id;
  final String userId;
  final String
      type; // 'Weight', 'Chest', 'Waist', 'Hips', 'Left Arm', 'Right Arm', etc.
  final double value; // kg or cm
  final String unit; // 'kg' or 'cm' or '%'
  final DateTime recordedAt;
  final String? note;

  const BodyMeasurement({
    required this.id,
    required this.userId,
    required this.type,
    required this.value,
    required this.unit,
    required this.recordedAt,
    this.note,
  });

  BodyMeasurement copyWith({
    String? id,
    String? userId,
    String? type,
    double? value,
    String? unit,
    DateTime? recordedAt,
    String? note,
  }) {
    return BodyMeasurement(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      value: value ?? this.value,
      unit: unit ?? this.unit,
      recordedAt: recordedAt ?? this.recordedAt,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'value': value,
      'unit': unit,
      'recordedAt': recordedAt.toIso8601String(),
      'note': note,
    };
  }

  factory BodyMeasurement.fromMap(Map<String, dynamic> map, String id) {
    return BodyMeasurement(
      id: id,
      userId: map['userId'] as String? ?? '',
      type: map['type'] as String? ?? 'Weight',
      value: (map['value'] as num?)?.toDouble() ?? 0.0,
      unit: map['unit'] as String? ?? 'kg',
      recordedAt: map['recordedAt'] != null
          ? DateTime.tryParse(map['recordedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      note: map['note'] as String?,
    );
  }
}
