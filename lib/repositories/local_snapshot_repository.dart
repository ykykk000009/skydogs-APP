import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/app_snapshot.dart';
import '../data/models/media_track.dart';
import '../data/models/mvp_models.dart';
import '../data/models/user_profile.dart';
import '../data/models/sleep_schedule.dart';
import '../data/sources/sample_catalog.dart';

class LocalSnapshotRepository {
  LocalSnapshotRepository({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const _storageKey = 'skydogs.snapshot.v1';
  static const _legacyStorageKeys = <String>['sleepdog.snapshot.v1'];

  final SharedPreferencesAsync _preferences;

  Future<AppSnapshot> load() async {
    var raw = await _preferences.getString(_storageKey);
    if (raw == null || raw.trim().isEmpty) {
      for (final legacyKey in _legacyStorageKeys) {
        final legacyRaw = await _preferences.getString(legacyKey);
        if (legacyRaw != null && legacyRaw.trim().isNotEmpty) {
          raw = legacyRaw;
          await _preferences.setString(_storageKey, legacyRaw);
          break;
        }
      }
    }
    if (raw == null || raw.trim().isEmpty) {
      return AppSnapshot(
        tracks: SampleCatalog.seedTracks(),
        sessions: const [],
        schedule: SleepSchedule.defaults(),
        profile: UserProfile.defaults(),
        account: UserAccount.defaults(),
        emergencyLogs: _seedEmergencyLogs(),
        personalScenes: _seedPersonalScenes(),
        relationshipEvents: _seedRelationshipEvents(),
        ritualLogs: _seedRitualLogs(),
        aiAssist: AiAssistResult.empty(),
      );
    }

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    var snapshot = AppSnapshot.fromJson(decoded);
    if (snapshot.tracks.isEmpty) {
      snapshot = snapshot.copyWith(tracks: SampleCatalog.seedTracks());
    } else {
      snapshot = snapshot.copyWith(
        tracks: _mergeBuiltInTrackLabels(snapshot.tracks),
      );
    }
    if (snapshot.emergencyLogs.isEmpty) {
      snapshot = snapshot.copyWith(emergencyLogs: _seedEmergencyLogs());
    }
    if (snapshot.personalScenes.isEmpty) {
      snapshot = snapshot.copyWith(personalScenes: _seedPersonalScenes());
    }
    if (snapshot.relationshipEvents.isEmpty) {
      snapshot = snapshot.copyWith(
        relationshipEvents: _seedRelationshipEvents(),
      );
    }
    if (snapshot.ritualLogs.isEmpty) {
      snapshot = snapshot.copyWith(ritualLogs: _seedRitualLogs());
    }
    if (snapshot.aiAssist.recommendedSceneIds.isEmpty) {
      snapshot = snapshot.copyWith(aiAssist: AiAssistResult.empty());
    }
    return snapshot;
  }

  Future<void> save(AppSnapshot snapshot) async {
    final raw = jsonEncode(snapshot.toJson());
    await _preferences.setString(_storageKey, raw);
  }

  List<MediaTrack> _mergeBuiltInTrackLabels(List<MediaTrack> tracks) {
    final seeds = {
      for (final track in SampleCatalog.seedTracks()) track.id: track,
    };
    const cloudSoundIds = <String>{
      'rain_loop',
      'ocean_drift',
      'forest_night',
      'brown_noise',
    };
    return tracks
        .map((track) {
          final seed = seeds[track.id];
          if (seed != null && cloudSoundIds.contains(track.id)) {
            return seed.copyWith(cachedFilePath: track.cachedFilePath);
          }
          if (seed == null || !track.builtIn) {
            return track;
          }
          return track.copyWith(
            title: seed.title,
            subtitle: seed.subtitle,
            category: seed.category,
            accentColor: seed.accentColor,
          );
        })
        .toList(growable: false);
  }

  List<NightEmergencyLog> _seedEmergencyLogs() {
    final now = DateTime.now();
    return <NightEmergencyLog>[
      NightEmergencyLog(
        id: 'emergency_seed_1',
        state: NightEmergencyState.wantToContact,
        createdAt: now.subtract(const Duration(days: 1, hours: 2)),
        userMessage: '我只是想确认，对方是不是也难过。',
        actions: NightEmergencyState.wantToContact.actions,
        aiLetter: '这句话先留在这里。今晚不用发送，也不用证明自己还在乎。',
      ),
    ];
  }

  List<PersonalScene> _seedPersonalScenes() {
    return <PersonalScene>[
      PersonalScene(
        id: 'scene_no_turning_back',
        sceneName: '别回头',
        audioFiles: const <PersonalAudioFile>[
          PersonalAudioFile(
            fileName: 'rain_loop.wav',
            fileType: 'ambient',
            duration: 2700,
          ),
        ],
        textEntries: const <PersonalTextEntry>[
          PersonalTextEntry(content: '今晚先不联系，明天醒来再决定。', linkedAudio: true),
        ],
        images: const <PersonalImageEntry>[
          PersonalImageEntry(
            fileName: 'empty_chat.png',
            annotations: '不再反复打开聊天框',
          ),
        ],
        playbackOptions: PlaybackOptions.defaults(),
        styleKey: 'lavender',
      ),
      PersonalScene(
        id: 'scene_rain_sleep',
        sceneName: '雨夜睡眠',
        audioFiles: const <PersonalAudioFile>[
          PersonalAudioFile(
            fileName: 'ocean_drift.wav',
            fileType: 'natural',
            duration: 2400,
          ),
        ],
        textEntries: const <PersonalTextEntry>[
          PersonalTextEntry(content: '把注意力放回呼吸和身体。', linkedAudio: true),
        ],
        images: const <PersonalImageEntry>[],
        playbackOptions: PlaybackOptions.defaults(),
        styleKey: 'ocean',
      ),
    ];
  }

  List<RelationshipEvent> _seedRelationshipEvents() {
    final now = DateTime.now();
    return <RelationshipEvent>[
      RelationshipEvent(
        eventId: 'event_seed_1',
        eventType: RelationshipEventType.confirmed,
        timestamp: now.subtract(const Duration(days: 48)),
        content: '那天确定关系，也确定了很多期待。',
        emotion: RelationshipEmotion.relieved,
        factOrFantasy: FactOrFantasy.fact,
      ),
      RelationshipEvent(
        eventId: 'event_seed_2',
        eventType: RelationshipEventType.conflict,
        timestamp: now.subtract(const Duration(days: 13)),
        content: '争执后我开始反复猜测对方的每一句话。',
        emotion: RelationshipEmotion.sad,
        factOrFantasy: FactOrFantasy.fantasy,
      ),
      RelationshipEvent(
        eventId: 'event_seed_3',
        eventType: RelationshipEventType.breakup,
        timestamp: now.subtract(const Duration(days: 5)),
        content: '分开已经发生，今晚先处理自己的睡眠。',
        emotion: RelationshipEmotion.empty,
        factOrFantasy: FactOrFantasy.fact,
      ),
    ];
  }

  List<SleepRitualLog> _seedRitualLogs() {
    final now = DateTime.now();
    return <SleepRitualLog>[
      SleepRitualLog(
        id: 'ritual_seed_1',
        createdAt: now.subtract(const Duration(days: 2)),
        emotionRating: 2,
        unsayableSentence: '我还会想你，但我不必今晚解决一切。',
        soundSceneId: 'rain_loop',
        relaxationMinutes: 6,
        nextDayActionReminder: '早上出门走十分钟',
      ),
      SleepRitualLog(
        id: 'ritual_seed_2',
        createdAt: now.subtract(const Duration(days: 1)),
        emotionRating: 3,
        unsayableSentence: '我可以先照顾自己。',
        soundSceneId: 'ocean_drift',
        relaxationMinutes: 5,
        nextDayActionReminder: '不要翻旧聊天记录',
      ),
    ];
  }
}
