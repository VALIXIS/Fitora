import 'dart:convert';
import 'package:fitora/core/storage/app_preferences.dart';
import 'package:fitora/core/storage/local_database_service.dart';
import 'package:fitora/core/utils/app_logger.dart';
import 'package:fitora/features/cloud_backup/data/cloud_backup_repository.dart';
import 'package:fitora/features/cloud_backup/domain/cloud_backup_models.dart';
import 'package:fitora/features/cycle/domain/cycle_models.dart';
import 'package:fitora/features/personalization/data/personalization_local_data_source.dart';
import 'package:fitora/features/personalization/domain/personalization_models.dart';
import 'package:fitora/features/workouts/domain/workout_models.dart';

class CloudBackupSyncService {
  final CloudBackupRepository _repository;
  final LocalDatabaseService _localDb;
  final PersonalizationLocalDataSource _personalizationDs;

  static const String _tombstonesKey = 'fitora_cloud_sync_tombstones';
  static const String _lastSyncKey = 'fitora_cloud_sync_last_time';

  CloudBackupSyncService({
    required CloudBackupRepository repository,
    LocalDatabaseService? localDb,
    PersonalizationLocalDataSource? personalizationDs,
  })  : _repository = repository,
        _localDb = localDb ?? LocalDatabaseService(),
        _personalizationDs = personalizationDs ?? PersonalizationLocalDataSource();

