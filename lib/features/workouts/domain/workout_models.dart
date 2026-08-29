import 'package:flutter/material.dart';

enum WorkoutActivityType {
  running,
  walking,
  cycling,
  strengthTraining,
  yoga,
  hiit,
}

extension WorkoutActivityTypeX on WorkoutActivityType {
  String get label {
    switch (this) {
      case WorkoutActivityType.running:
        return 'Running';
      case WorkoutActivityType.walking:
        return 'Walking';
      case WorkoutActivityType.cycling:
        return 'Cycling';
      case WorkoutActivityType.strengthTraining:
        return 'Strength Training';
      case WorkoutActivityType.yoga:
        return 'Yoga';
      case WorkoutActivityType.hiit:
        return 'HIIT';
    }
  }

  IconData get icon {
    switch (this) {
      case WorkoutActivityType.running:
        return Icons.directions_run_rounded;
      case WorkoutActivityType.walking:
        return Icons.directions_walk_rounded;
      case WorkoutActivityType.cycling:
        return Icons.directions_bike_rounded;
      case WorkoutActivityType.strengthTraining:
        return Icons.fitness_center_rounded;
      case WorkoutActivityType.yoga:
        return Icons.self_improvement_rounded;
      case WorkoutActivityType.hiit:
        return Icons.bolt_rounded;
    }
  }

  double get metMultiplier {
    switch (this) {
      case WorkoutActivityType.running:
        return 8.0;
      case WorkoutActivityType.walking:
        return 3.8;
      case WorkoutActivityType.cycling:
        return 7.5;
      case WorkoutActivityType.strengthTraining:
        return 5.0;
      case WorkoutActivityType.yoga:
        return 2.5;
      case WorkoutActivityType.hiit:
        return 9.0;
    }
  }
}

class WorkoutLogEntry {
  final String id;
  final WorkoutActivityType activityType;
  final int durationMinutes;
  final double estimatedCalories;
  final DateTime timestamp;
  final String? notes;

  const WorkoutLogEntry({
    required this.id,
    required this.activityType,
    required this.durationMinutes,
    required this.estimatedCalories,
    required this.timestamp,
    this.notes,
  });

  WorkoutLogEntry copyWith({
    String? id,
    WorkoutActivityType? activityType,
    int? durationMinutes,
    double? estimatedCalories,
    DateTime? timestamp,
    String? notes,
  }) {
    return WorkoutLogEntry(
      id: id ?? this.id,
      activityType: activityType ?? this.activityType,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      estimatedCalories: estimatedCalories ?? this.estimatedCalories,
      timestamp: timestamp ?? this.timestamp,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'activityType': activityType.name,
      'durationMinutes': durationMinutes,
      'estimatedCalories': estimatedCalories,
      'timestamp': timestamp.toIso8601String(),
      'notes': notes,
    };
  }

  factory WorkoutLogEntry.fromJson(Map<String, dynamic> json) {
    return WorkoutLogEntry(
      id: json['id'] as String? ?? '',
      activityType: WorkoutActivityType.values.byName(
        json['activityType'] as String? ?? 'running',
      ),
      durationMinutes: json['durationMinutes'] as int? ?? 0,
      estimatedCalories: (json['estimatedCalories'] as num? ?? 0).toDouble(),
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
      notes: json['notes'] as String?,
    );
  }
}
