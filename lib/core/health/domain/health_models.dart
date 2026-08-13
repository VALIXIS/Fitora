/// Tracks whether the device step-counter sensor is usable.
enum SensorStatus {
  /// Sensor is streaming data successfully.
  active,

  /// Permission has not been granted yet.
  permissionRequired,

  /// Sensor hardware is not present or unavailable.
  unavailable,

  /// Initial state before any check.
  unknown,
}

enum HealthConnectStatus {
  connected,
  permissionRequired,
  partiallyGranted,
  revoked,
  unavailable,
  syncing,
  error,
  unknown,
}

enum SyncStatus { synced, syncing, offline, error }

enum DataSource { healthConnectAndSensor, sensorOnly, healthConnectOnly, cache }

class DailyActivitySummary {
  final int steps;
  final int stepsGoal;
  final double caloriesBurned; // active calories
  final double caloriesGoal;
  final int activeMinutes;
  final int activeMinutesGoal;
  final double distanceKm;
  final DateTime date;
  final SensorStatus sensorStatus;
  final HealthConnectStatus healthConnectStatus;
  final DataSource dataSource;
  final DateTime? lastSyncTime;

  const DailyActivitySummary({
    required this.steps,
    required this.stepsGoal,
    required this.caloriesBurned,
    required this.caloriesGoal,
    required this.activeMinutes,
    required this.activeMinutesGoal,
    required this.distanceKm,
    required this.date,
    this.sensorStatus = SensorStatus.unknown,
    this.healthConnectStatus = HealthConnectStatus.error,
    this.dataSource = DataSource.cache,
    this.lastSyncTime,
  });

  factory DailyActivitySummary.empty({
    DateTime? date,
    SensorStatus sensorStatus = SensorStatus.unknown,
    HealthConnectStatus healthConnectStatus = HealthConnectStatus.error,
    DataSource dataSource = DataSource.cache,
  }) => DailyActivitySummary(
    steps: 0,
    stepsGoal: 10000,
    caloriesBurned: 0,
    caloriesGoal: 500,
    activeMinutes: 0,
    activeMinutesGoal: 30,
    distanceKm: 0,
    date: date ?? DateTime.now(),
    sensorStatus: sensorStatus,
    healthConnectStatus: healthConnectStatus,
    dataSource: dataSource,
  );

  DailyActivitySummary copyWith({
    int? steps,
    int? stepsGoal,
    double? caloriesBurned,
    double? caloriesGoal,
    int? activeMinutes,
    int? activeMinutesGoal,
    double? distanceKm,
    DateTime? date,
    SensorStatus? sensorStatus,
    HealthConnectStatus? healthConnectStatus,
    DataSource? dataSource,
    DateTime? lastSyncTime,
  }) {
    return DailyActivitySummary(
      steps: steps ?? this.steps,
      stepsGoal: stepsGoal ?? this.stepsGoal,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      caloriesGoal: caloriesGoal ?? this.caloriesGoal,
      activeMinutes: activeMinutes ?? this.activeMinutes,
      activeMinutesGoal: activeMinutesGoal ?? this.activeMinutesGoal,
      distanceKm: distanceKm ?? this.distanceKm,
      date: date ?? this.date,
      sensorStatus: sensorStatus ?? this.sensorStatus,
      healthConnectStatus: healthConnectStatus ?? this.healthConnectStatus,
      dataSource: dataSource ?? this.dataSource,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'steps': steps,
      'stepsGoal': stepsGoal,
      'caloriesBurned': caloriesBurned,
      'caloriesGoal': caloriesGoal,
      'activeMinutes': activeMinutes,
      'activeMinutesGoal': activeMinutesGoal,
      'distanceKm': distanceKm,
      'date': date.toIso8601String(),
      'lastSyncTime': lastSyncTime?.toIso8601String(),
    };
  }

  factory DailyActivitySummary.fromJson(Map<String, dynamic> json) {
    return DailyActivitySummary(
      steps: json['steps'] ?? 0,
      stepsGoal: json['stepsGoal'] ?? 10000,
      caloriesBurned: (json['caloriesBurned'] ?? 0.0).toDouble(),
      caloriesGoal: (json['caloriesGoal'] ?? 500.0).toDouble(),
      activeMinutes: json['activeMinutes'] ?? 0,
      activeMinutesGoal: json['activeMinutesGoal'] ?? 30,
      distanceKm: (json['distanceKm'] ?? 0.0).toDouble(),
      date: DateTime.parse(json['date']),
      lastSyncTime: json['lastSyncTime'] != null
          ? DateTime.parse(json['lastSyncTime'])
          : null,
      dataSource: DataSource.cache,
    );
  }

  double get stepsProgress => (steps / stepsGoal).clamp(0.0, 1.0);
  double get caloriesProgress =>
      (caloriesBurned / caloriesGoal).clamp(0.0, 1.0);
  double get activeMinutesProgress =>
      (activeMinutes / activeMinutesGoal).clamp(0.0, 1.0);
}

class SleepSummary {
  final Duration totalSleep;
  final Duration remSleep;
  final Duration deepSleep;
  final Duration lightSleep;
  final int sleepScore; // 0-100
  final DateTime date;

  const SleepSummary({
    required this.totalSleep,
    required this.remSleep,
    required this.deepSleep,
    required this.lightSleep,
    required this.sleepScore,
    required this.date,
  });

  Map<String, dynamic> toJson() {
    return {
      'totalSleep': totalSleep.inMinutes,
      'remSleep': remSleep.inMinutes,
      'deepSleep': deepSleep.inMinutes,
      'lightSleep': lightSleep.inMinutes,
      'sleepScore': sleepScore,
      'date': date.toIso8601String(),
    };
  }

  factory SleepSummary.fromJson(Map<String, dynamic> json) {
    return SleepSummary(
      totalSleep: Duration(minutes: json['totalSleep'] ?? 0),
      remSleep: Duration(minutes: json['remSleep'] ?? 0),
      deepSleep: Duration(minutes: json['deepSleep'] ?? 0),
      lightSleep: Duration(minutes: json['lightSleep'] ?? 0),
      sleepScore: json['sleepScore'] ?? 0,
      date: DateTime.parse(json['date']),
    );
  }
}

class RecoverySummary {
  final int recoveryScore; // 0-100
  final int hrv; // Heart Rate Variability (ms)
  final int restingHeartRate; // bpm
  final DateTime date;

  const RecoverySummary({
    required this.recoveryScore,
    required this.hrv,
    required this.restingHeartRate,
    required this.date,
  });
}

class HydrationSummary {
  final double waterConsumedLiters;
  final double waterGoalLiters;
  final DateTime date;

  const HydrationSummary({
    required this.waterConsumedLiters,
    required this.waterGoalLiters,
    required this.date,
  });

  double get progress =>
      (waterConsumedLiters / waterGoalLiters).clamp(0.0, 1.0);
}
