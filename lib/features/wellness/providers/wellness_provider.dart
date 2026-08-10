import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitora/core/storage/app_preferences.dart';
import 'package:fitora/features/wellness/domain/wellness_models.dart';

final wellnessProvider = StateNotifierProvider<WellnessNotifier, WellnessState>((ref) {
  return WellnessNotifier()..load();
});

class WellnessNotifier extends StateNotifier<WellnessState> {
  WellnessNotifier() : super(WellnessState.initial());

  static const _storageKey = 'fitora_wellness_state_v2';

  String _todayStr() {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  Future<void> load() async {
    try {
      final prefs = await AppPreferences.instance();
      final raw = prefs.getString(_storageKey);
      if (raw != null) {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        state = WellnessState.fromJson(map);
      }
      _checkNewDay();
    } catch (_) {}
  }

  Future<void> _persist() async {
    try {
      final prefs = await AppPreferences.instance();
      await prefs.setString(_storageKey, jsonEncode(state.toJson()));
    } catch (_) {}
  }

  void _checkNewDay() {
    final today = _todayStr();
    if (state.lastActiveDate != today) {
      // Check if they met hydration goal yesterday to maintain hydration streak
      double previousHydration = state.hydrationLiters;
      double previousGoal = state.hydrationGoalLiters;
      
      int newHydrationStreak = state.hydrationStreak;
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yesterdayStr = "${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}";
      
      if (state.lastHydrationDate == yesterdayStr) {
        if (previousHydration < previousGoal) {
          newHydrationStreak = 0; // Broke streak
        }
      } else if (state.lastHydrationDate != today) {
        newHydrationStreak = 0; // Missed day
      }

      // Wellness streak: check if active yesterday
      int newWellnessStreak = state.wellnessStreak;
      if (state.lastActiveDate != yesterdayStr && state.lastActiveDate != today) {
        newWellnessStreak = 0; // Broke streak
      }

      state = state.copyWith(
        hydrationLiters: 0.0,
        breathingMinutes: 0,
        sleepMinutes: 0,
        sleepQualityScore: 0,
        hydrationStreak: newHydrationStreak,
        wellnessStreak: newWellnessStreak,
        // Preserve other historical values
      );
      _persist();
    }
  }

  void _recordWellnessActivity() {
    _checkNewDay();
    final today = _todayStr();
    if (state.lastActiveDate != today) {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yesterdayStr = "${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}";
      
      int newStreak = state.wellnessStreak;
      if (state.lastActiveDate == yesterdayStr) {
        newStreak += 1;
      } else {
        newStreak = 1; // start new
      }
      
      state = state.copyWith(
        wellnessStreak: newStreak,
        lastActiveDate: today,
      );
    }
  }

  int _calculateRecoveryScore({
    double? hydrationLiters,
    double? hydrationGoalLiters,
    int? sleepQualityScore,
    String? muscleFatigue,
    int? energyLevel,
  }) {
    final hyd = hydrationLiters ?? state.hydrationLiters;
    final goal = hydrationGoalLiters ?? state.hydrationGoalLiters;
    final sq = sleepQualityScore ?? state.sleepQualityScore;
    final fatigue = muscleFatigue ?? state.muscleFatigue;
    
    double hydrationPct = goal > 0 ? (hyd / goal).clamp(0.0, 1.0) : 0.0;
    
    int score = 0;
    
    // Sleep contribution: up to 40% (using quality score)
    score += (sq * 0.4).round();
    
    // Hydration contribution: up to 25%
    score += (hydrationPct * 25).round();
    
    // Fatigue contribution: up to 25%
    if (fatigue == 'Low') {
      score += 25;
    } else if (fatigue == 'Medium') {
      score += 12;
    } else {
      score += 3;
    }
    
    // Energy/Mood contribution: up to 10%
    final today = _todayStr();
    final energy = energyLevel ?? state.loggedEnergy[today] ?? 5;
    score += (energy * 1.0).round();
    
    return score.clamp(10, 100);
  }

  void updateRecovery() {
    state = state.copyWith(
      recoveryScore: _calculateRecoveryScore(),
    );
    _persist();
  }

  // ── Hydration actions ────────────────────────────────────────────────────────
  
  Future<void> addWaterLogEntry({required int amountMl, DateTime? timestamp}) async {
    _recordWellnessActivity();
    final now = timestamp ?? DateTime.now();
    final today = _todayStr();
    final id = '${now.microsecondsSinceEpoch}';

    final entry = WaterLogEntry(
      id: id,
      amountMl: amountMl,
      timestamp: now,
      dateStr: today,
    );

    final updatedLogs = [entry, ...state.waterLogs];
    
    final todayTotalMl = updatedLogs
        .where((l) => l.dateStr == today)
        .fold<int>(0, (sum, l) => sum + l.amountMl);

    double newHydration = todayTotalMl / 1000.0;
    int newHydrationStreak = state.hydrationStreak;

    if (newHydration >= state.hydrationGoalLiters && state.hydrationLiters < state.hydrationGoalLiters) {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yesterdayStr = "${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}";

      if (state.lastHydrationDate == yesterdayStr) {
        newHydrationStreak += 1;
      } else if (state.lastHydrationDate != today) {
        newHydrationStreak = 1;
      }
    }

    state = state.copyWith(
      waterLogs: updatedLogs,
      hydrationLiters: newHydration,
      hydrationStreak: newHydrationStreak,
      lastHydrationDate: today,
    );
    updateRecovery();
    await _persist();
  }

  Future<void> deleteWaterLogEntry(String id) async {
    final today = _todayStr();
    final updatedLogs = state.waterLogs.where((l) => l.id != id).toList();

    final todayTotalMl = updatedLogs
        .where((l) => l.dateStr == today)
        .fold<int>(0, (sum, l) => sum + l.amountMl);

    double newHydration = todayTotalMl / 1000.0;

    state = state.copyWith(
      waterLogs: updatedLogs,
      hydrationLiters: newHydration,
    );
    updateRecovery();
    await _persist();
  }

  Future<void> addHydration(double amount) async {
    final amountMl = (amount * 1000.0).round();
    await addWaterLogEntry(amountMl: amountMl);
  }

  Future<void> resetHydration() async {
    final today = _todayStr();
    final updatedLogs = state.waterLogs.where((l) => l.dateStr != today).toList();
    state = state.copyWith(
      waterLogs: updatedLogs,
      hydrationLiters: 0.0,
    );
    updateRecovery();
    await _persist();
  }

  Future<void> setHydrationGoal(double goal) async {
    state = state.copyWith(hydrationGoalLiters: goal.clamp(1.0, 10.0));
    updateRecovery();
  }

  Future<void> toggleHydrationReminders(bool enabled) async {
    state = state.copyWith(hydrationRemindersEnabled: enabled);
    await _persist();
  }

  Future<void> setHydrationReminderFrequency(int minutes) async {
    state = state.copyWith(hydrationReminderFrequencyMinutes: minutes.clamp(15, 480));
    await _persist();
  }

  // ── Guided Breathing actions ──────────────────────────────────────────────────
  
  Future<void> addBreathingMinutes(int amount) async {
    _recordWellnessActivity();
    state = state.copyWith(
      breathingMinutes: state.breathingMinutes + amount,
    );
    await _persist();
  }

  Future<void> setBreathingSettings({
    int? inhaleSeconds,
    int? exhaleSeconds,
    bool? breathingHapticsEnabled,
  }) async {
    state = state.copyWith(
      inhaleSeconds: inhaleSeconds,
      exhaleSeconds: exhaleSeconds,
      breathingHapticsEnabled: breathingHapticsEnabled,
    );
    await _persist();
  }

  // ── Sleep logging actions ─────────────────────────────────────────────────────
  
  Future<void> logSleep({required int minutes, required int qualityScore}) async {
    _recordWellnessActivity();
    final today = _todayStr();
    
    final updatedHistory = Map<String, int>.from(state.sleepLogHistory)..[today] = minutes;
    final updatedScores = Map<String, int>.from(state.sleepScoreHistory)..[today] = qualityScore;
    
    state = state.copyWith(
      sleepMinutes: minutes,
      sleepQualityScore: qualityScore.clamp(0, 100),
      sleepLogHistory: updatedHistory,
      sleepScoreHistory: updatedScores,
    );
    updateRecovery();
  }

  // ── Cycle Tracking actions ────────────────────────────────────────────────────
  
  Future<void> logPeriodStart(String dateStr) async {
    _recordWellnessActivity();
    final dates = List<String>.from(state.periodStartDates);
    if (!dates.contains(dateStr)) {
      dates.add(dateStr);
    }
    
    state = state.copyWith(periodStartDates: dates);
    updateRecovery();
  }

  Future<void> deletePeriodStart(String dateStr) async {
    final dates = List<String>.from(state.periodStartDates)..remove(dateStr);
    state = state.copyWith(periodStartDates: dates);
    updateRecovery();
  }

  Future<void> setCycleSettings({int? cycleLength, int? periodDuration}) async {
    state = state.copyWith(
      cycleLengthDays: cycleLength,
      periodDurationDays: periodDuration,
    );
    updateRecovery();
  }

  Future<void> logCycleSymptom(String dateStr, String symptom) async {
    _recordWellnessActivity();
    final symptoms = Map<String, List<String>>.from(state.loggedSymptoms);
    final daySymptoms = List<String>.from(symptoms[dateStr] ?? []);
    if (!daySymptoms.contains(symptom)) {
      daySymptoms.add(symptom);
    }
    symptoms[dateStr] = daySymptoms;
    
    state = state.copyWith(loggedSymptoms: symptoms);
    await _persist();
  }

  Future<void> removeCycleSymptom(String dateStr, String symptom) async {
    final symptoms = Map<String, List<String>>.from(state.loggedSymptoms);
    if (symptoms.containsKey(dateStr)) {
      final daySymptoms = List<String>.from(symptoms[dateStr] ?? [])..remove(symptom);
      if (daySymptoms.isEmpty) {
        symptoms.remove(dateStr);
      } else {
        symptoms[dateStr] = daySymptoms;
      }
    }
    state = state.copyWith(loggedSymptoms: symptoms);
    await _persist();
  }

  // ── Mood & Energy actions ─────────────────────────────────────────────────────
  
  Future<void> logMood(String mood) async {
    _recordWellnessActivity();
    final today = _todayStr();
    final moods = Map<String, String>.from(state.loggedMoods)..[today] = mood;
    
    state = state.copyWith(loggedMoods: moods);
    updateRecovery();
  }

  Future<void> logEnergy(int level) async {
    _recordWellnessActivity();
    final today = _todayStr();
    final energy = Map<String, int>.from(state.loggedEnergy)..[today] = level.clamp(1, 10);
    
    state = state.copyWith(loggedEnergy: energy);
    updateRecovery();
  }

  Future<void> setMuscleFatigue(String level) async {
    state = state.copyWith(muscleFatigue: level);
    updateRecovery();
  }

  // ── High fidelity predictions helper functions ───────────────────────────────
  
  int get currentCycleDay {
    if (state.periodStartDates.isEmpty) return 14; // default baseline middle day
    
    final sorted = List<String>.from(state.periodStartDates)
      ..sort((a, b) => b.compareTo(a));
    final latestDateStr = sorted.first;
    try {
      final latestDate = DateTime.parse(latestDateStr);
      final today = DateTime.now();
      // Reset times to compare only dates
      final latestDateOnly = DateTime(latestDate.year, latestDate.month, latestDate.day);
      final todayOnly = DateTime(today.year, today.month, today.day);
      final diff = todayOnly.difference(latestDateOnly).inDays;
      if (diff >= 0 && diff < state.cycleLengthDays) {
        return diff + 1;
      }
    } catch (_) {}
    return 14;
  }

  bool get isFertileWindow {
    final day = currentCycleDay;
    // Fertile window is typically cycle days 10 to 16
    return day >= 10 && day <= 16;
  }

  bool get isOvulationDay {
    final day = currentCycleDay;
    // Ovulation is predicted to be day cycleLength - 14 (day 14 for a 28 day cycle)
    final predictedOvulation = state.cycleLengthDays - 14;
    return day == predictedOvulation;
  }

  bool get isPeriodDay {
    final day = currentCycleDay;
    return day <= state.periodDurationDays;
  }
}
