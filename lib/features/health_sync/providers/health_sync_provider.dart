import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/app_preferences.dart';
import '../domain/health_sync_models.dart';
import '../services/health_sync_service.dart';
import '../services/pedometer_service.dart';

final healthSyncProvider = StateNotifierProvider<HealthSyncController, HealthSyncState>((ref) {
  return HealthSyncController()..load();
});

class HealthSyncController extends StateNotifier<HealthSyncState> {
  HealthSyncController()
      : super(HealthSyncState(
          connections: {},
          priorities: [],
          cachedData: HealthMetricData.empty(),
        ));

  late final HealthSyncService _service;
  bool _initialized = false;

  Future<void> load() async {
    if (_initialized) return;

    final prefs = await AppPreferences.instance();
    _service = HealthSyncService(prefs);

    final connections = _service.loadConnections();
    final priorities = _service.loadPriorities();
    final bgSyncEnabled = _service.loadBgSyncEnabled();
    final bgSyncInterval = _service.loadBgSyncInterval();
    final cachedData = _service.loadCachedData();

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
    PedometerService().stepStream.listen((realtimeSteps) {
      final hasActiveConnectedSource = state.connections.values.any(
        (c) => c.isConnected && c.permissionStatus == HealthPermissionStatus.authorized
      );
      if (hasActiveConnectedSource) {
        state = state.copyWith(
          cachedData: state.cachedData.copyWith(
            steps: realtimeSteps,
            timestamp: DateTime.now(),
          ),
        );
        _service.saveCachedData(state.cachedData);
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
      final connector = _service.connectors.firstWhere((c) => c.source == source);
      final reqStatus = await connector.requestPermissions();

      if (reqStatus == HealthPermissionStatus.authorized) {
        // Also request permission on pedometer service
        await PedometerService().requestPermissions();

        final updatedConn = conn.copyWith(
          isConnected: true,
          permissionStatus: HealthPermissionStatus.authorized,
          lastSyncStatus: SyncStatus.success,
          lastSyncTime: DateTime.now(),
        );

        final updatedConnections = Map<HealthSource, HealthSourceConnectionState>.from(state.connections);
        updatedConnections[source] = updatedConn;

        state = state.copyWith(connections: updatedConnections);
        await _service.saveConnections(updatedConnections);

        // Perform a quick initial sync of metrics
        await syncAllActive();
      } else {
        state = state.copyWith(
          isSyncing: false,
          syncError: 'Permission not granted for ${source.label}',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isSyncing: false,
        syncError: 'Failed to connect to ${source.label}: $e',
      );
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
    final activeSources = state.connections.values.where((c) => c.isConnected).map((c) => c.source).toList();
    if (activeSources.isEmpty) return;

    state = state.copyWith(isSyncing: true, syncError: null);

    final List<HealthMetricData> results = [];
    final updatedConnections = Map<HealthSource, HealthSourceConnectionState>.from(state.connections);

    for (final src in activeSources) {
      try {
        final metric = await _service.syncSource(src);
        results.add(metric);

        final conn = updatedConnections[src]!;
        updatedConnections[src] = conn.copyWith(
          lastSyncStatus: SyncStatus.success,
          lastSyncTime: DateTime.now(),
        );
      } catch (e) {
        final conn = updatedConnections[src]!;
        updatedConnections[src] = conn.copyWith(
          lastSyncStatus: SyncStatus.error,
          errorMessage: e.toString(),
        );
      }
    }

    if (results.isEmpty) {
      state = state.copyWith(
        connections: updatedConnections,
        isSyncing: false,
        syncError: 'No sources synced successfully.',
      );
      await _service.saveConnections(updatedConnections);
      return;
    }

    final blended = _service.blendMetrics(results, state.priorities);

    state = state.copyWith(
      connections: updatedConnections,
      cachedData: blended,
      isSyncing: false,
    );

    await _service.saveConnections(updatedConnections);
    await _service.saveCachedData(blended);
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
