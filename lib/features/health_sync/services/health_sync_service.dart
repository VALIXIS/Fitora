import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/health_sync_models.dart';
import 'health_platform_connectors.dart';

class HealthSyncService {
  final SharedPreferences _prefs;
  final List<HealthPlatformConnector> _connectors;

  HealthSyncService(this._prefs)
      : _connectors = [
          GoogleFitConnector(),
          HealthConnectConnector(),
          SamsungHealthConnector(),
          AppleHealthConnector(),
        ];

  List<HealthPlatformConnector> get connectors => _connectors;

  // Key Constants
  static const String _kConnections = 'fitora_health_connections';
  static const String _kPriorities = 'fitora_health_priorities';
  static const String _kBgSyncEnabled = 'fitora_health_bg_sync';
  static const String _kBgSyncInterval = 'fitora_health_bg_sync_interval';
  static const String _kCacheSteps = 'fitora_health_cache_steps';
  static const String _kCacheHeart = 'fitora_health_cache_heart';
  static const String _kCacheCal = 'fitora_health_cache_calories';
  static const String _kCacheSleep = 'fitora_health_cache_sleep';
  static const String _kCacheTime = 'fitora_health_cache_time';

  // Load preferences and connections
  Map<HealthSource, HealthSourceConnectionState> loadConnections() {
    final Map<HealthSource, HealthSourceConnectionState> map = {};
    for (final src in HealthSource.values) {
      map[src] = HealthSourceConnectionState(source: src);
    }

    final rawJson = _prefs.getString(_kConnections);
    if (rawJson != null) {
      try {
        final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
        decoded.forEach((key, value) {
          final src = HealthSource.fromId(key);
          map[src] = HealthSourceConnectionState.fromJson(value as Map<String, dynamic>);
        });
      } catch (_) {
        // Fallback to defaults
      }
    }
    return map;
  }

  Future<void> saveConnections(Map<HealthSource, HealthSourceConnectionState> connections) async {
    final Map<String, dynamic> jsonMap = {};
    connections.forEach((key, value) {
      jsonMap[key.id] = value.toJson();
    });
    await _prefs.setString(_kConnections, jsonEncode(jsonMap));
  }

  List<HealthSource> loadPriorities() {
    final list = _prefs.getStringList(_kPriorities);
    if (list != null && list.isNotEmpty) {
      return list.map((id) => HealthSource.fromId(id)).toList();
    }
    // Default priority order
    return [
      HealthSource.appleHealth,
      HealthSource.healthConnect,
      HealthSource.googleFit,
      HealthSource.samsungHealth,
    ];
  }

  Future<void> savePriorities(List<HealthSource> priorities) async {
    final ids = priorities.map((e) => e.id).toList();
    await _prefs.setStringList(_kPriorities, ids);
  }

  bool loadBgSyncEnabled() {
    return _prefs.getBool(_kBgSyncEnabled) ?? true;
  }

  Future<void> saveBgSyncEnabled(bool enabled) async {
    await _prefs.setBool(_kBgSyncEnabled, enabled);
  }

  int loadBgSyncInterval() {
    return _prefs.getInt(_kBgSyncInterval) ?? 60;
  }

  Future<void> saveBgSyncInterval(int minutes) async {
    await _prefs.setInt(_kBgSyncInterval, minutes);
  }

  // Local caching of sync metrics
  HealthMetricData loadCachedData() {
    final steps = _prefs.getInt(_kCacheSteps) ?? 0;
    final heart = _prefs.getDouble(_kCacheHeart) ?? 0.0;
    final calories = _prefs.getDouble(_kCacheCal) ?? 0.0;
    final sleep = _prefs.getDouble(_kCacheSleep) ?? 0.0;
    final rawTime = _prefs.getString(_kCacheTime);

    final cacheTime = rawTime != null ? DateTime.tryParse(rawTime) : null;

    return HealthMetricData(
      steps: steps,
      heartRate: heart,
      activeCalories: calories,
      sleepHours: sleep,
      timestamp: cacheTime ?? DateTime.now(),
    );
  }

  Future<void> saveCachedData(HealthMetricData data) async {
    await _prefs.setInt(_kCacheSteps, data.steps);
    await _prefs.setDouble(_kCacheHeart, data.heartRate);
    await _prefs.setDouble(_kCacheCal, data.activeCalories);
    await _prefs.setDouble(_kCacheSleep, data.sleepHours);
    await _prefs.setString(_kCacheTime, data.timestamp.toIso8601String());
  }

  // Blending priorities engine
  HealthMetricData blendMetrics(List<HealthMetricData> activeMetrics, List<HealthSource> priorities) {
    if (activeMetrics.isEmpty) return HealthMetricData.empty();

    int finalSteps = 0;
    double finalHeartRate = 0.0;
    double finalCalories = 0.0;
    double finalSleep = 0.0;

    for (final metric in activeMetrics) {
      if (metric.steps > finalSteps) finalSteps = metric.steps;
      if (metric.heartRate > finalHeartRate) finalHeartRate = metric.heartRate;
      if (metric.activeCalories > finalCalories) finalCalories = metric.activeCalories;
      if (metric.sleepHours > finalSleep) finalSleep = metric.sleepHours;
    }

    return HealthMetricData(
      steps: finalSteps,
      heartRate: finalHeartRate,
      activeCalories: finalCalories,
      sleepHours: finalSleep,
      timestamp: DateTime.now(),
    );
  }

  // Sync with a specific source
  Future<HealthMetricData> syncSource(HealthSource source) async {
    final connector = _connectors.firstWhere((c) => c.source == source);
    final status = await connector.checkPermissionStatus();
    if (status != HealthPermissionStatus.authorized) {
      await connector.requestPermissions();
    }
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 1));
    return await connector.fetchMetrics(start, now);
  }
}
