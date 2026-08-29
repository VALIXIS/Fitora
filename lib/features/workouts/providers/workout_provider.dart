import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitora/core/storage/app_preferences.dart';
import 'package:fitora/features/workouts/domain/workout_models.dart';
import 'package:fitora/features/gamification/providers/gamification_provider.dart';

final workoutProvider = StateNotifierProvider<WorkoutNotifier, List<WorkoutLogEntry>>((ref) {
  return WorkoutNotifier(ref)..load();
});

class WorkoutNotifier extends StateNotifier<List<WorkoutLogEntry>> {
  final Ref _ref;
  static const _storageKey = 'fitora_workout_history_v1';

  WorkoutNotifier(this._ref) : super([]);

  Future<void> load() async {
    try {
      final prefs = await AppPreferences.instance();
      final raw = prefs.getString(_storageKey);
      if (raw != null) {
        final decoded = jsonDecode(raw) as List<dynamic>;
        state = decoded.map((e) => WorkoutLogEntry.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
  }

  Future<void> _persist() async {
    try {
      final prefs = await AppPreferences.instance();
      final encoded = state.map((e) => e.toJson()).toList();
      await prefs.setString(_storageKey, jsonEncode(encoded));
    } catch (_) {}
  }

  Future<void> addWorkoutLog(WorkoutLogEntry entry) async {
    state = [...state, entry];
    await _persist();
    // Trigger badge verification in gamification notifier
    _ref.read(gamificationProvider.notifier).checkBadges();
  }

  Future<void> deleteWorkoutLog(String id) async {
    state = state.where((element) => element.id != id).toList();
    await _persist();
    _ref.read(gamificationProvider.notifier).checkBadges();
  }
}
