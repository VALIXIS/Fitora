import 'package:flutter/material.dart';
import 'package:fitora/features/wellness/domain/wellness_models.dart';
import 'package:fitora/features/progress/domain/progress_models.dart';
import 'package:fitora/features/wellness_engine/domain/wellness_engine_models.dart';

class WellnessEngineService {
  WellnessEngineState process({
    required WellnessState wellness,
    required List<WorkoutHistoryEntry> history,
  }) {
    // 1. Compute Readiness
    final readiness = _calculateReadiness(wellness);

    // 2. Generate Adaptive Recommendations
    final recommendations = _generateRecommendations(readiness, wellness, history);

    // 3. Generate Insights
    final insights = _generateInsights(wellness, readiness);

    // 4. Calculate Adaptive Goals
    final goals = _calculateGoals(wellness, readiness);

    // 5. Build Streak Report
    final streaks = _buildStreaks(wellness, history);

    return WellnessEngineState(
      readiness: readiness,
      recommendations: recommendations,
      insights: insights,
      goals: goals,
      streaks: streaks,
      isLoaded: true,
    );
  }

  // ── READINESS SCORE ENGINE ──────────────────────────────────────────────────
  ReadinessState _calculateReadiness(WellnessState wellness) {
    var score = 50; // Starting baseline

    // Sleep Contribution (Max 25 pts)
    final sleepScore = wellness.sleepQualityScore;
    if (sleepScore > 0) {
      score += (sleepScore * 0.25).round();
    } else {
      score += 10; // Neutral default if not logged
    }

    // Hydration Contribution (Max 15 pts)
    final hydrationRatio = (wellness.hydrationLiters / wellness.hydrationGoalLiters).clamp(0.0, 1.0);
    score += (hydrationRatio * 15).round();

    // Muscle Soreness / Fatigue (Max +10 or -15 pts)
    if (wellness.muscleFatigue == 'Low') {
      score += 10;
    } else if (wellness.muscleFatigue == 'Medium') {
      score += 3;
    } else {
      score -= 15; // High fatigue reduces readiness
    }

    // Mood & Energy logs (Max 10 pts)
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final todayEnergy = wellness.loggedEnergy[todayStr];
    if (todayEnergy != null) {
      score += todayEnergy; // 1-10 level directly contributes
    } else {
      score += 5;
    }

    // Symptom deduction (Deduct 5 pts per symptom)
    final todaySymptoms = wellness.loggedSymptoms[todayStr] ?? const [];
    score -= (todaySymptoms.length * 5);

    // Clamp score strictly between 0 and 100
    final finalScore = score.clamp(0, 100);

    // Determine state labels
    ReadinessLevel level;
    if (finalScore >= 85) {
      level = ReadinessLevel.optimal;
    } else if (finalScore >= 65) {
      level = ReadinessLevel.good;
    } else if (finalScore >= 45) {
      level = ReadinessLevel.recovering;
    } else {
      level = ReadinessLevel.fatigued;
    }

    return ReadinessState(
      score: finalScore,
      level: level,
      description: level.description,
    );
  }

