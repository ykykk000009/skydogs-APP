class SleepSession {
  const SleepSession({
    required this.id,
    required this.startedAt,
    required this.endedAt,
    required this.trackingSource,
    required this.movementScore,
    required this.restfulnessScore,
    this.notes,
  });

  final String id;
  final DateTime startedAt;
  final DateTime endedAt;
  final String trackingSource;
  final double movementScore;
  final double restfulnessScore;
  final String? notes;

  Duration get duration => endedAt.difference(startedAt);

  String get qualityLabel {
    if (restfulnessScore >= 85) {
      return '恢复感很好';
    }
    if (restfulnessScore >= 70) {
      return '睡眠稳定';
    }
    if (restfulnessScore >= 55) {
      return '还可以再优化';
    }
    return '建议减少干扰';
  }

  SleepSession copyWith({
    String? id,
    DateTime? startedAt,
    DateTime? endedAt,
    String? trackingSource,
    double? movementScore,
    double? restfulnessScore,
    String? notes,
  }) {
    return SleepSession(
      id: id ?? this.id,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      trackingSource: trackingSource ?? this.trackingSource,
      movementScore: movementScore ?? this.movementScore,
      restfulnessScore: restfulnessScore ?? this.restfulnessScore,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'startedAt': startedAt.toIso8601String(),
      'endedAt': endedAt.toIso8601String(),
      'trackingSource': trackingSource,
      'movementScore': movementScore,
      'restfulnessScore': restfulnessScore,
      'notes': notes,
    };
  }

  factory SleepSession.fromJson(Map<String, dynamic> json) {
    return SleepSession(
      id: json['id'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String),
      endedAt: DateTime.parse(json['endedAt'] as String),
      trackingSource: json['trackingSource'] as String,
      movementScore: (json['movementScore'] as num?)?.toDouble() ?? 0,
      restfulnessScore: (json['restfulnessScore'] as num?)?.toDouble() ?? 0,
      notes: json['notes'] as String?,
    );
  }
}
