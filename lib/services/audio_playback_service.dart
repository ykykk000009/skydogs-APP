import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';

import '../data/models/media_track.dart';

class AudioPlaybackService {
  AudioPlaybackService() : _player = AudioPlayer();

  final AudioPlayer _player;
  String? _currentTrackId;

  String? get currentTrackId => _currentTrackId;

  bool get isPlaying => _player.playing;

  Stream<bool> get playingStream => _player.playingStream;

  Stream<Duration> get positionStream => _player.positionStream;

  Stream<Duration?> get durationStream => _player.durationStream;

  Stream<void> get completedStream => _player.processingStateStream
      .where((state) => state == ProcessingState.completed)
      .map((_) {});

  Future<void> initialize() async {
    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration.music());
    await _player.setVolume(1);
  }

  Future<void> play(MediaTrack track) async {
    if (track.cachedFilePath?.isNotEmpty ?? false) {
      if (track.cachedFilePath!.startsWith('content://')) {
        await _player.setUrl(track.cachedFilePath!);
      } else {
        await _player.setFilePath(track.cachedFilePath!);
      }
    } else if (track.assetPath?.isNotEmpty ?? false) {
      await _player.setAsset(track.assetPath!);
    } else if (track.remoteUrl?.isNotEmpty ?? false) {
      await _player.setUrl(
        track.remoteUrl!,
        headers: const <String, String>{
          'User-Agent': 'SkyDogs/0.1 Flutter audio player',
          'Accept': 'audio/mpeg,audio/mp4,audio/*;q=0.9,*/*;q=0.8',
        },
      );
    } else {
      throw StateError('Track ${track.id} has no playable source.');
    }

    _currentTrackId = track.id;
    await _player.setLoopMode(track.loop ? LoopMode.one : LoopMode.off);
    await _player.play();
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> stop() async {
    await _player.stop();
  }

  Future<void> toggle(MediaTrack track) async {
    if (_currentTrackId == track.id && _player.playing) {
      await pause();
      return;
    }

    await play(track);
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}
