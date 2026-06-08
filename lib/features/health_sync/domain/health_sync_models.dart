import 'package:flutter/foundation.dart';

enum HealthSource {
  googleFit(
    id: 'google_fit',
    label: 'Google Fit',
    description: 'Sync steps and daily activity.',
    iconName: 'google',
  ),
  healthConnect(
    id: 'health_connect',
    label: 'Health Connect',
    description: 'Android centralized hub for on-device health data.',
    iconName: 'android',
  ),
  samsungHealth(
    id: 'samsung_health',
    label: 'Samsung Health',
    description: 'Sync steps from your Samsung device.',
    iconName: 'samsung',
  ),
  appleHealth(
    id: 'apple_health',
    label: 'Apple Health',
    description: 'Securely sync fitness and biometrics directly from iOS.',
    iconName: 'apple',
  );

  final String id;
  final String label;
  final String description;
  final String iconName;

  const HealthSource({
    required this.id,
    required this.label,
    required this.description,
    required this.iconName,
  });

  static HealthSource fromId(String id) {
    return HealthSource.values.firstWhere(
      (e) => e.id == id,
      orElse: () => HealthSource.googleFit,
    );
  }

  // Detect and filter supported integrations per platform
  static List<HealthSource> getSupportedSources() {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return [HealthSource.appleHealth];
    } else {
      return [
        HealthSource.googleFit,
        HealthSource.healthConnect,
        HealthSource.samsungHealth,
      ];
    }
  }
}

enum HealthPermissionStatus {
  notDetermined,
  authorized,
  denied,
}

enum SyncStatus {
  idle,
  syncing,
  success,
  error,
}

@immutable
class HealthSourceConnectionState {
  final HealthSource source;
  final bool isConnected;
  final HealthPermissionStatus permissionStatus;
  final SyncStatus lastSyncStatus;
  final DateTime? lastSyncTime;
  final String? errorMessage;

  const HealthSourceConnectionState({
    required this.source,
    this.isConnected = false,
    this.permissionStatus = HealthPermissionStatus.notDetermined,
    this.lastSyncStatus = SyncStatus.idle,
    this.lastSyncTime,
    this.errorMessage,
  });

  HealthSourceConnectionState copyWith({
    bool? isConnected,
    HealthPermissionStatus? permissionStatus,
    SyncStatus? lastSyncStatus,
    DateTime? lastSyncTime,
    String? errorMessage,
  }) {
    return HealthSourceConnectionState(
      source: source,
      isConnected: isConnected ?? this.isConnected,
      permissionStatus: permissionStatus ?? this.permissionStatus,
      lastSyncStatus: lastSyncStatus ?? this.lastSyncStatus,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'source': source.id,
      'isConnected': isConnected,
      'permissionStatus': permissionStatus.name,
      'lastSyncStatus': lastSyncStatus.name,
      'lastSyncTime': lastSyncTime?.toIso8601String(),
      'errorMessage': errorMessage,
    };
  }

  factory HealthSourceConnectionState.fromJson(Map<String, dynamic> json) {
    return HealthSourceConnectionState(
      source: HealthSource.fromId(json['source'] as String),
      isConnected: json['isConnected'] as bool? ?? false,
      permissionStatus: HealthPermissionStatus.values.firstWhere(
        (e) => e.name == json['permissionStatus'],
        orElse: () => HealthPermissionStatus.notDetermined,
      ),
      lastSyncStatus: SyncStatus.values.firstWhere(
        (e) => e.name == json['lastSyncStatus'],
        orElse: () => SyncStatus.idle,
      ),
      lastSyncTime: json['lastSyncTime'] != null
          ? DateTime.tryParse(json['lastSyncTime'] as String)
          : null,
      errorMessage: json['errorMessage'] as String?,
    );
  }
}

@immutable
class HealthMetricData {
  final int steps;
  final double heartRate;
  final double activeCalories;
  final double sleepHours;
  final List<HealthSyncWorkout> workouts;
  final DateTime timestamp;

  const HealthMetricData({
    required this.steps,
    required this.heartRate,
    required this.activeCalories,
    required this.sleepHours,
    required this.workouts,
    required this.timestamp,
  });

  factory HealthMetricData.empty() {
    return HealthMetricData(
      steps: 0,
      heartRate: 0.0,
      activeCalories: 0.0,
      sleepHours: 0.0,
      workouts: const [],
      timestamp: DateTime.now(),
    );
  }

  HealthMetricData copyWith({
    int? steps,
    double? heartRate,
    double? activeCalories,
    double? sleepHours,
    List<HealthSyncWorkout>? workouts,
    DateTime? timestamp,
  }) {
    return HealthMetricData(
      steps: steps ?? this.steps,
      heartRate: heartRate ?? this.heartRate,
      activeCalories: activeCalories ?? this.activeCalories,
      sleepHours: sleepHours ?? this.sleepHours,
      workouts: workouts ?? this.workouts,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}

@immutable
class HealthSyncWorkout {
  final String id;
  final String title;
  final String category; // wellness, gym, cardio, home, etc.
  final int durationMinutes;
  final int caloriesBurned;
  final DateTime completedAt;

  const HealthSyncWorkout({
    required this.id,
    required this.title,
    required this.category,
    required this.durationMinutes,
    required this.caloriesBurned,
    required this.completedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'durationMinutes': durationMinutes,
      'caloriesBurned': caloriesBurned,
      'completedAt': completedAt.toIso8601String(),
    };
  }

  factory HealthSyncWorkout.fromJson(Map<String, dynamic> json) {
    return HealthSyncWorkout(
      id: json['id'] as String,
      title: json['title'] as String,
      category: json['category'] as String,
      durationMinutes: json['durationMinutes'] as int,
      caloriesBurned: json['caloriesBurned'] as int,
      completedAt: DateTime.parse(json['completedAt'] as String),
    );
  }
}

@immutable
class HealthSyncState {
  final Map<HealthSource, HealthSourceConnectionState> connections;
  final List<HealthSource> priorities;
  final HealthMetricData cachedData;
  final bool isBackgroundSyncEnabled;
  final int syncIntervalMinutes;
  final bool isSyncing;
  final String? syncError;

  const HealthSyncState({
    required this.connections,
    required this.priorities,
    required this.cachedData,
    this.isBackgroundSyncEnabled = true,
    this.syncIntervalMinutes = 60,
    this.isSyncing = false,
    this.syncError,
  });

  HealthSyncState copyWith({
    Map<HealthSource, HealthSourceConnectionState>? connections,
    List<HealthSource>? priorities,
    HealthMetricData? cachedData,
    bool? isBackgroundSyncEnabled,
    int? syncIntervalMinutes,
    bool? isSyncing,
    String? syncError,
  }) {
    return HealthSyncState(
      connections: connections ?? this.connections,
      priorities: priorities ?? this.priorities,
      cachedData: cachedData ?? this.cachedData,
      isBackgroundSyncEnabled: isBackgroundSyncEnabled ?? this.isBackgroundSyncEnabled,
      syncIntervalMinutes: syncIntervalMinutes ?? this.syncIntervalMinutes,
      isSyncing: isSyncing ?? this.isSyncing,
      syncError: syncError ?? this.syncError,
    );
  }
}
