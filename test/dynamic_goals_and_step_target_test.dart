import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitora/core/constants/storage_keys.dart';
import 'package:fitora/core/health/utils/goal_calculator.dart';
import 'package:fitora/core/health/providers/health_providers.dart';
import 'package:fitora/features/personalization/domain/personalization_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Bug 04 - BMI-based Dynamic Goals', () {
    test(
      'Calculates dynamic goals for Normal Weight profile with StayFit goal',
      () {
        final profile = PersonalizationProfile(
          heightCm: 175,
          weightKg: 70,
          age: 28,
          goal: PersonalizationGoal.stayFit,
          experienceLevel: ExperienceLevel.intermediate,
        );

        final goals = HealthGoalCalculator.calculateGoals(profile: profile);

        expect(goals.bmi, closeTo(22.86, 0.1));
        expect(goals.bmiCategory, equals('Normal Weight'));
        expect(goals.stepsGoal, equals(9500));
        expect(goals.caloriesGoal, equals(500.0));
        expect(goals.hydrationGoalLiters, equals(2.6));
      },
    );

    test(
      'Calculates dynamic goals for Overweight profile with LoseWeight goal',
      () {
        final profile = PersonalizationProfile(
          heightCm: 175,
          weightKg: 85,
          age: 30,
          goal: PersonalizationGoal.loseWeight,
          experienceLevel: ExperienceLevel.advanced,
        );

        final goals = HealthGoalCalculator.calculateGoals(profile: profile);

        expect(goals.bmi, closeTo(27.75, 0.1));
        expect(goals.bmiCategory, equals('Overweight'));
        // base 10000 + 1000 (overweight) + 1500 (advanced) = 12500 steps
        expect(goals.stepsGoal, equals(12500));
        // weight 85 * 7 * 1.2 (loseWeight) * 1.1 (BMI>=25) = ~785 kcal -> 775 kcal
        expect(goals.caloriesGoal, greaterThan(700.0));
        // weight 85 * 0.035 + 0.3 (loseWeight) + 0.3 (advanced) = 3.6 L
        expect(goals.hydrationGoalLiters, closeTo(3.6, 0.1));
      },
    );

    test(
      'Calculates dynamic goals for Underweight profile with GainMuscle goal',
      () {
        final profile = PersonalizationProfile(
          heightCm: 170,
          weightKg: 50,
          age: 22,
          goal: PersonalizationGoal.gainMuscle,
          experienceLevel: ExperienceLevel.beginner,
        );

        final goals = HealthGoalCalculator.calculateGoals(profile: profile);

        expect(goals.bmi, closeTo(17.3, 0.1));
        expect(goals.bmiCategory, equals('Underweight'));
        // base 8000 - 1000 (underweight) - 1000 (beginner) = 6000 steps
        expect(goals.stepsGoal, equals(6000));
        // 50 * 7 * 0.85 * 0.9 = ~267 -> clamped min 300 kcal
        expect(goals.caloriesGoal, equals(300.0));
      },
    );

    test('Custom step target overrides dynamic step calculation', () {
      final profile = PersonalizationProfile(
        heightCm: 175,
        weightKg: 70,
        goal: PersonalizationGoal.stayFit,
      );

      final goals = HealthGoalCalculator.calculateGoals(
        profile: profile,
        customStepGoal: 15000,
      );

      expect(goals.stepsGoal, equals(15000));
    });
  });

  group('Bug 05 - Custom Step Target Persistence', () {
    test(
      'CustomStepGoalNotifier loads and persists custom step target',
      () async {
        SharedPreferences.setMockInitialValues({});
        final notifier = CustomStepGoalNotifier();

        expect(notifier.state, isNull);

        await notifier.setGoal(12500);

        expect(notifier.state, equals(12500));

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getInt(StorageKeys.customStepGoal), equals(12500));

        final reloadedNotifier = CustomStepGoalNotifier();
        await reloadedNotifier.load();

        expect(reloadedNotifier.state, equals(12500));
      },
    );
  });
}
