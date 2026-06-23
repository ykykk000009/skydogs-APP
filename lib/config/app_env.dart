class AppEnv {
  static const ttsEndpoint = String.fromEnvironment('TTS_ENDPOINT');
  static const openAiApiKey = String.fromEnvironment('OPENAI_API_KEY');
  static const openAiModel = String.fromEnvironment(
    'OPENAI_MODEL',
    defaultValue: 'gpt-4.1-mini',
  );
  static const analyticsEndpoint = String.fromEnvironment('ANALYTICS_ENDPOINT');
  static const crashEndpoint = String.fromEnvironment('CRASH_ENDPOINT');
  static const backendToken = String.fromEnvironment('BACKEND_TOKEN');
  static const audioBackendUrl = String.fromEnvironment(
    'AUDIO_BACKEND_URL',
    defaultValue: 'https://skydogs.top',
  );

  static bool get hasTts => ttsEndpoint.trim().isNotEmpty;
  static bool get hasOpenAi => openAiApiKey.trim().isNotEmpty;
  static bool get hasAnalytics => analyticsEndpoint.trim().isNotEmpty;
}
