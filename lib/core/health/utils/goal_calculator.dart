import 'package:fitora/features/personalization/domain/personalization_models.dart';

class DynamicHealthGoals {
  final int stepsGoal;
  final double caloriesGoal;
  final double hydrationGoalLiters;
  final double? bmi;
  final String bmiCategory;

  const DynamicHealthGoals({
    required this.stepsGoal,
    required this.caloriesGoal,
    required this.hydrationGoalLiters,
    this.bmi,
    required this.bmiCategory,
  });
}

class HealthGoalCalculator {
  /// Calculates personalized health goals based on user metrics, BMI, and custom overrides.
  static DynamicHealthGoals calculateGoals({
    required PersonalizationProfile profile,
    int? customStepGoal,
  }) {
    double? bmi;
    String bmiCategory = 'Normal';

    if (profile.weightKg != null &&
        profile.heightCm != null &&
        profile.heightCm! > 0) {
      final heightM = profile.heightCm! / 100;
      bmi = profile.weightKg! / (heightM * heightM);

      if (bmi < 18.5) {
        bmiCategory = 'Underweight';
      } else if (bmi < 25.0) {
        bmiCategory = 'Normal Weight';
      } else if (bmi < 30.0) {
        bmiCategory = 'Overweight';
      } else {
        bmiCategory = 'Obese';
      }
    }

    // ── 1. STEP GOAL ────────────────────────────────────────────────────────
    int stepsGoal;
    if (customStepGoal != null && customStepGoal > 0) {
      stepsGoal = customStepGoal;
    } else {
      int baseSteps = switch (profile.goal) {
        PersonalizationGoal.loseWeight => 10000,
        PersonalizationGoal.gainMuscle => 8000,
        PersonalizationGoal.stayFit => 9500,
        PersonalizationGoal.improveWellness => 8500,
        PersonalizationGoal.buildHabits => 8000,
        PersonalizationGoal.reduceStress => 7500,
        null => 10000,
      };

      if (bmi != null) {
        if (bmi < 18.5) {
          baseSteps -= 1000;
        } else if (bmi >= 25.0 && bmi < 30.0) {
          baseSteps += 1000;
        } else if (bmi >= 30.0) {
          baseSteps -= 500;
        }
      }

      if (profile.experienceLevel == ExperienceLevel.beginner) {
        baseSteps -= 1000;
      } else if (profile.experienceLevel == ExperienceLevel.advanced) {
        baseSteps += 1500;
      }

      stepsGoal = (baseSteps / 500).round() * 500;
      stepsGoal = stepsGoal.clamp(5000, 25000);
    }

    // ── 2. CALORIE GOAL ─────────────────────────────────────────────────────
    double baseCalories = profile.weightKg != null
        ? profile.weightKg! * 7.0
        : 500.0;

    double goalMultiplier = switch (profile.goal) {
      PersonalizationGoal.loseWeight => 1.2,
      PersonalizationGoal.gainMuscle => 0.85,
      PersonalizationGoal.stayFit => 1.0,
      PersonalizationGoal.improveWellness => 0.9,
      PersonalizationGoal.buildHabits => 0.95,
      PersonalizationGoal.reduceStress => 0.85,
      null => 1.0,
    };
    baseCalories *= goalMultiplier;

    if (bmi != null) {
      if (bmi >= 25.0) {
        baseCalories *= 1.1;
      } else if (bmi < 18.5) {
        baseCalories *= 0.9;
      }
    }

    double caloriesGoal = (baseCalories / 25.0).round() * 25.0;
    caloriesGoal = caloriesGoal.clamp(300.0, 1200.0);

    // ── 3. HYDRATION GOAL ───────────────────────────────────────────────────
    double baseHydration = profile.weightKg != null
        ? profile.weightKg! * 0.035
        : 2.5;

    if (profile.goal == PersonalizationGoal.loseWeight) {
      baseHydration += 0.3;
    } else if (profile.goal == PersonalizationGoal.gainMuscle) {
      baseHydration += 0.2;
    }

    if (profile.experienceLevel == ExperienceLevel.advanced) {
      baseHydration += 0.3;
    } else if (profile.experienceLevel == ExperienceLevel.intermediate) {
      baseHydration += 0.1;
    }

    double hydrationGoal = (baseHydration * 10).round() / 10.0;
    hydrationGoal = hydrationGoal.clamp(1.5, 4.5);

    return DynamicHealthGoals(
      stepsGoal: stepsGoal,
      caloriesGoal: caloriesGoal,
      hydrationGoalLiters: hydrationGoal,
      bmi: bmi,
      bmiCategory: bmiCategory,
    );
  }
}
