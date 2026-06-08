import 'package:flutter/foundation.dart';

enum AICoachMood {
  idle,
  thinking,
  speaking,
  comforting,
  encouraging,
}

@immutable
class CoachMessage {
  final String id;
  final String sender; // 'user' or 'coach'
  final String content;
  final DateTime timestamp;
  final List<String> suggestedPrompts;

  const CoachMessage({
    required this.id,
    required this.sender,
    required this.content,
    required this.timestamp,
    this.suggestedPrompts = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender': sender,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'suggestedPrompts': suggestedPrompts,
    };
  }

  factory CoachMessage.fromJson(Map<String, dynamic> json) {
    return CoachMessage(
      id: json['id'] as String,
      sender: json['sender'] as String,
      content: json['content'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      suggestedPrompts: (json['suggestedPrompts'] as List?)?.map((e) => e as String).toList() ?? const [],
    );
  }
}

@immutable
class WellnessTrend {
  final String label; // E.g., 'Mon', 'Tue'
  final int steps;
  final double sleepHours;
  final double waterLiters;
  final int readinessScore;
  final int moodValue; // 1-5 scale

  const WellnessTrend({
    required this.label,
    required this.steps,
    required this.sleepHours,
    required this.waterLiters,
    required this.readinessScore,
    required this.moodValue,
  });
}

@immutable
class WeeklySummary {
  final double weeklyReadinessAvg;
  final double weeklyStepsAvg;
  final double weeklySleepHoursAvg;
  final double weeklyWaterLitersAvg;
  final String primaryRecoverySuggestion;
  final String energyWorkoutRecommendation;
  final String moodWellnessCoaching;

  const WeeklySummary({
    required this.weeklyReadinessAvg,
    required this.weeklyStepsAvg,
    required this.weeklySleepHoursAvg,
    required this.weeklyWaterLitersAvg,
    required this.primaryRecoverySuggestion,
    required this.energyWorkoutRecommendation,
    required this.moodWellnessCoaching,
  });

  factory WeeklySummary.defaults() {
    return const WeeklySummary(
      weeklyReadinessAvg: 76.5,
      weeklyStepsAvg: 8900.0,
      weeklySleepHoursAvg: 7.2,
      weeklyWaterLitersAvg: 2.1,
      primaryRecoverySuggestion: 'Your slow wave sleep has been slightly compressed. Prioritize a dark, screen-free room 45 mins before bedtime to boost slow-wave recovery.',
      energyWorkoutRecommendation: 'Readiness is moderate with high sleep debt. We recommend a 25-minute Restorative Flow or an active outdoor stroll rather than high-intensity intervals.',
      moodWellnessCoaching: 'Tension scores peaked on Tuesday. Integrate a 5-minute boxed breathing session mid-day to transition your nervous system from sympathetic to parasympathetic dominance.',
    );
  }
}
