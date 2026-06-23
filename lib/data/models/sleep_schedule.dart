class SleepSchedule {
  const SleepSchedule({
    required this.bedtimeHour,
    required this.bedtimeMinute,
    required this.reminderEnabled,
    required this.timerMinutes,
    required this.healthSyncEnabled,
  });

  final int bedtimeHour;
  final int bedtimeMinute;
  final bool reminderEnabled;
  final int timerMinutes;
  final bool healthSyncEnabled;

  String get bedtimeLabel {
    final hour = bedtimeHour.toString().padLeft(2, '0');
    final minute = bedtimeMinute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  SleepSchedule copyWith({
    int? bedtimeHour,
    int? bedtimeMinute,
    bool? reminderEnabled,
    int? timerMinutes,
    bool? healthSyncEnabled,
  }) {
    return SleepSchedule(
      bedtimeHour: bedtimeHour ?? this.bedtimeHour,
      bedtimeMinute: bedtimeMinute ?? this.bedtimeMinute,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      timerMinutes: timerMinutes ?? this.timerMinutes,
      healthSyncEnabled: healthSyncEnabled ?? this.healthSyncEnabled,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'bedtimeHour': bedtimeHour,
      'bedtimeMinute': bedtimeMinute,
      'reminderEnabled': reminderEnabled,
      'timerMinutes': timerMinutes,
      'healthSyncEnabled': healthSyncEnabled,
    };
  }

  factory SleepSchedule.fromJson(Map<String, dynamic> json) {
    return SleepSchedule(
      bedtimeHour: json['bedtimeHour'] as int? ?? 22,
      bedtimeMinute: json['bedtimeMinute'] as int? ?? 45,
      reminderEnabled: json['reminderEnabled'] as bool? ?? false,
      timerMinutes: json['timerMinutes'] as int? ?? 45,
      healthSyncEnabled: json['healthSyncEnabled'] as bool? ?? false,
    );
  }

  factory SleepSchedule.defaults() {
    return const SleepSchedule(
      bedtimeHour: 22,
      bedtimeMinute: 45,
      reminderEnabled: false,
      timerMinutes: 45,
      healthSyncEnabled: false,
    );
  }
}
