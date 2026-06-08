import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _stepEventChannel = EventChannel('com.example.fitora/step_counter');
const _debugMethodChannel = MethodChannel('com.example.fitora/step_debug');

final sensorRepositoryProvider = Provider<SensorRepository>((ref) {
  return SensorRepository();
});

/// Holds a debug snapshot from the native sensor plugin.
class SensorDebugSnapshot {
  final int rawSteps;
  final int todaySteps;
  final int baseline;
  final DateTime? lastEventTime;
  final bool sensorAvailable;

  const SensorDebugSnapshot({
    required this.rawSteps,
    required this.todaySteps,
    required this.baseline,
    required this.lastEventTime,
    required this.sensorAvailable,
  });

  factory SensorDebugSnapshot.empty() => const SensorDebugSnapshot(
        rawSteps: -1,
        todaySteps: 0,
        baseline: -1,
        lastEventTime: null,
        sensorAvailable: false,
      );
}

/// Exposes the native Android TYPE_STEP_COUNTER sensor as a Dart stream.
///
/// The Kotlin plugin handles:
///   - Computing today's steps from the cumulative raw sensor value
///   - Persisting the daily baseline across app restarts
///   - Midnight reset detection
class SensorRepository {
  Stream<int>? _stepStream;

  /// A broadcast stream of today's step count.
  /// Emits nothing (never emits) when the sensor is unavailable.
  Stream<int> get stepStream {
    _stepStream ??= _stepEventChannel
        .receiveBroadcastStream()
        .map<int>((event) => (event as num).toInt())
        .where((steps) => steps >= 0) // Guard against negative values
        .handleError((_) {}); // Silently swallow sensor errors
    return _stepStream!;
  }

  /// One-shot snapshot: returns the latest step count immediately, or null if unavailable.
  Future<int?> getCurrentSteps() async {
    try {
      final snap = await getDebugSnapshot();
      if (!snap.sensorAvailable) return null;
      if (snap.todaySteps >= 0) return snap.todaySteps;

      // Fallback if snapshot is missing but stream works
      return await stepStream.first
          .timeout(const Duration(seconds: 4), onTimeout: () => 0)
          .then((v) => v < 0 ? 0 : v);
    } catch (_) {
      return null;
    }
  }

  /// Fetches a debug snapshot from the native plugin.
  /// Returns [SensorDebugSnapshot.empty()] on any error.
  Future<SensorDebugSnapshot> getDebugSnapshot() async {
    try {
      final raw = await _debugMethodChannel.invokeMethod<Map>('getDebugSnapshot');
      if (raw == null) return SensorDebugSnapshot.empty();

      final lastEventMs = raw['lastEventMs'] as int? ?? 0;
      return SensorDebugSnapshot(
        rawSteps: raw['rawSteps'] as int? ?? -1,
        todaySteps: raw['todaySteps'] as int? ?? 0,
        baseline: raw['baseline'] as int? ?? -1,
        lastEventTime: lastEventMs > 0
            ? DateTime.fromMillisecondsSinceEpoch(lastEventMs)
            : null,
        sensorAvailable: raw['sensorAvailable'] as bool? ?? false,
      );
    } catch (_) {
      return SensorDebugSnapshot.empty();
    }
  }
}
