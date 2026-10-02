import 'package:flutter/material.dart';

enum ShareableMilestoneType {
  sevenDayStreak,
  achievementBadge,
}

class ShareableMilestoneData {
  final ShareableMilestoneType type;
  final String title;
  final String subtitle;
  final String metricValue;
  final String metricUnit;
  final IconData icon;
  final Color accentColor;
  final String? userName;
  final DateTime? date;

  const ShareableMilestoneData({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.metricValue,
    required this.metricUnit,
    required this.icon,
    required this.accentColor,
    this.userName,
    this.date,
  });

  factory ShareableMilestoneData.streak7Day({
    required int streakDays,
    required int totalSteps,
    String? userName,
  }) {
    final stepsFormatted = totalSteps >= 10000
        ? '${(totalSteps / 1000).toStringAsFixed(1)}k'
        : '$totalSteps';
    return ShareableMilestoneData(
      type: ShareableMilestoneType.sevenDayStreak,
      title: '$streakDays-DAY STEP STREAK',
      subtitle: 'Consistency & Momentum Mastered',
      metricValue: stepsFormatted,
      metricUnit: 'TOTAL STEPS LOGGED',
      icon: Icons.local_fire_department_rounded,
      accentColor: const Color(0xFFFF9500),
      userName: userName,
      date: DateTime.now(),
    );
  }

  factory ShareableMilestoneData.achievement({
    required String title,
    required String description,
    required IconData icon,
    required Color accentColor,
    String? userName,
  }) {
    return ShareableMilestoneData(
      type: ShareableMilestoneType.achievementBadge,
      title: title.toUpperCase(),
      subtitle: description,
      metricValue: 'UNLOCKED',
      metricUnit: 'ACHIEVEMENT BADGE',
      icon: icon,
      accentColor: accentColor,
      userName: userName,
      date: DateTime.now(),
    );
  }
}
