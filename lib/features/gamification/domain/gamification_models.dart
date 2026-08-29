import 'package:flutter/material.dart';

class StreakState {
  final int currentStepStreak;
  final int currentWaterStreak;
  final int longestStreak;
  final DateTime? lastActiveDate;

  const StreakState({
    required this.currentStepStreak,
    required this.currentWaterStreak,
    required this.longestStreak,
    this.lastActiveDate,
  });

  factory StreakState.initial() => const StreakState(
        currentStepStreak: 0,
        currentWaterStreak: 0,
        longestStreak: 0,
        lastActiveDate: null,
      );

  StreakState copyWith({
    int? currentStepStreak,
    int? currentWaterStreak,
    int? longestStreak,
    DateTime? lastActiveDate,
  }) {
    return StreakState(
      currentStepStreak: currentStepStreak ?? this.currentStepStreak,
      currentWaterStreak: currentWaterStreak ?? this.currentWaterStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentStepStreak': currentStepStreak,
      'currentWaterStreak': currentWaterStreak,
      'longestStreak': longestStreak,
      'lastActiveDate': lastActiveDate?.toIso8601String(),
    };
  }

  factory StreakState.fromJson(Map<String, dynamic> json) {
    return StreakState(
      currentStepStreak: json['currentStepStreak'] as int? ?? 0,
      currentWaterStreak: json['currentWaterStreak'] as int? ?? 0,
      longestStreak: json['longestStreak'] as int? ?? 0,
      lastActiveDate: json['lastActiveDate'] != null
          ? DateTime.tryParse(json['lastActiveDate'] as String)
          : null,
    );
  }
}

class AchievementBadge {
  final String id;
  final String title;
  final String description;
  final String iconType;
  final String category; // 'streak', 'steps', 'water', 'workout'
  final bool isUnlocked;
  final DateTime? unlockedAt;

  const AchievementBadge({
    required this.id,
    required this.title,
    required this.description,
    required this.iconType,
    required this.category,
    required this.isUnlocked,
    this.unlockedAt,
  });

  IconData get iconData {
    switch (iconType) {
      case 'streak_3':
        return Icons.local_fire_department_rounded;
      case 'streak_7':
        return Icons.shield_rounded;
      case 'steps_10k':
        return Icons.directions_walk_rounded;
      case 'workout_first':
        return Icons.fitness_center_rounded;
      default:
        return Icons.emoji_events_rounded;
    }
  }

  AchievementBadge copyWith({
    String? id,
    String? title,
    String? description,
    String? iconType,
    String? category,
    bool? isUnlocked,
    DateTime? unlockedAt,
  }) {
    return AchievementBadge(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      iconType: iconType ?? this.iconType,
      category: category ?? this.category,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'iconType': iconType,
      'category': category,
      'isUnlocked': isUnlocked,
      'unlockedAt': unlockedAt?.toIso8601String(),
    };
  }

  factory AchievementBadge.fromJson(Map<String, dynamic> json) {
    return AchievementBadge(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      iconType: json['iconType'] as String? ?? 'default',
      category: json['category'] as String? ?? 'streak',
      isUnlocked: json['isUnlocked'] as bool? ?? false,
      unlockedAt: json['unlockedAt'] != null
          ? DateTime.tryParse(json['unlockedAt'] as String)
          : null,
    );
  }
}
