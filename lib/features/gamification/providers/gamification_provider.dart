import 'dart:convert';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitora/core/storage/app_preferences.dart';
import 'package:fitora/core/health/providers/health_providers.dart';
import 'package:fitora/features/wellness/providers/wellness_provider.dart';
import 'package:fitora/features/workouts/providers/workout_provider.dart';
import 'package:fitora/features/gamification/domain/gamification_models.dart';

class GamificationState {
  final StreakState streakState;
  final List<AchievementBadge> badges;

  const GamificationState({
    required this.streakState,
    required this.badges,
  });

  GamificationState copyWith({
    StreakState? streakState,
    List<AchievementBadge>? badges,
  }) {
    return GamificationState(
      streakState: streakState ?? this.streakState,
      badges: badges ?? this.badges,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'streakState': streakState.toJson(),
      'badges': badges.map((e) => e.toJson()).toList(),
    };
  }

  factory GamificationState.fromJson(Map<String, dynamic> json) {
    final streakData = json['streakState'] as Map<String, dynamic>?;
    final badgesData = json['badges'] as List<dynamic>?;

    return GamificationState(
      streakState: streakData != null
          ? StreakState.fromJson(streakData)
          : StreakState.initial(),
      badges: badgesData != null
          ? badgesData.map((e) => AchievementBadge.fromJson(e as Map<String, dynamic>)).toList()
          : GamificationNotifier.defaultBadges,
    );
  }
}

final gamificationProvider = StateNotifierProvider<GamificationNotifier, GamificationState>((ref) {
  final notifier = GamificationNotifier(ref);

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  ref.listen(dailyActivityProvider(today), (_, _) {
    notifier.checkStreaksAndBadges();
  });

  ref.listen(wellnessProvider, (_, _) {
    notifier.checkStreaksAndBadges();
  });

  return notifier;
});

class GamificationNotifier extends StateNotifier<GamificationState> {
  final Ref _ref;
  static const _storageKey = 'fitora_gamification_state_v1';

  GamificationNotifier(this._ref)
      : super(GamificationState(
          streakState: StreakState.initial(),
          badges: defaultBadges,
        )) {
    _load();
  }

  static List<AchievementBadge> get defaultBadges => [
        const AchievementBadge(
          id: 'streak_7',
          title: '7-Day Step Warrior',
          description: 'Achieve a 7-day daily step or activity streak',
          iconType: 'streak_7',
          category: 'streak',
          tier: 'gold',
          statRequirement: '7-Day Streak',
          isUnlocked: false,
        ),
        const AchievementBadge(
          id: 'sleep_8h',
          title: '8h Sleep Champion',
          description: 'Log 8 or more hours of restful, high-quality sleep',
          iconType: 'sleep_8h',
          category: 'sleep',
          tier: 'diamond',
          statRequirement: '8+ Hours Sleep',
          isUnlocked: false,
        ),
        const AchievementBadge(
          id: 'water_2l',
          title: '2L Water Champion',
          description: 'Reach 2.0 Liters or more of hydration in a single day',
          iconType: 'water_2l',
          category: 'water',
          tier: 'emerald',
          statRequirement: '2.0L Daily Hydration',
          isUnlocked: false,
        ),
        const AchievementBadge(
          id: 'streak_3',
          title: '3-Day Fire',
          description: 'Achieve a 3-day continuous wellness streak',
          iconType: 'streak_3',
          category: 'streak',
          tier: 'bronze',
          statRequirement: '3-Day Streak',
          isUnlocked: false,
        ),
        const AchievementBadge(
          id: 'steps_10k',
          title: '10k Steps Club',
          description: 'Walk 10,000 steps in a single day',
          iconType: 'steps_10k',
          category: 'steps',
          tier: 'silver',
          statRequirement: '10,000 Steps',
          isUnlocked: false,
        ),
        const AchievementBadge(
          id: 'workout_first',
          title: 'First Workout Logged',
          description: 'Log your first manual workout session',
          iconType: 'workout_first',
          category: 'workout',
          tier: 'bronze',
          statRequirement: '1 Workout',
          isUnlocked: false,
        ),
        const AchievementBadge(
          id: 'recovery_peak',
          title: 'Peak Readiness',
          description: 'Reach an optimal 80%+ recovery score',
          iconType: 'recovery_peak',
          category: 'wellness',
          tier: 'gold',
          statRequirement: '80%+ Recovery',
          isUnlocked: false,
        ),
        const AchievementBadge(
          id: 'wellness_master',
          title: 'Master of Balance',
          description: 'Concurrently hit daily steps, hydration, and sleep goals',
          iconType: 'wellness_master',
          category: 'wellness',
          tier: 'diamond',
          statRequirement: 'Triple Goal Met',
          isUnlocked: false,
        ),
      ];

