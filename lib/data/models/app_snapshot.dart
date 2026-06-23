import 'media_track.dart';
import 'mvp_models.dart';
import 'sleep_schedule.dart';
import 'sleep_session.dart';
import 'user_profile.dart';

class AppSnapshot {
  const AppSnapshot({
    required this.tracks,
    required this.sessions,
    required this.schedule,
    required this.profile,
    required this.account,
    required this.emergencyLogs,
    required this.personalScenes,
    required this.relationshipEvents,
    required this.ritualLogs,
    required this.aiAssist,
    this.playlistTrackIds = const <String>[],
    this.lastSyncedAt,
  });

  final List<MediaTrack> tracks;
  final List<SleepSession> sessions;
  final SleepSchedule schedule;
  final UserProfile profile;
  final UserAccount account;
  final List<NightEmergencyLog> emergencyLogs;
  final List<PersonalScene> personalScenes;
  final List<RelationshipEvent> relationshipEvents;
  final List<SleepRitualLog> ritualLogs;
  final AiAssistResult aiAssist;
  final List<String> playlistTrackIds;
  final DateTime? lastSyncedAt;

  AppSnapshot copyWith({
    List<MediaTrack>? tracks,
    List<SleepSession>? sessions,
    SleepSchedule? schedule,
    UserProfile? profile,
    UserAccount? account,
    List<NightEmergencyLog>? emergencyLogs,
    List<PersonalScene>? personalScenes,
    List<RelationshipEvent>? relationshipEvents,
    List<SleepRitualLog>? ritualLogs,
    AiAssistResult? aiAssist,
    List<String>? playlistTrackIds,
    DateTime? lastSyncedAt,
  }) {
    return AppSnapshot(
      tracks: tracks ?? this.tracks,
      sessions: sessions ?? this.sessions,
      schedule: schedule ?? this.schedule,
      profile: profile ?? this.profile,
      account: account ?? this.account,
      emergencyLogs: emergencyLogs ?? this.emergencyLogs,
      personalScenes: personalScenes ?? this.personalScenes,
      relationshipEvents: relationshipEvents ?? this.relationshipEvents,
      ritualLogs: ritualLogs ?? this.ritualLogs,
      aiAssist: aiAssist ?? this.aiAssist,
      playlistTrackIds: playlistTrackIds ?? this.playlistTrackIds,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'tracks': tracks.map((track) => track.toJson()).toList(),
      'sessions': sessions.map((session) => session.toJson()).toList(),
      'schedule': schedule.toJson(),
      'profile': profile.toJson(),
      'account': account.toJson(),
      'emergencyLogs': emergencyLogs.map((log) => log.toJson()).toList(),
      'personalScenes': personalScenes.map((scene) => scene.toJson()).toList(),
      'relationshipEvents': relationshipEvents
          .map((event) => event.toJson())
          .toList(),
      'ritualLogs': ritualLogs.map((log) => log.toJson()).toList(),
      'aiAssist': aiAssist.toJson(),
      'playlistTrackIds': playlistTrackIds,
      'lastSyncedAt': lastSyncedAt?.toIso8601String(),
    };
  }

  factory AppSnapshot.fromJson(Map<String, dynamic> json) {
    return AppSnapshot(
      tracks: (json['tracks'] as List<dynamic>? ?? const <dynamic>[])
          .map((item) => MediaTrack.fromJson(item as Map<String, dynamic>))
          .toList(),
      sessions: (json['sessions'] as List<dynamic>? ?? const <dynamic>[])
          .map((item) => SleepSession.fromJson(item as Map<String, dynamic>))
          .toList(),
      schedule: SleepSchedule.fromJson(
        json['schedule'] as Map<String, dynamic>? ?? const <String, dynamic>{},
      ),
      profile: UserProfile.fromJson(
        json['profile'] as Map<String, dynamic>? ?? const <String, dynamic>{},
      ),
      account: UserAccount.fromJson(
        json['account'] as Map<String, dynamic>? ?? const <String, dynamic>{},
      ),
      emergencyLogs:
          (json['emergencyLogs'] as List<dynamic>? ?? const <dynamic>[])
              .map(
                (item) =>
                    NightEmergencyLog.fromJson(item as Map<String, dynamic>),
              )
              .toList(),
      personalScenes:
          (json['personalScenes'] as List<dynamic>? ?? const <dynamic>[])
              .map(
                (item) => PersonalScene.fromJson(item as Map<String, dynamic>),
              )
              .toList(),
      relationshipEvents:
          (json['relationshipEvents'] as List<dynamic>? ?? const <dynamic>[])
              .map(
                (item) =>
                    RelationshipEvent.fromJson(item as Map<String, dynamic>),
              )
              .toList(),
      ritualLogs: (json['ritualLogs'] as List<dynamic>? ?? const <dynamic>[])
          .map((item) => SleepRitualLog.fromJson(item as Map<String, dynamic>))
          .toList(),
      aiAssist: AiAssistResult.fromJson(
        json['aiAssist'] as Map<String, dynamic>? ?? const <String, dynamic>{},
      ),
      playlistTrackIds:
          (json['playlistTrackIds'] as List<dynamic>? ?? const <dynamic>[])
              .map((item) => item.toString())
              .toList(growable: false),
      lastSyncedAt: json['lastSyncedAt'] == null
          ? null
          : DateTime.parse(json['lastSyncedAt'] as String),
    );
  }
}
