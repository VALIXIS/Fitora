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

  ref.listen(dailyActivityProvider(today), (_, __) {
    notifier.checkStreaksAndBadges();
  });

  ref.listen(wellnessProvider, (_, __) {
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
          id: 'streak_3',
          title: '3-Day Fire',
          description: 'Achieve a 3-day step or water streak',
          iconType: 'streak_3',
          category: 'streak',
          isUnlocked: false,
        ),
        const AchievementBadge(
          id: 'streak_7',
          title: '7-Day Warrior',
          description: 'Achieve a 7-day step or water streak',
          iconType: 'streak_7',
          category: 'streak',
          isUnlocked: false,
        ),
        const AchievementBadge(
          id: 'steps_10k',
          title: '10k Steps Club',
          description: 'Walk 10,000 steps in a single day',
          iconType: 'steps_10k',
          category: 'steps',
          isUnlocked: false,
        ),
        const AchievementBadge(
          id: 'workout_first',
          title: 'First Workout Logged',
          description: 'Log your first manual workout session',
          iconType: 'workout_first',
          category: 'workout',
          isUnlocked: false,
        ),
      ];

  Future<void> _load() async {
    try {
      final prefs = await AppPreferences.instance();
      final raw = prefs.getString(_storageKey);
      if (raw != null) {
        state = GamificationState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
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

    // Badge Unlocking Checks
    final now = DateTime.now();
    final todaySteps = _ref.read(dailyActivityProvider(now)).steps;
    final yesterday = now.subtract(const Duration(days: 1));
    final yesterdaySteps = _ref.read(dailyActivityProvider(yesterday)).steps;
    final has10kSteps = todaySteps >= 10000 || yesterdaySteps >= 10000;

    // Workouts logged?
    bool hasWorkout = false;
    try {
      final workouts = _ref.read(workoutProvider);
      hasWorkout = workouts.isNotEmpty;
    } catch (_) {}

    final updatedBadges = state.badges.map((badge) {
      if (badge.isUnlocked) return badge;

      bool shouldUnlock = false;
      if (badge.id == 'streak_3' && currentLongest >= 3) shouldUnlock = true;
      if (badge.id == 'streak_7' && currentLongest >= 7) shouldUnlock = true;
      if (badge.id == 'steps_10k' && has10kSteps) shouldUnlock = true;
      if (badge.id == 'workout_first' && hasWorkout) shouldUnlock = true;

      if (shouldUnlock) {
        return badge.copyWith(
          isUnlocked: true,
          unlockedAt: DateTime.now(),
        );
      }
      return badge;
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
}
