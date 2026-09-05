import 'package:fitora/core/storage/local_database_service.dart';
import 'package:fitora/features/cycle/domain/cycle_models.dart';
import 'package:fitora/features/personalization/domain/personalization_models.dart';
import 'package:fitora/features/workouts/domain/workout_models.dart';

enum CloudBackupSyncStatus {
  disabled,
  unauthenticated,
  idle,
  syncing,
  success,
  failed,
  offline,
}

extension CloudBackupSyncStatusX on CloudBackupSyncStatus {
  String get displayName {
    switch (this) {
      case CloudBackupSyncStatus.disabled:
        return 'Cloud backup is off';
      case CloudBackupSyncStatus.unauthenticated:
        return 'Sign in to enable cloud backup';
      case CloudBackupSyncStatus.idle:
        return 'Backed up & in sync';
      case CloudBackupSyncStatus.syncing:
        return 'Backing up your data...';
      case CloudBackupSyncStatus.success:
        return 'Backup synchronized';
      case CloudBackupSyncStatus.failed:
        return 'Backup failed. Local data is safe.';
      case CloudBackupSyncStatus.offline:
        return 'Offline (changes pending)';
    }
  }
}

class CloudBackupSyncState {
  final bool enabled;
  final CloudBackupSyncStatus status;
  final DateTime? lastSyncTime;
  final String? lastError;
  final int pendingChangesCount;
  final bool isRestoring;

  const CloudBackupSyncState({
    this.enabled = false,
    this.status = CloudBackupSyncStatus.disabled,
    this.lastSyncTime,
    this.lastError,
    this.pendingChangesCount = 0,
    this.isRestoring = false,
  });

  CloudBackupSyncState copyWith({
    bool? enabled,
    CloudBackupSyncStatus? status,
    DateTime? lastSyncTime,
    String? lastError,
    int? pendingChangesCount,
    bool? isRestoring,
  }) {
    return CloudBackupSyncState(
      enabled: enabled ?? this.enabled,
      status: status ?? this.status,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      lastError: lastError,
      pendingChangesCount: pendingChangesCount ?? this.pendingChangesCount,
      isRestoring: isRestoring ?? this.isRestoring,
    );
  }
}

/// Unified payload representing user backup snapshot for Cloud Backup & Sync.
class CloudBackupPayload {
  static const int currentSchemaVersion = 1;

  final int schemaVersion;
  final String userId;
  final DateTime updatedAt;

  final PersonalizationProfile? profile;
  final Map<String, dynamic>? settings;
  final List<WorkoutLogEntry> workouts;
  final List<DailyLogRecord> sleepRecords;
  final List<PeriodRange> periodRanges;
  final Map<String, PeriodDayData> cycleDayLogs;
  final Map<String, dynamic>? cycleSettings;
  final Map<String, String> tombstones; // recordId -> deletedAt ISO string

  const CloudBackupPayload({
    this.schemaVersion = currentSchemaVersion,
    required this.userId,
    required this.updatedAt,
    this.profile,
    this.settings,
    this.workouts = const [],
    this.sleepRecords = const [],
    this.periodRanges = const [],
    this.cycleDayLogs = const {},
    this.cycleSettings,
    this.tombstones = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'schemaVersion': schemaVersion,
      'userId': userId,
      'updatedAt': updatedAt.toIso8601String(),
      'profile': profile?.toJson(),
      'settings': settings,
      'workouts': workouts.map((w) => w.toJson()).toList(),
      'sleepRecords': sleepRecords.map((s) => s.toMap()).toList(),
      'periodRanges': periodRanges.map((p) => p.toJson()).toList(),
      'cycleDayLogs': cycleDayLogs.map((k, v) => MapEntry(k, v.toJson())),
      'cycleSettings': cycleSettings,
      'tombstones': tombstones,
    };
  }

  factory CloudBackupPayload.fromJson(Map<String, dynamic> json) {
    final rawSchemaVersion = (json['schemaVersion'] as num?)?.toInt() ?? 1;
    final rawUserId = json['userId'] as String? ?? '';
    final rawUpdatedAt = json['updatedAt'] != null
        ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
        : DateTime.now();

    // Data validation & safe parsing
    PersonalizationProfile? parsedProfile;
    if (json['profile'] != null && json['profile'] is Map<String, dynamic>) {
      try {
        parsedProfile = PersonalizationProfile.fromJson(json['profile'] as Map<String, dynamic>);
      } catch (_) {}
    }

    Map<String, dynamic>? parsedSettings;
    if (json['settings'] != null && json['settings'] is Map<String, dynamic>) {
      parsedSettings = Map<String, dynamic>.from(json['settings'] as Map);
    }

    final List<WorkoutLogEntry> parsedWorkouts = [];
    if (json['workouts'] != null && json['workouts'] is List) {
      for (final item in (json['workouts'] as List)) {
        if (item is Map<String, dynamic>) {
          try {
            parsedWorkouts.add(WorkoutLogEntry.fromJson(item));
          } catch (_) {}
        }
      }
    }

    final List<DailyLogRecord> parsedSleepRecords = [];
    if (json['sleepRecords'] != null && json['sleepRecords'] is List) {
      for (final item in (json['sleepRecords'] as List)) {
        if (item is Map<String, dynamic>) {
          try {
            parsedSleepRecords.add(DailyLogRecord.fromMap(item));
          } catch (_) {}
        }
      }
    }

    final List<PeriodRange> parsedPeriodRanges = [];
    if (json['periodRanges'] != null && json['periodRanges'] is List) {
      for (final item in (json['periodRanges'] as List)) {
        if (item is Map<String, dynamic>) {
          try {
            parsedPeriodRanges.add(PeriodRange.fromJson(item));
          } catch (_) {}
        }
      }
    }

    final Map<String, PeriodDayData> parsedCycleDayLogs = {};
    if (json['cycleDayLogs'] != null && json['cycleDayLogs'] is Map) {
      (json['cycleDayLogs'] as Map).forEach((k, v) {
        if (v is Map<String, dynamic>) {
          try {
            parsedCycleDayLogs[k.toString()] = PeriodDayData.fromJson(v);
          } catch (_) {}
        }
      });
    }

    Map<String, dynamic>? parsedCycleSettings;
    if (json['cycleSettings'] != null && json['cycleSettings'] is Map<String, dynamic>) {
      parsedCycleSettings = Map<String, dynamic>.from(json['cycleSettings'] as Map);
    }

    final Map<String, String> parsedTombstones = {};
    if (json['tombstones'] != null && json['tombstones'] is Map) {
      (json['tombstones'] as Map).forEach((k, v) {
        parsedTombstones[k.toString()] = v.toString();
      });
    }

    return CloudBackupPayload(
      schemaVersion: rawSchemaVersion,
      userId: rawUserId,
      updatedAt: rawUpdatedAt,
      profile: parsedProfile,
      settings: parsedSettings,
      workouts: parsedWorkouts,
      sleepRecords: parsedSleepRecords,
      periodRanges: parsedPeriodRanges,
      cycleDayLogs: parsedCycleDayLogs,
      cycleSettings: parsedCycleSettings,
      tombstones: parsedTombstones,
    );
  }
}