  Future<void> _load() async {
    try {
      final prefs = await AppPreferences.instance();
      final raw = prefs.getString(_storageKey);
      if (raw != null) {
        final loaded = GamificationState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
        final existingIds = loaded.badges.map((b) => b.id).toSet();
        final missingDefaults = defaultBadges.where((b) => !existingIds.contains(b.id)).toList();
        state = loaded.copyWith(badges: [...loaded.badges, ...missingDefaults]);
      }
      checkStreaksAndBadges();
    } catch (_) {}
  }

  Future<void> _persist() async {
    try {
      final prefs = await AppPreferences.instance();
      await prefs.setString(_storageKey, jsonEncode(state.toJson()));
    } catch (_) {}
  }

  bool _isStepGoalMet(DateTime date) {
    try {
      final activity = _ref.read(dailyActivityProvider(date));
      return activity.steps >= activity.stepsGoal && activity.stepsGoal > 0;
    } catch (_) {
      return false;
    }
  }

  bool _isWaterGoalMet(DateTime date) {
    try {
      final now = DateTime.now();
      final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
      final wellness = _ref.read(wellnessProvider);
      if (isToday) {
        return wellness.hydrationLiters >= wellness.hydrationGoalLiters && wellness.hydrationGoalLiters > 0;
      }
      final dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      final waterLiters = wellness.waterLogHistory[dateStr] ?? 0.0;
      return waterLiters >= wellness.hydrationGoalLiters && wellness.hydrationGoalLiters > 0;
    } catch (_) {
      return false;
    }
  }

  int _calculateStepStreak() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    int streak = 0;
    DateTime date = today;

