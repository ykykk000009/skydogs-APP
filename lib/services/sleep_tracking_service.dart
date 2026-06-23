import 'dart:async';

import 'package:sensors_plus/sensors_plus.dart';
import 'package:uuid/uuid.dart';

import '../data/models/sleep_session.dart';

class SleepTrackingService {
  StreamSubscription<AccelerometerEvent>? _subscription;
  DateTime? _startedAt;
  AccelerometerEvent? _lastEvent;
  double _movementAccumulator = 0;
  int _sampleCount = 0;

  bool get isTracking => _subscription != null;

  Future<void> start() async {
    if (isTracking) {
      return;
    }

    _startedAt = DateTime.now();
    _lastEvent = null;
    _movementAccumulator = 0;
    _sampleCount = 0;

    _subscription =
        accelerometerEventStream(
          samplingPeriod: const Duration(milliseconds: 1200),
        ).listen((event) {
          if (_lastEvent != null) {
            _movementAccumulator +=
                (event.x - _lastEvent!.x).abs() +
                (event.y - _lastEvent!.y).abs() +
                (event.z - _lastEvent!.z).abs();
            _sampleCount += 1;
          }
          _lastEvent = event;
        });
  }

  Future<SleepSession?> stopAndBuildSession({
    String source = 'accelerometer',
  }) async {
    final startedAt = _startedAt;
    if (startedAt == null) {
      return null;
    }

    await _subscription?.cancel();
    _subscription = null;

    final endedAt = DateTime.now();
    _startedAt = null;

    final averageMotion = _sampleCount == 0
        ? 0.0
        : _movementAccumulator / _sampleCount;
    final normalized = (averageMotion / 4.5).clamp(0.0, 1.0);
    final movementScore = ((1 - normalized) * 100).toDouble();
    final restfulnessScore = (55 + movementScore * 0.45).clamp(0.0, 100.0);

    return SleepSession(
      id: const Uuid().v4(),
      startedAt: startedAt,
      endedAt: endedAt,
      trackingSource: source,
      movementScore: double.parse(movementScore.toStringAsFixed(1)),
      restfulnessScore: double.parse(restfulnessScore.toStringAsFixed(1)),
      notes: '基于设备加速度计的轻量估算结果。',
    );
  }

  Future<List<SleepSession>> importFromHealthSdk() async {
    return const <SleepSession>[];
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}
