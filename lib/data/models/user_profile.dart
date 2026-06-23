class UserProfile {
  const UserProfile({
    required this.selectedTrackId,
    required this.selectedMeditationId,
    required this.offlineOnly,
    required this.motionConsentAccepted,
    required this.analyticsConsentAccepted,
    required this.accessControlEnabled,
    required this.auditLogsEnabled,
  });

  final String selectedTrackId;
  final String selectedMeditationId;
  final bool offlineOnly;
  final bool motionConsentAccepted;
  final bool analyticsConsentAccepted;
  final bool accessControlEnabled;
  final bool auditLogsEnabled;

  UserProfile copyWith({
    String? selectedTrackId,
    String? selectedMeditationId,
    bool? offlineOnly,
    bool? motionConsentAccepted,
    bool? analyticsConsentAccepted,
    bool? accessControlEnabled,
    bool? auditLogsEnabled,
  }) {
    return UserProfile(
      selectedTrackId: selectedTrackId ?? this.selectedTrackId,
      selectedMeditationId: selectedMeditationId ?? this.selectedMeditationId,
      offlineOnly: offlineOnly ?? this.offlineOnly,
      motionConsentAccepted:
          motionConsentAccepted ?? this.motionConsentAccepted,
      analyticsConsentAccepted:
          analyticsConsentAccepted ?? this.analyticsConsentAccepted,
      accessControlEnabled: accessControlEnabled ?? this.accessControlEnabled,
      auditLogsEnabled: auditLogsEnabled ?? this.auditLogsEnabled,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'selectedTrackId': selectedTrackId,
      'selectedMeditationId': selectedMeditationId,
      'offlineOnly': offlineOnly,
      'motionConsentAccepted': motionConsentAccepted,
      'analyticsConsentAccepted': analyticsConsentAccepted,
      'accessControlEnabled': accessControlEnabled,
      'auditLogsEnabled': auditLogsEnabled,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      selectedTrackId: json['selectedTrackId'] as String? ?? 'rain_loop',
      selectedMeditationId:
          json['selectedMeditationId'] as String? ?? 'breath_reset',
      offlineOnly: json['offlineOnly'] as bool? ?? false,
      motionConsentAccepted: json['motionConsentAccepted'] as bool? ?? false,
      analyticsConsentAccepted:
          json['analyticsConsentAccepted'] as bool? ?? false,
      accessControlEnabled: json['accessControlEnabled'] as bool? ?? true,
      auditLogsEnabled: json['auditLogsEnabled'] as bool? ?? true,
    );
  }

  factory UserProfile.defaults() {
    return const UserProfile(
      selectedTrackId: 'rain_loop',
      selectedMeditationId: 'breath_reset',
      offlineOnly: false,
      motionConsentAccepted: false,
      analyticsConsentAccepted: false,
      accessControlEnabled: true,
      auditLogsEnabled: true,
    );
  }
}