  // ── ADAPTIVE WORKOUT RECOMMENDATION ENGINE ───────────────────────────────────
  List<AdaptiveWorkoutRecommendation> _generateRecommendations(
    ReadinessState readiness,
    WellnessState wellness,
    List<WorkoutHistoryEntry> history,
  ) {
    final recommendations = <AdaptiveWorkoutRecommendation>[];

    switch (readiness.level) {
      case ReadinessLevel.optimal:
        recommendations.add(const AdaptiveWorkoutRecommendation(
          title: 'Full-Body Gym Sculpt',
          intensity: 'High',
          categoryLabel: 'Gym',
          reason: 'Your peak readiness and low physical fatigue make today perfect for strength progression.',
          actionLabel: 'Go to Gym Catalog',
        ));
        recommendations.add(const AdaptiveWorkoutRecommendation(
          title: 'HIIT Cardio Burner',
          intensity: 'High',
          categoryLabel: 'Home',
          reason: 'Fully energized sleep metric enables powerful cardiorespiratory conditioning today.',
          actionLabel: 'Start Cardio',
        ));
        break;

      case ReadinessLevel.good:
        recommendations.add(const AdaptiveWorkoutRecommendation(
          title: 'Sunset Sculpt Flow',
          intensity: 'Moderate',
          categoryLabel: 'Home',
          reason: 'A steady energy baseline supports an active muscular sculpting session.',
          actionLabel: 'Start Sunset Sculpt',
        ));
        recommendations.add(const AdaptiveWorkoutRecommendation(
          title: 'Dumbbell Upper Body',
          intensity: 'Moderate',
          categoryLabel: 'Gym',
          reason: 'Maintains functional strength without overtraining your nervous system.',
          actionLabel: 'View Workout',
        ));
        break;

      case ReadinessLevel.recovering:
        recommendations.add(const AdaptiveWorkoutRecommendation(
          title: 'Gentle Mobility Flow',
          intensity: 'Recovery',
          categoryLabel: 'Wellness',
          reason: 'Light stretching and mobility work will flush out muscle fatigue and stiffness.',
          actionLabel: 'Begin Flow',
        ));
        recommendations.add(const AdaptiveWorkoutRecommendation(
          title: 'Guided Outdoor Walk',
          intensity: 'Low',
          categoryLabel: 'Home',
          reason: 'Slight fatigue detected. Active walking promotes blood flow and enhances recovery.',
          actionLabel: 'Track Walk',
        ));
        break;

      case ReadinessLevel.fatigued:
        recommendations.add(const AdaptiveWorkoutRecommendation(
          title: 'Calm Breathing & Stretch',
          intensity: 'Rest/Recovery',
          categoryLabel: 'Wellness',
          reason: 'Deep physical stress identified. Prioritize box breathing and recovery alignment.',
          actionLabel: 'Enter Calm Zone',
        ));
        recommendations.add(const AdaptiveWorkoutRecommendation(
          title: 'Pure Recovery Rest Day',
          intensity: 'Rest',
          categoryLabel: 'Wellness',
          reason: 'Significant fatigue markers. Give your muscles time to rebuild and rest.',
          actionLabel: 'Relax & Log Water',
        ));
        break;
    }

    return recommendations;
  }

  // ── WELLNESS INSIGHTS ENGINE ─────────────────────────────────────────────────
  List<WellnessInsightCard> _generateInsights(WellnessState wellness, ReadinessState readiness) {
    final insights = <WellnessInsightCard>[];

    // Hydration Insight
    if (wellness.hydrationLiters < 1.2) {
      insights.add(const WellnessInsightCard(
        title: 'Hydration Low Today',
        message: 'Water levels are low. Drinking 2 more cups will directly support cellular recovery and energy.',
        type: 'hydration',
        icon: Icons.water_drop_rounded,
        accentColor: Colors.cyan,
      ));
    } else if (wellness.hydrationLiters >= wellness.hydrationGoalLiters) {
      insights.add(const WellnessInsightCard(
        title: 'Optimal Hydration reached!',
        message: 'Fabulous work! Meeting your hydration quota improves cognitive focus and joint lubrication.',
        type: 'hydration',
        icon: Icons.check_circle_outline_rounded,
        accentColor: Colors.teal,
      ));
    }

    // Sleep Insight
    if (wellness.sleepMinutes > 0 && wellness.sleepMinutes < 360) {
      insights.add(const WellnessInsightCard(
        title: 'Sleep Debt Detected',
        message: 'You logged under 6 hours last night. A short 5-minute breathing session helps clear fatigue.',
        type: 'sleep',
        icon: Icons.nights_stay_rounded,
        accentColor: Colors.deepPurpleAccent,
      ));
    } else if (wellness.sleepQualityScore >= 85) {
      insights.add(const WellnessInsightCard(
        title: 'Premium Rest Quality',
        message: 'High-quality deep sleep. Your recovery rate is 12% faster today.',
        type: 'sleep',
        icon: Icons.stars_rounded,
        accentColor: Colors.amber,
      ));
    }

    // Fatigue Soreness Insight
    if (wellness.muscleFatigue == 'High') {
      insights.add(const WellnessInsightCard(
        title: 'Muscular Fatigue Elevated',
        message: 'High muscle soreness logged. We recommend avoiding heavy resistance lifts today.',
        type: 'recovery',
        icon: Icons.healing_rounded,
        accentColor: Colors.redAccent,
      ));
    } else {
      insights.add(const WellnessInsightCard(
        title: 'Active Muscle Recovery',
        message: 'Muscle stress is low. Good condition to push standard training volume.',
        type: 'recovery',
        icon: Icons.trending_up_rounded,
        accentColor: Colors.teal,
      ));
    }

    // Wellness Active Streaks encouragement
    if (wellness.wellnessStreak > 2) {
      insights.add(WellnessInsightCard(
        title: 'Streak Rising! 🔥',
        message: 'You are on a ${wellness.wellnessStreak}-day wellness streak. Consistency is the ultimate wellness compound.',
        type: 'stretching',
        icon: Icons.whatshot_rounded,
        accentColor: Colors.orangeAccent,
      ));
    }

    // Fallback baseline insight if lists are empty
    if (insights.isEmpty) {
      insights.add(const WellnessInsightCard(
        title: 'Evolving Dashboard',
        message: 'Fitora learns from your logs! Track steps, hydration, sleep, or wellness daily for personalized guidance.',
        type: 'stretching',
        icon: Icons.lightbulb_outline_rounded,
        accentColor: Colors.teal,
      ));
    }

    return insights;
  }

