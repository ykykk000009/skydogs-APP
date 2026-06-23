import 'dart:developer' as developer;

abstract class AnalyticsService {
  Future<void> logEvent(String name, [Map<String, Object?> payload = const {}]);

  Future<void> logError(Object error, StackTrace stackTrace);
}

class ConsoleAnalyticsService implements AnalyticsService {
  @override
  Future<void> logEvent(
    String name, [
    Map<String, Object?> payload = const {},
  ]) async {
    developer.log('event=$name payload=$payload', name: 'SkyDogsAnalytics');
  }

  @override
  Future<void> logError(Object error, StackTrace stackTrace) async {
    developer.log(
      '$error',
      name: 'SkyDogsError',
      error: error,
      stackTrace: stackTrace,
    );
  }
}
