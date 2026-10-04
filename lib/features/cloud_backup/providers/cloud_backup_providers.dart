import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitora/core/storage/app_preferences.dart';
import 'package:fitora/core/utils/app_logger.dart';
import 'package:fitora/features/auth/providers/auth_providers.dart';
import 'package:fitora/features/cloud_backup/data/cloud_backup_repository.dart';
import 'package:fitora/features/cloud_backup/domain/cloud_backup_models.dart';
import 'package:fitora/features/cloud_backup/services/cloud_backup_sync_service.dart';
import 'package:fitora/features/cycle/providers/cycle_provider.dart';
import 'package:fitora/features/personalization/providers/personalization_controller.dart';
import 'package:fitora/features/workouts/providers/workout_provider.dart';

final cloudBackupRepositoryProvider = Provider<CloudBackupRepository>((ref) {
  return FirestoreCloudBackupRepository();
});

final cloudBackupSyncServiceProvider = Provider<CloudBackupSyncService>((ref) {
  final repo = ref.watch(cloudBackupRepositoryProvider);
  return CloudBackupSyncService(repository: repo);
});

final cloudBackupSyncProvider =
    StateNotifierProvider<CloudBackupSyncNotifier, CloudBackupSyncState>((ref) {
  final syncService = ref.watch(cloudBackupSyncServiceProvider);
  return CloudBackupSyncNotifier(syncService, ref);
});

class CloudBackupSyncNotifier extends StateNotifier<CloudBackupSyncState> {
  final CloudBackupSyncService _syncService;
  final Ref _ref;
  static const String _prefEnabledKey = 'fitora_cloud_backup_enabled';

  CloudBackupSyncNotifier(this._syncService, this._ref)
      : super(const CloudBackupSyncState()) {
    _init();
  }

  Future<void> _init() async {
    final prefs = await AppPreferences.instance();
    final isEnabled = prefs.getBool(_prefEnabledKey) ?? false;
    final lastSyncStr = prefs.getString('fitora_cloud_sync_last_time');
    final lastSync = lastSyncStr != null ? DateTime.tryParse(lastSyncStr) : null;

    final authSession = _ref.read(authStateProvider);
    final user = authSession.user;

    if (user == null || user.isAnonymous) {
      state = CloudBackupSyncState(
        enabled: isEnabled,
        status: CloudBackupSyncStatus.unauthenticated,
        lastSyncTime: lastSync,
      );
    } else {
      state = CloudBackupSyncState(
        enabled: isEnabled,
        status: isEnabled ? CloudBackupSyncStatus.idle : CloudBackupSyncStatus.disabled,
        lastSyncTime: lastSync,
      );
    }

    // Listen to Auth State Changes reactively
    _ref.listen(authStateProvider, (previous, next) {
      final newUser = next.user;
      if (newUser == null || newUser.isAnonymous) {
        state = state.copyWith(
          status: CloudBackupSyncStatus.unauthenticated,
        );
      } else {
        // Automatically enable backup & sync if user signs in with Google
        prefs.setBool(_prefEnabledKey, true);
        state = state.copyWith(
          enabled: true,
          status: CloudBackupSyncStatus.idle,
        );
        // Perform automatic restore and sync on sign-in
        syncNow();
      }
    });
  }

  Future<void> toggleBackup(bool enable) async {
    final prefs = await AppPreferences.instance();
    await prefs.setBool(_prefEnabledKey, enable);

    final authSession = _ref.read(authStateProvider);
    final user = authSession.user;

    if (user == null || user.isAnonymous) {
      state = state.copyWith(
        enabled: enable,
        status: CloudBackupSyncStatus.unauthenticated,
      );
      return;
    }

    if (enable) {
      state = state.copyWith(
        enabled: true,
        status: CloudBackupSyncStatus.syncing,
      );
      await syncNow();
    } else {
      state = state.copyWith(
        enabled: false,
        status: CloudBackupSyncStatus.disabled,
      );
    }
  }

  Future<void> syncNow() async {
    final authSession = _ref.read(authStateProvider);
    final user = authSession.user;

    if (user == null || user.isAnonymous) {
      state = state.copyWith(status: CloudBackupSyncStatus.unauthenticated);
      return;
    }

    if (state.status == CloudBackupSyncStatus.syncing) return;

    state = state.copyWith(status: CloudBackupSyncStatus.syncing);

    try {
      final syncTime = await _syncService.performSync(user.id);

      // Refresh in-memory Riverpod state across features
      await _refreshFeatureNotifiers();

      state = state.copyWith(
        status: CloudBackupSyncStatus.success,
        lastSyncTime: syncTime,
        lastError: null,
      );
    } catch (e, st) {
      AppLogger.error('Cloud backup sync failed: $e', st);
      state = state.copyWith(
        status: CloudBackupSyncStatus.failed,
        lastError: 'Sync failed: $e',
      );
    }
  }

  Future<void> restoreData() async {
    final authSession = _ref.read(authStateProvider);
    final user = authSession.user;

    if (user == null || user.isAnonymous) {
      state = state.copyWith(status: CloudBackupSyncStatus.unauthenticated);
      return;
    }

    state = state.copyWith(
      isRestoring: true,
      status: CloudBackupSyncStatus.syncing,
    );

    try {
      final syncTime = await _syncService.performSync(user.id);
      await _refreshFeatureNotifiers();

      state = state.copyWith(
        isRestoring: false,
        status: CloudBackupSyncStatus.success,
        lastSyncTime: syncTime,
        lastError: null,
      );
    } catch (e, st) {
      AppLogger.error('Cloud restore failed: $e', st);
      state = state.copyWith(
        isRestoring: false,
        status: CloudBackupSyncStatus.failed,
        lastError: 'Restore failed: $e',
      );
    }
  }

  Future<void> _refreshFeatureNotifiers() async {
    try {
      await _ref.read(workoutProvider.notifier).load();
      await _ref.read(cycleProvider.notifier).load();
      await _ref.read(personalizationControllerProvider.notifier).reloadProfile();
    } catch (_) {}
  }
}
