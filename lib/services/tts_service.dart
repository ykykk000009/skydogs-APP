import 'package:dio/dio.dart';

import '../data/models/media_track.dart';

abstract class MeditationTtsService {
  String get providerLabel;

  bool get isConfigured;

  Future<MediaTrack?> generateTrack({
    required String title,
    required String script,
    required int accentColor,
  });
}

class DisabledMeditationTtsService implements MeditationTtsService {
  @override
  String get providerLabel => '内置冥想';

  @override
  bool get isConfigured => false;

  @override
  Future<MediaTrack?> generateTrack({
    required String title,
    required String script,
    required int accentColor,
  }) async {
    return null;
  }
}

class HttpMeditationTtsService implements MeditationTtsService {
  HttpMeditationTtsService({
    required Dio dio,
    required this.endpoint,
    required this.providerLabel,
  }) : _dio = dio;

  final Dio _dio;
  final String endpoint;

  @override
  final String providerLabel;

  @override
  bool get isConfigured => endpoint.trim().isNotEmpty;

  @override
  Future<MediaTrack?> generateTrack({
    required String title,
    required String script,
    required int accentColor,
  }) async {
    if (!isConfigured) {
      return null;
    }

    final response = await _dio.post<Map<String, dynamic>>(
      endpoint,
      data: <String, dynamic>{'title': title, 'text': script},
    );

    final audioUrl = response.data?['audioUrl'] as String?;
    if (audioUrl == null || audioUrl.isEmpty) {
      return null;
    }

    return MediaTrack(
      id: 'tts_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      subtitle: '由 $providerLabel 生成，可缓存到本地离线播放。',
      kind: TrackKind.meditation,
      category: '冥想',
      accentColor: accentColor,
      remoteUrl: audioUrl,
      script: script,
      builtIn: false,
      loop: false,
    );
  }
}