    if (_isStepGoalMet(date)) {
      while (_isStepGoalMet(date)) {
        streak++;
        date = date.subtract(const Duration(days: 1));
      }
    } else {
      date = today.subtract(const Duration(days: 1));
      while (_isStepGoalMet(date)) {
        streak++;
        date = date.subtract(const Duration(days: 1));
      }
    }
    return streak;
  }

  int _calculateWaterStreak() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    int streak = 0;
    DateTime date = today;

    if (_isWaterGoalMet(date)) {
      while (_isWaterGoalMet(date)) {
        streak++;
        date = date.subtract(const Duration(days: 1));
      }
    } else {
      date = today.subtract(const Duration(days: 1));
      while (_isWaterGoalMet(date)) {
        streak++;
        date = date.subtract(const Duration(days: 1));
      }
    }
    return streak;
  }

  void checkStreaksAndBadges() {
    final stepStreak = _calculateStepStreak();
    final waterStreak = _calculateWaterStreak();
    final currentLongest = max(stepStreak, waterStreak);
    final storedLongest = max(state.streakState.longestStreak, currentLongest);

    final newStreakState = state.streakState.copyWith(
      currentStepStreak: stepStreak,
      currentWaterStreak: waterStreak,
      longestStreak: storedLongest,
      lastActiveDate: DateTime.now(),
    );

    // Badge Unlocking & Stats Checks
    final now = DateTime.now();
    final todaySteps = _ref.read(dailyActivityProvider(now)).steps;
    final yesterday = now.subtract(const Duration(days: 1));
    final yesterdaySteps = _ref.read(dailyActivityProvider(yesterday)).steps;
    final has10kSteps = todaySteps >= 10000 || yesterdaySteps >= 10000;

    final wellness = _ref.read(wellnessProvider);
    final has2lWater = wellness.hydrationLiters >= 2.0;
    final has8hSleep = wellness.sleepMinutes >= 480;
    final hasPeakRecovery = wellness.recoveryScore >= 80;
    final hasTripleGoals = _isStepGoalMet(now) && _isWaterGoalMet(now) && has8hSleep;

    // Workouts logged?
    bool hasWorkout = false;
    try {
      final workouts = _ref.read(workoutProvider);
      hasWorkout = workouts.isNotEmpty;
    } catch (_) {}

    final updatedBadges = state.badges.map((badge) {
      bool shouldUnlock = badge.isUnlocked;
      String currentProgress = badge.currentProgress ?? '';
      double progressRatio = badge.progressRatio;

      if (badge.id == 'streak_7') {
        final streakVal = max(max(stepStreak, currentLongest), storedLongest);
        progressRatio = (streakVal / 7.0).clamp(0.0, 1.0);
        currentProgress = '$streakVal / 7 days';
        if (streakVal >= 7) shouldUnlock = true;
      } else if (badge.id == 'sleep_8h') {
        final sleepHours = wellness.sleepMinutes / 60.0;
        progressRatio = (wellness.sleepMinutes / 480.0).clamp(0.0, 1.0);
        currentProgress = '${sleepHours.toStringAsFixed(1)}h / 8.0h';
        if (has8hSleep) shouldUnlock = true;
      } else if (badge.id == 'water_2l') {
        progressRatio = (wellness.hydrationLiters / 2.0).clamp(0.0, 1.0);
        currentProgress = '${wellness.hydrationLiters.toStringAsFixed(1)}L / 2.0L';
        if (has2lWater) shouldUnlock = true;
      } else if (badge.id == 'streak_3') {
        final streak3Val = max(currentLongest, storedLongest);
        progressRatio = (streak3Val / 3.0).clamp(0.0, 1.0);
        currentProgress = '$streak3Val / 3 days';
        if (streak3Val >= 3) shouldUnlock = true;
      } else if (badge.id == 'steps_10k') {
        final bestSteps = max(todaySteps, yesterdaySteps);
        progressRatio = (bestSteps / 10000.0).clamp(0.0, 1.0);
        currentProgress = '$bestSteps / 10,000';
        if (has10kSteps) shouldUnlock = true;
      } else if (badge.id == 'workout_first') {
        progressRatio = hasWorkout ? 1.0 : 0.0;
        currentProgress = hasWorkout ? '1 / 1 session' : '0 / 1 session';
        if (hasWorkout) shouldUnlock = true;
      } else if (badge.id == 'recovery_peak') {
        progressRatio = (wellness.recoveryScore / 80.0).clamp(0.0, 1.0);
        currentProgress = '${wellness.recoveryScore}% / 80%';
        if (hasPeakRecovery) shouldUnlock = true;
      } else if (badge.id == 'wellness_master') {
        int goalsMet = 0;
        if (_isStepGoalMet(now)) goalsMet++;
        if (_isWaterGoalMet(now) || has2lWater) goalsMet++;
        if (has8hSleep) goalsMet++;
        progressRatio = (goalsMet / 3.0).clamp(0.0, 1.0);
        currentProgress = '$goalsMet / 3 goals';
        if (hasTripleGoals) shouldUnlock = true;
      }

      if (badge.isUnlocked) {
        return badge.copyWith(
          currentProgress: currentProgress.isNotEmpty ? currentProgress : 'Completed',
          progressRatio: 1.0,
        );
      }

      if (shouldUnlock) {
        return badge.copyWith(
          isUnlocked: true,
          unlockedAt: badge.unlockedAt ?? DateTime.now(),
          currentProgress: currentProgress.isNotEmpty ? currentProgress : 'Completed',
          progressRatio: 1.0,
        );
      }

      return badge.copyWith(
        currentProgress: currentProgress,
        progressRatio: progressRatio,
      );
    }).toList();

    state = state.copyWith(
      streakState: newStreakState,
      badges: updatedBadges,
    );

    _persist();
  }

  void checkBadges() {
    checkStreaksAndBadges();
  }

  void updateStreak({
    int? currentStepStreak,
    int? currentWaterStreak,
    int? longestStreak,
  }) {
    state = state.copyWith(
      streakState: state.streakState.copyWith(
        currentStepStreak: currentStepStreak,
        currentWaterStreak: currentWaterStreak,
        longestStreak: longestStreak,
      ),
    );
    checkStreaksAndBadges();
  }
}
