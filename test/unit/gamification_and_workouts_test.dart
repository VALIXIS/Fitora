import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitora/core/storage/app_preferences.dart';
import 'package:fitora/features/gamification/domain/gamification_models.dart';
import 'package:fitora/features/workouts/domain/workout_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppPreferences.initialize();
  });

  group('WorkoutLogEntry Serialization', () {
    test('toJson and fromJson', () {
      final now = DateTime(2026, 8, 25, 12, 0);
      final entry = WorkoutLogEntry(
        id: 'w1',
        activityType: WorkoutActivityType.running,
        durationMinutes: 45,
        estimatedCalories: 360.0,
        timestamp: now,
        notes: 'Steady run',
      );

      final json = entry.toJson();
      expect(json['id'], equals('w1'));
      expect(json['activityType'], equals('running'));
      expect(json['durationMinutes'], equals(45));
      expect(json['estimatedCalories'], equals(360.0));
      expect(json['notes'], equals('Steady run'));

      final restored = WorkoutLogEntry.fromJson(json);
      expect(restored.id, equals('w1'));
      expect(restored.activityType, equals(WorkoutActivityType.running));
      expect(restored.durationMinutes, equals(45));
      expect(restored.estimatedCalories, equals(360.0));
      expect(restored.timestamp, equals(now));
      expect(restored.notes, equals('Steady run'));
    });
  });

  group('Gamification Models Serialization', () {
    test('StreakState toJson and fromJson', () {
      final now = DateTime(2026, 8, 25, 12, 0);
      final state = StreakState(
        currentStepStreak: 3,
        currentWaterStreak: 5,
        longestStreak: 8,
        lastActiveDate: now,
      );

      final json = state.toJson();
      expect(json['currentStepStreak'], equals(3));
      expect(json['currentWaterStreak'], equals(5));
      expect(json['longestStreak'], equals(8));

      final restored = StreakState.fromJson(json);
      expect(restored.currentStepStreak, equals(3));
      expect(restored.currentWaterStreak, equals(5));
      expect(restored.longestStreak, equals(8));
      expect(restored.lastActiveDate, equals(now));
    });

    test('AchievementBadge toJson and fromJson', () {
      final now = DateTime(2026, 8, 25, 12, 0);
      const badge = AchievementBadge(
        id: 'badge1',
        title: '3-Day Fire',
        description: 'Complete 3 days of goals',
        iconType: 'streak_3',
        category: 'streak',
        isUnlocked: true,
        unlockedAt: null,
      );

      final json = badge.copyWith(unlockedAt: now).toJson();
      expect(json['id'], equals('badge1'));
      expect(json['title'], equals('3-Day Fire'));
      expect(json['isUnlocked'], equals(true));

      final restored = AchievementBadge.fromJson(json);
      expect(restored.id, equals('badge1'));
      expect(restored.title, equals('3-Day Fire'));
      expect(restored.iconData.codePoint, equals(Icons.local_fire_department_rounded.codePoint));
      expect(restored.isUnlocked, equals(true));
      expect(restored.unlockedAt, equals(now));
    });
  });

  group('Workout Activity MET Calculation', () {
    test('Estimated calories calculation formulas', () {
      const weight = 70.0;
      const duration = 60; // 1 hour

      final runningCal = WorkoutActivityType.running.metMultiplier * weight * (duration / 60.0);
      expect(runningCal, equals(8.0 * 70.0 * 1.0));

      final walkingCal = WorkoutActivityType.walking.metMultiplier * weight * (duration / 60.0);
      expect(walkingCal, equals(3.8 * 70.0 * 1.0));
    });
  });
}
