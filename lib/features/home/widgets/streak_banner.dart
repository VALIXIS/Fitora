import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitora/features/gamification/providers/gamification_provider.dart';

class StreakBanner extends ConsumerWidget {
  const StreakBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gamification = ref.watch(gamificationProvider);
    final streak = gamification.streakState;
    final currentStreak = max(streak.currentStepStreak, streak.currentWaterStreak);

    if (currentStreak == 0) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final tt = theme.textTheme;

    String subtitle = 'Keep going! Complete your step or water goals to grow your streak.';
    if (currentStreak >= 7) {
      subtitle = 'Incredible dedication! You are a true wellness warrior.';
    } else if (currentStreak >= 3) {
      subtitle = 'You are building some great momentum. Keep it burning!';
    }

    final isDark = theme.brightness == Brightness.dark;

    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark 
              ? const Color(0xFF2E1A05) 
              : Colors.orange.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.orange.withValues(alpha: isDark ? 0.2 : 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Text(
                '🔥',
                style: TextStyle(fontSize: 24),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$currentStreak Day Goal Streak',
                    style: tt.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.orangeAccent : Colors.orange.shade800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: tt.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