  // ── DAILY GOALS ENGINE ───────────────────────────────────────────────────────
  DailyGoals _calculateGoals(WellnessState wellness, ReadinessState readiness) {
    // Dynamically adjust daily steps and mindfulness goals based on readiness score
    var baseSteps = 8000;
    var baseMindfulness = 10;

    if (readiness.score >= 85) {
      baseSteps = 10000; // Optimal state: encourage higher activity!
      baseMindfulness = 8;
    } else if (readiness.score < 50) {
      baseSteps = 5500;  // Fatigue/Recovering state: encourage active recovery walks
      baseMindfulness = 15; // Higher mindfulness focus for recovery
    }

    // Hydration targets scale higher if user is active/sore
    var hydrationGoal = 2.5;
    if (wellness.muscleFatigue == 'High') {
      hydrationGoal = 3.0; // Needs more hydration to flush lactic acids
    }

    return DailyGoals(
      stepsGoal: baseSteps,
      hydrationGoalLiters: hydrationGoal,
      mindfulnessMinutesGoal: baseMindfulness,
      sleepHoursGoal: 8.0,
    );
  }

  // ── HABIT & STREAK ENGINE ────────────────────────────────────────────────────
  StreakReport _buildStreaks(WellnessState wellness, List<WorkoutHistoryEntry> history) {
    // 1. Workout Streak calculation
    var workoutStreak = 0;
    if (history.isNotEmpty) {
      // Basic mock check - count consecutive active days in history
      final uniqueDays = history.map((e) => e.completedAt.toIso8601String().substring(0, 10)).toSet().toList();
      uniqueDays.sort((a, b) => b.compareTo(a));
      
      final todayStr = DateTime.now().toString().substring(0, 10);
      
      if (uniqueDays.contains(todayStr)) {
        workoutStreak = 1;
        var checkDate = DateTime.now().subtract(const Duration(days: 1));
        while (uniqueDays.contains(checkDate.toIso8601String().substring(0, 10))) {
          workoutStreak++;
          checkDate = checkDate.subtract(const Duration(days: 1));
        }
      }
    }

    return StreakReport(
      workoutStreak: workoutStreak > 0 ? workoutStreak : 1,
      hydrationStreak: wellness.hydrationStreak,
      sleepConsistencyScore: wellness.sleepQualityScore > 0 ? wellness.sleepQualityScore : 84,
      mindfulnessStreak: wellness.wellnessStreak,
    );
  }
}
