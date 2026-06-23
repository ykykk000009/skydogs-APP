import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/services.dart';

import '../config/app_env.dart';
import '../repositories/local_snapshot_repository.dart';
import '../services/analytics_service.dart';
import '../services/archive_audio_service.dart';
import '../services/audio_playback_service.dart';
import '../services/offline_cache_service.dart';
import '../services/openai_assist_service.dart';
import '../services/reminder_service.dart';
import '../services/sleep_tracking_service.dart';
import '../services/tts_service.dart';
import '../state/sleep_app_controller.dart';

class AppBootstrap {
  const AppBootstrap({required this.controller});

  final SleepAppController controller;

  static Future<AppBootstrap> initialize() async {
    final dio = await _createDio();
    final repository = LocalSnapshotRepository();
    final audioPlaybackService = AudioPlaybackService();
    final archiveAudioService = ArchiveAudioService(
      dio: dio,
      backendBaseUrl: AppEnv.audioBackendUrl,
    );
    final offlineCacheService = OfflineCacheService(dio: dio);
    final reminderService = ReminderService();
    final sleepTrackingService = SleepTrackingService();
    final analyticsService = ConsoleAnalyticsService();
    final aiAssistService = BackendAiAssistService(
      dio: dio,
      backendBaseUrl: AppEnv.audioBackendUrl,
    );

    final ttsService = AppEnv.hasTts
        ? HttpMeditationTtsService(
            dio: dio,
            endpoint: AppEnv.ttsEndpoint,
            providerLabel: '百度 / 讯飞代理',
          )
        : DisabledMeditationTtsService();

    await audioPlaybackService.initialize();
    await reminderService.initialize();

    final controller = SleepAppController(
      repository: repository,
      audioPlaybackService: audioPlaybackService,
      archiveAudioService: archiveAudioService,
      offlineCacheService: offlineCacheService,
      reminderService: reminderService,
      sleepTrackingService: sleepTrackingService,
      aiAssistService: aiAssistService,
      ttsService: ttsService,
      analyticsService: analyticsService,
    );

    await controller.initialize();
    return AppBootstrap(controller: controller);
  }

  static Future<Dio> _createDio() async {
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 8),
        sendTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 18),
      ),
    );

    final context = SecurityContext(withTrustedRoots: true);
    final rootBytes = await rootBundle.load('assets/certs/isrgrootx1.pem');
    context.setTrustedCertificatesBytes(rootBytes.buffer.asUint8List());
    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () => HttpClient(context: context)
        ..badCertificateCallback = (certificate, host, port) {
          return (host == 'skydogs.top' || host == '115.29.232.99') &&
              port == 443 &&
              certificate.sha1
                      .map(
                        (byte) => byte
                            .toRadixString(16)
                            .padLeft(2, '0')
                            .toUpperCase(),
                      )
                      .join(':') ==
                  'AC:54:A4:EE:CE:82:72:25:81:94:ED:DC:8D:6D:9D:D8:AA:F8:41:88';
        },
    );

    return dio;
  }
}
