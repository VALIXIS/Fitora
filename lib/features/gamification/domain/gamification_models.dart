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
  final String category; // 'streak', 'steps', 'water', 'sleep', 'workout', 'wellness'
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final String tier; // 'gold', 'silver', 'bronze', 'emerald', 'diamond'
  final String? statRequirement;
  final String? currentProgress;
  final double progressRatio; // 0.0 to 1.0

  const AchievementBadge({
    required this.id,
    required this.title,
    required this.description,
    required this.iconType,
    required this.category,
    required this.isUnlocked,
    this.unlockedAt,
    this.tier = 'gold',
    this.statRequirement,
    this.currentProgress,
    this.progressRatio = 0.0,
  });

  IconData get iconData {
    switch (iconType) {
      case 'streak_7_step':
      case 'streak_7':
        return Icons.military_tech_rounded;
      case 'sleep_8h':
        return Icons.nights_stay_rounded;
      case 'water_2l':
        return Icons.water_drop_rounded;
      case 'streak_3':
        return Icons.local_fire_department_rounded;
      case 'steps_10k':
        return Icons.directions_walk_rounded;
      case 'workout_first':
        return Icons.fitness_center_rounded;
      case 'recovery_peak':
        return Icons.bolt_rounded;
      case 'wellness_master':
        return Icons.workspace_premium_rounded;
      default:
        return Icons.emoji_events_rounded;
    }
  }

  /// 3D Metallic gradient colors for the trophy badge faceplate
  List<Color> get metallicGradient {
    if (!isUnlocked) {
      // Dark Gunmetal / Obsidian Metallic finish for locked badges
      return const [
        Color(0xFF2C3437),
        Color(0xFF1E2325),
        Color(0xFF384347),
        Color(0xFF181C1D),
      ];
    }

    switch (tier.toLowerCase()) {
      case 'diamond':
        return const [
          Color(0xFFE0F2FE),
          Color(0xFF38BDF8),
          Color(0xFF0284C7),
          Color(0xFFBAE6FD),
        ];
      case 'emerald':
        return const [
          Color(0xFFD1FAE5),
          Color(0xFF10B981),
          Color(0xFF059669),
          Color(0xFF6EE7B7),
        ];
      case 'silver':
        return const [
          Color(0xFFF1F5F9),
          Color(0xFF94A3B8),
          Color(0xFF64748B),
          Color(0xFFCBD5E1),
        ];
      case 'bronze':
        return const [
          Color(0xFFFED7AA),
          Color(0xFFF97316),
          Color(0xFFC2410C),
          Color(0xFFFB923C),
        ];
      case 'gold':
      default:
        // Radiant 3D Polished Gold
        return const [
          Color(0xFFFEF08A), // Light specular gold
          Color(0xFFEAB308), // Rich gold
          Color(0xFFCA8A04), // Deep amber gold
          Color(0xFFFDE047), // Lustrous yellow highlight
        ];
    }
  }

  Color get glowColor {
    if (!isUnlocked) {
      return const Color(0xFF64748B).withValues(alpha: 0.15);
    }
    switch (tier.toLowerCase()) {
      case 'diamond':
        return const Color(0xFF0ea5e9);
      case 'emerald':
        return const Color(0xFF10B981);
      case 'silver':
        return const Color(0xFF94A3B8);
      case 'bronze':
        return const Color(0xFFF97316);
      case 'gold':
      default:
        return const Color(0xFFEAB308);
    }
  }

  String get formattedUnlockDate {
    if (unlockedAt == null) return 'Locked';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[unlockedAt!.month - 1]} ${unlockedAt!.day}, ${unlockedAt!.year}';
  }

  AchievementBadge copyWith({
    String? id,
    String? title,
    String? description,
    String? iconType,
    String? category,
    bool? isUnlocked,
    DateTime? unlockedAt,
    String? tier,
    String? statRequirement,
    String? currentProgress,
    double? progressRatio,
  }) {
    return AchievementBadge(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      iconType: iconType ?? this.iconType,
      category: category ?? this.category,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      tier: tier ?? this.tier,
      statRequirement: statRequirement ?? this.statRequirement,
      currentProgress: currentProgress ?? this.currentProgress,
      progressRatio: progressRatio ?? this.progressRatio,
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
      'tier': tier,
      'statRequirement': statRequirement,
      'currentProgress': currentProgress,
      'progressRatio': progressRatio,
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
      tier: json['tier'] as String? ?? 'gold',
      statRequirement: json['statRequirement'] as String?,
      currentProgress: json['currentProgress'] as String?,
      progressRatio: (json['progressRatio'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
