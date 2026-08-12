class WellnessState {
  // Hydration
  final double hydrationLiters;
  final double hydrationGoalLiters;
  final int hydrationStreak;
  final String? lastHydrationDate;
  final bool hydrationRemindersEnabled;
  final int hydrationReminderFrequencyMinutes; // e.g. 60, 90, 120
  final Map<String, double> waterLogHistory; // date string -> waterLiters

  // Guided Breathing
  final int breathingMinutes;
  final int inhaleSeconds;
  final int exhaleSeconds;
  final bool breathingHapticsEnabled;

  // Sleep Tracking
  final int sleepMinutes;
  final int sleepQualityScore; // 0 to 100
  final Map<String, int> sleepLogHistory; // date string -> sleepMinutes
  final Map<String, int> sleepScoreHistory; // date string -> sleepScore

  // Women's Cycle Tracking
  final int cycleLengthDays;
  final int periodDurationDays;
  final List<String> periodStartDates; // List of period start dates (YYYY-MM-DD)
  final Map<String, List<String>> loggedSymptoms; // date string -> list of symptoms

  // Mood & Energy
  final Map<String, String> loggedMoods; // date string -> mood name
  final Map<String, int> loggedEnergy; // date string -> energy level (1-10)

  // Recovery & Muscle Fatigue
  final int recoveryScore;
  final String muscleFatigue; // 'Low', 'Medium', 'High'

  // General Wellness Streak
  final int wellnessStreak;
  final String? lastActiveDate; // YYYY-MM-DD of last wellness activity

  const WellnessState({
    required this.hydrationLiters,
    required this.hydrationGoalLiters,
    required this.hydrationStreak,
    this.lastHydrationDate,
    required this.hydrationRemindersEnabled,
    required this.hydrationReminderFrequencyMinutes,
    this.waterLogHistory = const {},
    required this.breathingMinutes,
    required this.inhaleSeconds,
    required this.exhaleSeconds,
    required this.breathingHapticsEnabled,
    required this.sleepMinutes,
    required this.sleepQualityScore,
    required this.sleepLogHistory,
    required this.sleepScoreHistory,
    required this.cycleLengthDays,
    required this.periodDurationDays,
    required this.periodStartDates,
    required this.loggedSymptoms,
    required this.loggedMoods,
    required this.loggedEnergy,
    required this.recoveryScore,
    required this.muscleFatigue,
    required this.wellnessStreak,
    this.lastActiveDate,
  });

  factory WellnessState.initial() => WellnessState(
        hydrationLiters: 0.0,
        hydrationGoalLiters: 2.5,
        hydrationStreak: 0,
        lastHydrationDate: null,
        hydrationRemindersEnabled: false,
        hydrationReminderFrequencyMinutes: 60,
        waterLogHistory: const {},
        breathingMinutes: 0,
        inhaleSeconds: 4,
        exhaleSeconds: 4,
        breathingHapticsEnabled: true,
        sleepMinutes: 0,
        sleepQualityScore: 0,
        sleepLogHistory: const {},
        sleepScoreHistory: const {},
        cycleLengthDays: 28,
        periodDurationDays: 5,
        periodStartDates: const [],
        loggedSymptoms: const {},
        loggedMoods: const {},
        loggedEnergy: const {},
        recoveryScore: 82,
        muscleFatigue: 'Low',
        wellnessStreak: 0,
        lastActiveDate: null,
      );

  WellnessState copyWith({
    double? hydrationLiters,
    double? hydrationGoalLiters,
    int? hydrationStreak,
    String? lastHydrationDate,
    bool? hydrationRemindersEnabled,
    int? hydrationReminderFrequencyMinutes,
    Map<String, double>? waterLogHistory,
    int? breathingMinutes,
    int? inhaleSeconds,
    int? exhaleSeconds,
    bool? breathingHapticsEnabled,
    int? sleepMinutes,
    int? sleepQualityScore,
    Map<String, int>? sleepLogHistory,
    Map<String, int>? sleepScoreHistory,
    int? cycleLengthDays,
    int? periodDurationDays,
    List<String>? periodStartDates,
    Map<String, List<String>>? loggedSymptoms,
    Map<String, String>? loggedMoods,
    Map<String, int>? loggedEnergy,
    int? recoveryScore,
    String? muscleFatigue,
    int? wellnessStreak,
    String? lastActiveDate,
  }) {
    return WellnessState(
      hydrationLiters: hydrationLiters ?? this.hydrationLiters,
      hydrationGoalLiters: hydrationGoalLiters ?? this.hydrationGoalLiters,
      hydrationStreak: hydrationStreak ?? this.hydrationStreak,
      lastHydrationDate: lastHydrationDate ?? this.lastHydrationDate,
      hydrationRemindersEnabled: hydrationRemindersEnabled ?? this.hydrationRemindersEnabled,
      hydrationReminderFrequencyMinutes: hydrationReminderFrequencyMinutes ?? this.hydrationReminderFrequencyMinutes,
      waterLogHistory: waterLogHistory ?? this.waterLogHistory,
      breathingMinutes: breathingMinutes ?? this.breathingMinutes,
      inhaleSeconds: inhaleSeconds ?? this.inhaleSeconds,
      exhaleSeconds: exhaleSeconds ?? this.exhaleSeconds,
      breathingHapticsEnabled: breathingHapticsEnabled ?? this.breathingHapticsEnabled,
      sleepMinutes: sleepMinutes ?? this.sleepMinutes,
      sleepQualityScore: sleepQualityScore ?? this.sleepQualityScore,
      sleepLogHistory: sleepLogHistory ?? this.sleepLogHistory,
      sleepScoreHistory: sleepScoreHistory ?? this.sleepScoreHistory,
      cycleLengthDays: cycleLengthDays ?? this.cycleLengthDays,
      periodDurationDays: periodDurationDays ?? this.periodDurationDays,
      periodStartDates: periodStartDates ?? this.periodStartDates,
      loggedSymptoms: loggedSymptoms ?? this.loggedSymptoms,
      loggedMoods: loggedMoods ?? this.loggedMoods,
      loggedEnergy: loggedEnergy ?? this.loggedEnergy,
      recoveryScore: recoveryScore ?? this.recoveryScore,
      muscleFatigue: muscleFatigue ?? this.muscleFatigue,
      wellnessStreak: wellnessStreak ?? this.wellnessStreak,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hydrationLiters': hydrationLiters,
      'hydrationGoalLiters': hydrationGoalLiters,
      'hydrationStreak': hydrationStreak,
      'lastHydrationDate': lastHydrationDate,
      'hydrationRemindersEnabled': hydrationRemindersEnabled,
      'hydrationReminderFrequencyMinutes': hydrationReminderFrequencyMinutes,
      'waterLogHistory': waterLogHistory,
      'breathingMinutes': breathingMinutes,
      'inhaleSeconds': inhaleSeconds,
      'exhaleSeconds': exhaleSeconds,
      'breathingHapticsEnabled': breathingHapticsEnabled,
      'sleepMinutes': sleepMinutes,
      'sleepQualityScore': sleepQualityScore,
      'sleepLogHistory': sleepLogHistory,
      'sleepScoreHistory': sleepScoreHistory,
      'cycleLengthDays': cycleLengthDays,
      'periodDurationDays': periodDurationDays,
      'periodStartDates': periodStartDates,
      'loggedSymptoms': loggedSymptoms,
      'loggedMoods': loggedMoods,
      'loggedEnergy': loggedEnergy,
      'recoveryScore': recoveryScore,
      'muscleFatigue': muscleFatigue,
      'wellnessStreak': wellnessStreak,
      'lastActiveDate': lastActiveDate,
    };
  }

  factory WellnessState.fromJson(Map<String, dynamic> map) {
    return WellnessState(
      hydrationLiters: (map['hydrationLiters'] as num?)?.toDouble() ?? 0.0,
      hydrationGoalLiters: (map['hydrationGoalLiters'] as num?)?.toDouble() ?? 2.5,
      hydrationStreak: (map['hydrationStreak'] as num?)?.toInt() ?? 0,
      lastHydrationDate: map['lastHydrationDate'] as String?,
      hydrationRemindersEnabled: map['hydrationRemindersEnabled'] as bool? ?? false,
      hydrationReminderFrequencyMinutes: (map['hydrationReminderFrequencyMinutes'] as num?)?.toInt() ?? 60,
      waterLogHistory: (map['waterLogHistory'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, (v as num).toDouble()),
          ) ??
          const {},
      breathingMinutes: (map['breathingMinutes'] as num?)?.toInt() ?? 0,
      inhaleSeconds: (map['inhaleSeconds'] as num?)?.toInt() ?? 4,
      exhaleSeconds: (map['exhaleSeconds'] as num?)?.toInt() ?? 4,
      breathingHapticsEnabled: map['breathingHapticsEnabled'] as bool? ?? true,
      sleepMinutes: (map['sleepMinutes'] as num?)?.toInt() ?? 0,
      sleepQualityScore: (map['sleepQualityScore'] as num?)?.toInt() ?? 0,
      sleepLogHistory: (map['sleepLogHistory'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, (v as num).toInt()),
          ) ??
          const {},
      sleepScoreHistory: (map['sleepScoreHistory'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, (v as num).toInt()),
          ) ??
          const {},
      cycleLengthDays: (map['cycleLengthDays'] as num?)?.toInt() ?? 28,
      periodDurationDays: (map['periodDurationDays'] as num?)?.toInt() ?? 5,
      periodStartDates: (map['periodStartDates'] as List<dynamic>?)?.map((e) => e as String).toList() ?? const [],
      loggedSymptoms: (map['loggedSymptoms'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, (v as List<dynamic>).map((e) => e as String).toList()),
          ) ??
          const {},
      loggedMoods: (map['loggedMoods'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v as String),
          ) ??
          const {},
      loggedEnergy: (map['loggedEnergy'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, (v as num).toInt()),
          ) ??
          const {},
      recoveryScore: (map['recoveryScore'] as num?)?.toInt() ?? 82,
      muscleFatigue: map['muscleFatigue'] as String? ?? 'Low',
      wellnessStreak: (map['wellnessStreak'] as num?)?.toInt() ?? 0,
      lastActiveDate: map['lastActiveDate'] as String?,
    );
  }
}
