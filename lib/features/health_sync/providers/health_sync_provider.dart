import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitora/core/health/domain/health_models.dart' hide SyncStatus;
import 'package:fitora/core/health/services/health_cache_service.dart';

import '../../../core/storage/app_preferences.dart';
import '../domain/health_sync_models.dart';
import '../services/health_sync_service.dart';
import '../services/health_platform_connectors.dart';
import '../services/pedometer_service.dart';

final healthSyncProvider = StateNotifierProvider<HealthSyncController, HealthSyncState>((ref) {
  return HealthSyncController()..load();
});

class HealthSyncController extends StateNotifier<HealthSyncState> with WidgetsBindingObserver {
  HealthSyncController()
      : super(HealthSyncState(
          connections: {},
          priorities: [],
          cachedData: HealthMetricData.empty(),
        )) {
    WidgetsBinding.instance.addObserver(this);
  }

  late final HealthSyncService _service;
  bool _initialized = false;
  StreamSubscription<int>? _pedometerSubscription;
  Timer? _saveDebounceTimer;

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_saveDebounceTimer?.isActive ?? false) {
      _saveDebounceTimer?.cancel();
      if (_initialized) {
        _service.saveCachedData(state.cachedData);
      }
    }
    _pedometerSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      if (_saveDebounceTimer?.isActive ?? false) {
        _saveDebounceTimer?.cancel();
        if (_initialized) {
          _service.saveCachedData(this.state.cachedData);
        }
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_initialized) {
        syncAllActive();
      }
    }
  }

  Future<void> load() async {
    if (_initialized) return;

    final prefs = await AppPreferences.instance();
    _service = HealthSyncService(prefs);

    final connections = Map<HealthSource, HealthSourceConnectionState>.from(_service.loadConnections());
    final priorities = _service.loadPriorities();
    final bgSyncEnabled = _service.loadBgSyncEnabled();
    final bgSyncInterval = _service.loadBgSyncInterval();
    final cachedData = _service.loadCachedData();

    try {
      final hcConnector = HealthConnectConnector();
      final perm = await hcConnector.checkPermissionStatus();
      if (perm == HealthPermissionStatus.authorized) {
        final existing = connections[HealthSource.healthConnect] ?? HealthSourceConnectionState(source: HealthSource.healthConnect);
        connections[HealthSource.healthConnect] = existing.copyWith(
          isConnected: true,
          permissionStatus: HealthPermissionStatus.authorized,
        );
        final existingGfit = connections[HealthSource.googleFit] ?? HealthSourceConnectionState(source: HealthSource.googleFit);
        connections[HealthSource.googleFit] = existingGfit.copyWith(
          isConnected: true,
          permissionStatus: HealthPermissionStatus.authorized,
        );
      }
    } catch (_) {}

    state = HealthSyncState(
      connections: connections,
      priorities: priorities,
      cachedData: cachedData,
      isBackgroundSyncEnabled: bgSyncEnabled,
      syncIntervalMinutes: bgSyncInterval,
      isSyncing: false,
    );

    _initialized = true;

    // Set up step stream listener for real-time live step tracking updates
    PedometerService().setInitialSteps(cachedData.steps);
    _pedometerSubscription?.cancel();
    _pedometerSubscription = PedometerService().stepStream.listen((realtimeSteps) {
      if (realtimeSteps < 0) return;

      final hasActiveConnectedSource = state.connections.values.any(
        (c) => c.isConnected && c.permissionStatus == HealthPermissionStatus.authorized,
      );
      if (hasActiveConnectedSource) {
        final currentSteps = state.cachedData.steps;
        final lastTime = state.cachedData.timestamp;
        final now = DateTime.now();
        final isSameDay = lastTime.year == now.year &&
            lastTime.month == now.month &&
            lastTime.day == now.day;
        final updatedSteps = isSameDay ? max(currentSteps, realtimeSteps) : realtimeSteps;

        state = state.copyWith(
          cachedData: state.cachedData.copyWith(
            steps: updatedSteps,
            timestamp: now,
          ),
        );

        // Debounce local persistence to prevent race conditions during frequent updates
        _saveDebounceTimer?.cancel();
        _saveDebounceTimer = Timer(const Duration(seconds: 1), () async {
          await _service.saveCachedData(state.cachedData);
          try {
            final cacheService = HealthCacheService(AppPreferences.prefs);
            final today = DateTime(now.year, now.month, now.day);
            final existingDaily = cacheService.getDailyActivity(today) ?? DailyActivitySummary.empty(date: today);
            if (updatedSteps > existingDaily.steps) {
              await cacheService.saveDailyActivity(existingDaily.copyWith(steps: updatedSteps, lastSyncTime: now));
            }
          } catch (_) {}
        });
      }
    });

    // Automatically trigger initial background sync simulation if at least one connected source exists
    final hasActiveConnection = connections.values.any((c) => c.isConnected);
    if (hasActiveConnection) {
      await syncAllActive();
    }
  }

  Future<void> toggleSourceConnection(HealthSource source) async {
    await load(); // Ensure initialized
    final conn = state.connections[source] ?? HealthSourceConnectionState(source: source);

    if (conn.isConnected) {
      await disconnectSource(source);
      return;
    }

    state = state.copyWith(isSyncing: true, syncError: null);

    try {
      try {
        final connector = _service.connectors.firstWhere((c) => c.source == source);
        await connector.requestPermissions();
      } catch (_) {}

      try {
        await PedometerService().requestPermissions();
      } catch (_) {}

      final updatedConn = conn.copyWith(
        isConnected: true,
        permissionStatus: HealthPermissionStatus.authorized,
        lastSyncStatus: SyncStatus.success,
        lastSyncTime: DateTime.now(),
      );

      final updatedConnections = Map<HealthSource, HealthSourceConnectionState>.from(state.connections);
      updatedConnections[source] = updatedConn;
      if (source == HealthSource.healthConnect || source == HealthSource.googleFit) {
        updatedConnections[HealthSource.healthConnect] = (updatedConnections[HealthSource.healthConnect] ?? HealthSourceConnectionState(source: HealthSource.healthConnect)).copyWith(
          isConnected: true,
          permissionStatus: HealthPermissionStatus.authorized,
        );
        updatedConnections[HealthSource.googleFit] = (updatedConnections[HealthSource.googleFit] ?? HealthSourceConnectionState(source: HealthSource.googleFit)).copyWith(
          isConnected: true,
          permissionStatus: HealthPermissionStatus.authorized,
        );
      }

      state = state.copyWith(connections: updatedConnections);
      await _service.saveConnections(updatedConnections);

      await syncAllActive();
    } catch (e) {
      state = state.copyWith(syncError: 'Could not connect ${source.label}');
    } finally {
      state = state.copyWith(isSyncing: false);
    }
  }

  Future<void> disconnectSource(HealthSource source) async {
    await load();
    final conn = state.connections[source];
    if (conn == null || !conn.isConnected) return;

    final updatedConn = conn.copyWith(
      isConnected: false,
      permissionStatus: HealthPermissionStatus.notDetermined,
      lastSyncStatus: SyncStatus.idle,
    );

    final updatedConnections = Map<HealthSource, HealthSourceConnectionState>.from(state.connections);
    updatedConnections[source] = updatedConn;

    state = state.copyWith(connections: updatedConnections);
    await _service.saveConnections(updatedConnections);
  }

  Future<void> syncAllActive() async {
    await load();

    final connectedSources = state.connections.values
        .where((c) => c.isConnected)
        .map((c) => c.source)
        .toList();

    if (kDebugMode) {
      print('[HC_DEBUG] Sync started, connected sources: ${connectedSources.map((s) => s.label).join(", ")}');
    }

    state = state.copyWith(isSyncing: true, syncError: null);

    final updatedConnections = Map<HealthSource, HealthSourceConnectionState>.from(state.connections);

    try {
      // Single direct read from Health Connect regardless of which sources are toggled.
      // All Android sources (Google Fit, Samsung, HC) share the same HC backend.
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      if (kDebugMode) print('[HC_DEBUG] Reading from HealthConnectRepository...');

      // Step read — MUST succeed for any useful data
      final hcDaily = await sharedHcRepo.getDailyActivity(now);

      if (kDebugMode) {
        print('[HC_DEBUG] HC steps read: steps=${hcDaily.steps}, cal=${hcDaily.caloriesBurned}, dist=${hcDaily.distanceKm}');
      }

      // Sleep read — optional, don't let failure kill the sync
      SleepSummary? hcSleep;
      try {
        hcSleep = await sharedHcRepo.getSleepSummary(now);
        if (kDebugMode) print('[HC_DEBUG] HC sleep: ${hcSleep.totalSleep.inMinutes} min');
      } catch (e) {
        if (kDebugMode) print('[HC_DEBUG] Sleep read failed (non-fatal): $e');
      }

      final sleepHours = (hcSleep?.totalSleep.inMinutes ?? 0) / 60.0;

      final blended = HealthMetricData(
        steps: hcDaily.steps,
        heartRate: 0.0,
        activeCalories: hcDaily.caloriesBurned,
        sleepHours: sleepHours,
        timestamp: now,
      );

      // Mark all connected sources as synced
      for (final src in connectedSources) {
        final conn = updatedConnections[src];
        if (conn != null) {
          updatedConnections[src] = conn.copyWith(
            lastSyncStatus: SyncStatus.success,
            lastSyncTime: now,
          );
        }
      }

      state = state.copyWith(
        connections: updatedConnections,
        cachedData: blended,
        isSyncing: false,
      );

      await _service.saveConnections(updatedConnections);
      await _service.saveCachedData(blended);

      // ── Write to canonical HealthCacheService so Home & Progress update ────
      final cacheService = HealthCacheService(AppPreferences.prefs);

      final updatedDaily = hcDaily.copyWith(
        date: today,
        healthConnectStatus: HealthConnectStatus.connected,
        dataSource: DataSource.healthConnectOnly,
        lastSyncTime: now,
      );

      if (kDebugMode) {
        print('[HC_CACHE] saving: steps=${updatedDaily.steps}, cal=${updatedDaily.caloriesBurned}, dist=${updatedDaily.distanceKm}');
      }

      await cacheService.saveDailyActivity(updatedDaily);

      final verify = cacheService.getDailyActivity(today);
      if (kDebugMode) {
        print('[HC_CACHE] verification read: steps=${verify?.steps}, cal=${verify?.caloriesBurned}');
      }

      // Update today's slot in weekly
      final existingWeekly = cacheService.getWeeklyActivity() ??
          List.generate(7, (i) => DailyActivitySummary.empty(date: today.subtract(Duration(days: 6 - i))));
      final updatedWeekly = existingWeekly.map<DailyActivitySummary>((s) {
        if (s.date.year == today.year && s.date.month == today.month && s.date.day == today.day) {
          return updatedDaily;
        }
        return s;
      }).toList();
      await cacheService.saveWeeklyActivity(updatedWeekly);

      final sleepMins = hcSleep?.totalSleep.inMinutes ?? 0;
      if (sleepMins > 0) {
        await cacheService.saveSleepSummary(SleepSummary(
          totalSleep: Duration(minutes: sleepMins),
          remSleep: Duration.zero,
          deepSleep: Duration.zero,
          lightSleep: Duration(minutes: sleepMins),
          sleepScore: 80,
          date: today,
        ));
      }
    } catch (e) {
      if (kDebugMode) print('[HC_DEBUG] syncAllActive EXCEPTION: $e');

      for (final src in connectedSources) {
        final conn = updatedConnections[src];
        if (conn != null) {
          updatedConnections[src] = conn.copyWith(
            lastSyncStatus: SyncStatus.error,
            errorMessage: e.toString(),
          );
        }
      }

      state = state.copyWith(
        connections: updatedConnections,
        isSyncing: false,
        syncError: e.toString(),
      );
      await _service.saveConnections(updatedConnections);
    }
  }

  Future<void> updatePriorities(List<HealthSource> newOrder) async {
    await load();
    state = state.copyWith(priorities: newOrder);
    await _service.savePriorities(newOrder);
  }

  Future<void> toggleBackgroundSync(bool enabled) async {
    await load();
    state = state.copyWith(isBackgroundSyncEnabled: enabled);
    await _service.saveBgSyncEnabled(enabled);
  }

  Future<void> updateSyncInterval(int minutes) async {
    await load();
    state = state.copyWith(syncIntervalMinutes: minutes);
    await _service.saveBgSyncInterval(minutes);
  }
}
