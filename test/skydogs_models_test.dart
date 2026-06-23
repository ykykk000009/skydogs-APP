import 'package:flutter_test/flutter_test.dart';
import 'package:skydogs/data/models/media_track.dart';
import 'package:skydogs/data/models/mvp_models.dart';
import 'package:skydogs/data/models/sleep_schedule.dart';
import 'package:skydogs/data/models/sleep_session.dart';

void main() {
  test('sleep schedule formats bedtime label', () {
    const schedule = SleepSchedule(
      bedtimeHour: 22,
      bedtimeMinute: 5,
      reminderEnabled: true,
      timerMinutes: 45,
      healthSyncEnabled: false,
    );

    expect(schedule.bedtimeLabel, '22:05');
  });

  test('media track treats built-in asset as offline ready', () {
    const track = MediaTrack(
      id: 'rain',
      title: 'Rain',
      subtitle: 'Quiet rain',
      kind: TrackKind.soundscape,
      category: 'ambient',
      accentColor: 0xFF000000,
      assetPath: 'assets/audio/ambient/rain_loop.wav',
      builtIn: true,
    );

    expect(track.isOfflineReady, isTrue);
    expect(track.hasPlayableSource, isTrue);
  });

  test('sleep session copyWith overrides notes only', () {
    final session = SleepSession(
      id: '1',
      startedAt: DateTime(2026, 5, 19, 22, 0),
      endedAt: DateTime(2026, 5, 19, 22, 45),
      trackingSource: 'accelerometer',
      movementScore: 80,
      restfulnessScore: 88,
      notes: 'baseline',
    );

    final updated = session.copyWith(notes: 'updated');

    expect(updated.notes, 'updated');
    expect(updated.restfulnessScore, 88);
    expect(updated.duration.inMinutes, 45);
  });

  test('night emergency log round trips actions and AI letter', () {
    final log = NightEmergencyLog(
      id: '1',
      state: NightEmergencyState.wantToContact,
      createdAt: DateTime(2026, 5, 19, 1, 30),
      userMessage: 'I want to contact them',
      actions: NightEmergencyState.wantToContact.actions,
      aiLetter: 'Write it here, do not send it tonight.',
    );

    final decoded = NightEmergencyLog.fromJson(log.toJson());

    expect(decoded.state.label, '想联系对方');
    expect(decoded.actions, contains('生成不发送的信'));
    expect(decoded.aiLetter, contains('do not send'));
  });

  test('relationship event keeps fact or fantasy label', () {
    final event = RelationshipEvent(
      eventId: 'event',
      eventType: RelationshipEventType.breakup,
      timestamp: DateTime(2026, 5, 19),
      content: 'A clear event',
      emotion: RelationshipEmotion.empty,
      factOrFantasy: FactOrFantasy.fact,
    );

    final decoded = RelationshipEvent.fromJson(event.toJson());

    expect(decoded.eventType.label, '分手');
    expect(decoded.factOrFantasy.label, '事实');
  });

  test('personal text entry preserves Chinese and emoji', () {
    const entry = PersonalTextEntry(
      content: '今晚先不发消息，明天再照顾自己 💤',
      linkedAudio: true,
    );

    final decoded = PersonalTextEntry.fromJson(entry.toJson());

    expect(decoded.content, '今晚先不发消息，明天再照顾自己 💤');
    expect(decoded.linkedAudio, isTrue);
  });
}