  // ---------------------------------------------------------------------------
  // 1. Gather Local Dataset
  // ---------------------------------------------------------------------------
  Future<CloudBackupPayload> buildLocalPayload(String userId) async {
    final prefs = await AppPreferences.instance();

    // Profile
    PersonalizationProfile? profile;
    try {
      profile = await _personalizationDs.fetchProfile();
    } catch (_) {}

    // App Settings
    Map<String, dynamic>? settings;
    try {
      settings = {
        'isDarkMode': prefs.getBool('isDarkMode') ?? true,
        'notificationsEnabled': prefs.getBool('notificationsEnabled') ?? true,
        'soundEffectsEnabled': prefs.getBool('soundEffectsEnabled') ?? false,
        'hapticsEnabled': prefs.getBool('hapticsEnabled') ?? true,
        'isMetric': prefs.getBool('isMetric') ?? true,
        'autoplayRest': prefs.getBool('autoplayRest') ?? true,
        'hydrationReminderEnabled': prefs.getBool('hydrationReminderEnabled') ?? false,
        'hydrationReminderIntervalMinutes': prefs.getInt('hydrationReminderIntervalMinutes') ?? 120,
        'stepReminderEnabled': prefs.getBool('stepReminderEnabled') ?? true,
        'sleepReminderEnabled': prefs.getBool('sleepReminderEnabled') ?? true,
        'dailySummaryEnabled': prefs.getBool('dailySummaryEnabled') ?? true,
        'quietHoursEnabled': prefs.getBool('quietHoursEnabled') ?? true,
        'quietHoursStartHour': prefs.getInt('quietHoursStartHour') ?? 22,
        'quietHoursEndHour': prefs.getInt('quietHoursEndHour') ?? 8,
        'sleepTargetDurationMinutes': prefs.getInt('sleepTargetDurationMinutes') ?? 480,
        'sleepTargetBedtimeHour': prefs.getInt('sleepTargetBedtimeHour') ?? 23,
        'sleepTargetBedtimeMinute': prefs.getInt('sleepTargetBedtimeMinute') ?? 0,
        'sleepTargetWakeHour': prefs.getInt('sleepTargetWakeHour') ?? 7,
        'sleepTargetWakeMinute': prefs.getInt('sleepTargetWakeMinute') ?? 0,
      };
    } catch (_) {}

    // Workouts
    List<WorkoutLogEntry> workouts = [];
    try {
      final rawWorkouts = prefs.getString('fitora_workout_history_v1');
      if (rawWorkouts != null && rawWorkouts.isNotEmpty) {
        final decoded = jsonDecode(rawWorkouts) as List<dynamic>;
        workouts = decoded
            .map((e) => WorkoutLogEntry.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}

    // Sleep & Daily logs from SQLite
    List<DailyLogRecord> sleepRecords = [];
    try {
      sleepRecords = await _localDb.getAllDailyLogs();
    } catch (_) {}

    // Cycle Records
    List<PeriodRange> periodRanges = [];
    Map<String, PeriodDayData> cycleDayLogs = {};
    Map<String, dynamic>? cycleSettings;

    try {
      final rawRanges = prefs.getString('fitora_cycle_ranges');
      if (rawRanges != null && rawRanges.isNotEmpty) {
        final decoded = jsonDecode(rawRanges) as List<dynamic>;
        periodRanges = decoded
            .map((e) => PeriodRange.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      final rawDayLogs = prefs.getString('fitora_cycle_day_logs');
      if (rawDayLogs != null && rawDayLogs.isNotEmpty) {
        final decoded = jsonDecode(rawDayLogs) as Map<String, dynamic>;
        cycleDayLogs = decoded.map(
            (k, v) => MapEntry(k, PeriodDayData.fromJson(v as Map<String, dynamic>)));
      }

      final rawCycleSettings = prefs.getString('fitora_cycle_settings');
      if (rawCycleSettings != null && rawCycleSettings.isNotEmpty) {
        cycleSettings = Map<String, dynamic>.from(jsonDecode(rawCycleSettings) as Map);
      }
    } catch (_) {}

    // Tombstones
    Map<String, String> tombstones = {};
    try {
      final rawTombstones = prefs.getString(_tombstonesKey);
      if (rawTombstones != null && rawTombstones.isNotEmpty) {
        tombstones = Map<String, String>.from(jsonDecode(rawTombstones) as Map);
      }
    } catch (_) {}

    return CloudBackupPayload(
      userId: userId,
      updatedAt: DateTime.now(),
      profile: profile,
      settings: settings,
      workouts: workouts,
      sleepRecords: sleepRecords,
      periodRanges: periodRanges,
      cycleDayLogs: cycleDayLogs,
      cycleSettings: cycleSettings,
      tombstones: tombstones,
    );
  }

  // ---------------------------------------------------------------------------
  // 2. Add Tombstone for Deleted Record
  // ---------------------------------------------------------------------------
  Future<void> markRecordDeleted(String recordId) async {
    if (recordId.isEmpty) return;
    try {
      final prefs = await AppPreferences.instance();
      Map<String, String> tombstones = {};
      final raw = prefs.getString(_tombstonesKey);
      if (raw != null && raw.isNotEmpty) {
        tombstones = Map<String, String>.from(jsonDecode(raw) as Map);
      }
      tombstones[recordId] = DateTime.now().toIso8601String();
      await prefs.setString(_tombstonesKey, jsonEncode(tombstones));
    } catch (e, st) {
      AppLogger.error('Failed to mark record deleted $recordId: $e', st);
    }
  }

  // ---------------------------------------------------------------------------
  // 3. Two-Way Safe Deterministic Merge
  // ---------------------------------------------------------------------------
  CloudBackupPayload mergePayloads(
    CloudBackupPayload local,
    CloudBackupPayload? cloud,
  ) {
    if (cloud == null) {
      return local;
    }

    // Merge tombstones
    final Map<String, String> mergedTombstones = {...cloud.tombstones, ...local.tombstones};

    // Helper to check if item deleted by tombstone
    bool isTombstoned(String id) => mergedTombstones.containsKey(id);

    // Profile: prefer whichever is newer or populated
    final PersonalizationProfile? mergedProfile = local.profile != null && local.profile!.name != null
        ? local.profile
        : cloud.profile ?? local.profile;

    // Settings: merge keys, local overrides if present
    final Map<String, dynamic> mergedSettings = {
      if (cloud.settings != null) ...cloud.settings!,
      if (local.settings != null) ...local.settings!,
    };

    // Workouts: merge by stable ID
    final Map<String, WorkoutLogEntry> workoutMap = {};
    for (final w in cloud.workouts) {
      if (!isTombstoned(w.id)) {
        workoutMap[w.id] = w;
      }
    }
    for (final w in local.workouts) {
      if (!isTombstoned(w.id)) {
        if (!workoutMap.containsKey(w.id)) {
          workoutMap[w.id] = w;
        } else {
          // Both exist: compare timestamp
          final existing = workoutMap[w.id]!;
          if (w.timestamp.isAfter(existing.timestamp)) {
            workoutMap[w.id] = w;
          }
        }
      }
    }

    // Sleep records: merge by date string
    final Map<String, DailyLogRecord> sleepMap = {};
    for (final s in cloud.sleepRecords) {
      if (!isTombstoned(s.date)) {
        sleepMap[s.date] = s;
      }
    }
    for (final s in local.sleepRecords) {
      if (!isTombstoned(s.date)) {
        if (!sleepMap.containsKey(s.date)) {
          sleepMap[s.date] = s;
        } else {
          final existing = sleepMap[s.date]!;
          // Merge metrics or keep latest
          final latestDate = s.updatedAt.isAfter(existing.updatedAt) ? s.updatedAt : existing.updatedAt;
          sleepMap[s.date] = DailyLogRecord(
            date: s.date,
            steps: s.steps > existing.steps ? s.steps : existing.steps,
            caloriesBurned: s.caloriesBurned > existing.caloriesBurned ? s.caloriesBurned : existing.caloriesBurned,
            waterLiters: s.waterLiters > existing.waterLiters ? s.waterLiters : existing.waterLiters,
            sleepMinutes: s.sleepMinutes > existing.sleepMinutes ? s.sleepMinutes : existing.sleepMinutes,
            distanceKm: s.distanceKm > existing.distanceKm ? s.distanceKm : existing.distanceKm,
            activeMinutes: s.activeMinutes > existing.activeMinutes ? s.activeMinutes : existing.activeMinutes,
            updatedAt: latestDate,
          );
        }
      }
    }

    // Cycle PeriodRanges: merge by ID
    final Map<String, PeriodRange> rangeMap = {};
    for (final pr in cloud.periodRanges) {
      if (!isTombstoned(pr.id)) {
        rangeMap[pr.id] = pr;
      }
    }
    for (final pr in local.periodRanges) {
      if (!isTombstoned(pr.id)) {
        rangeMap[pr.id] = pr; // Local keeps/overrides
      }
    }

    // Cycle DayLogs: merge by date
    final Map<String, PeriodDayData> cycleLogMap = {};
    for (final entry in cloud.cycleDayLogs.entries) {
      if (!isTombstoned(entry.key)) {
        cycleLogMap[entry.key] = entry.value;
      }
    }
    for (final entry in local.cycleDayLogs.entries) {
      if (!isTombstoned(entry.key)) {
        cycleLogMap[entry.key] = entry.value;
      }
    }

    // Cycle Settings: merge
    final Map<String, dynamic> mergedCycleSettings = {
      if (cloud.cycleSettings != null) ...cloud.cycleSettings!,
      if (local.cycleSettings != null) ...local.cycleSettings!,
    };

    return CloudBackupPayload(
      userId: local.userId,
      updatedAt: DateTime.now(),
      profile: mergedProfile,
      settings: mergedSettings,
      workouts: workoutMap.values.toList(),
      sleepRecords: sleepMap.values.toList(),
      periodRanges: rangeMap.values.toList(),
      cycleDayLogs: cycleLogMap,
      cycleSettings: mergedCycleSettings,
      tombstones: mergedTombstones,
    );
  }

  // ---------------------------------------------------------------------------
  // 4. Restore Merged Dataset Into Local Storage
  // ---------------------------------------------------------------------------
  Future<void> restoreToLocal(CloudBackupPayload payload) async {
    final prefs = await AppPreferences.instance();

    // 1. Profile
    if (payload.profile != null) {
      try {
        await _personalizationDs.saveProfile(payload.profile!);
        await _personalizationDs.setCompleted(true);
      } catch (e, st) {
        AppLogger.error('Failed to restore profile to local storage: $e', st);
      }
    }

    // 2. Settings
    if (payload.settings != null) {
      try {
        final map = payload.settings!;
        map.forEach((k, v) {
          if (v is bool) prefs.setBool(k, v);
          if (v is int) prefs.setInt(k, v);
          if (v is double) prefs.setDouble(k, v);
          if (v is String) prefs.setString(k, v);
        });
      } catch (e, st) {
        AppLogger.error('Failed to restore settings to local storage: $e', st);
      }
    }

    // 3. Workouts
    try {
      final encodedWorkouts = payload.workouts.map((w) => w.toJson()).toList();
      await prefs.setString('fitora_workout_history_v1', jsonEncode(encodedWorkouts));
    } catch (e, st) {
      AppLogger.error('Failed to restore workouts to local storage: $e', st);
    }

    // 4. Sleep & Daily records into SQLite
    try {
      for (final rec in payload.sleepRecords) {
        await _localDb.upsertDailyLog(rec);
      }
    } catch (e, st) {
      AppLogger.error('Failed to restore daily logs to SQLite: $e', st);
    }

    // 5. Cycle records
    try {
      final encodedRanges = payload.periodRanges.map((p) => p.toJson()).toList();
      await prefs.setString('fitora_cycle_ranges', jsonEncode(encodedRanges));

      final encodedDayLogs = payload.cycleDayLogs.map((k, v) => MapEntry(k, v.toJson()));
      await prefs.setString('fitora_cycle_day_logs', jsonEncode(encodedDayLogs));

      if (payload.cycleSettings != null) {
        await prefs.setString('fitora_cycle_settings', jsonEncode(payload.cycleSettings));
      }
    } catch (e, st) {
      AppLogger.error('Failed to restore cycle records to local storage: $e', st);
    }

    // 6. Tombstones
    try {
      await prefs.setString(_tombstonesKey, jsonEncode(payload.tombstones));
    } catch (_) {}
  }

  // ---------------------------------------------------------------------------
  // 5. Full Sync Workflow (Initial Backup & Incremental Sync)
  // ---------------------------------------------------------------------------
  Future<DateTime> performSync(String userId) async {
    if (userId.isEmpty) {
      throw ArgumentError('Cannot sync without an authenticated user ID');
    }

    AppLogger.info('Starting cloud backup synchronization for user $userId...');

    // Step A: Build local snapshot
    final localPayload = await buildLocalPayload(userId);

    // Step B: Fetch cloud snapshot
    CloudBackupPayload? cloudPayload;
    try {
      cloudPayload = await _repository.fetchBackup(userId);
    } catch (e) {
      AppLogger.info('Cloud fetch unavailable (possibly offline): $e');
      // Offline fallback: return current time, keep local data intact!
      return DateTime.now();
    }

    // Step C: Perform two-way safe merge
    final mergedPayload = mergePayloads(localPayload, cloudPayload);

    // Step D: Write merged payload back to cloud
    await _repository.saveBackup(userId, mergedPayload);

    // Step E: Restore merged payload into local storage
    await restoreToLocal(mergedPayload);

    final syncTime = DateTime.now();
    final prefs = await AppPreferences.instance();
    await prefs.setString(_lastSyncKey, syncTime.toIso8601String());

    AppLogger.info('Cloud backup synchronization completed successfully.');
    return syncTime;
  }
}
