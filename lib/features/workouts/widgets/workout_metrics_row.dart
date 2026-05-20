import 'package:flutter/material.dart';
import 'package:fitora/core/constants/spacing.dart';
import 'package:fitora/features/workouts/domain/workout_models.dart';
import 'package:fitora/features/workouts/widgets/workout_difficulty_indicator.dart';

class WorkoutMetricsRow extends StatelessWidget {
  final Workout workout;
  final Color? accentColor;

  const WorkoutMetricsRow({
    super.key,
    required this.workout,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Wrap(
      spacing: FitoraSpacing.md,
      runSpacing: FitoraSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _MetricPill(
          icon: Icons.timer_outlined,
          label: workout.durationLabel,
          textTheme: textTheme,
          colorScheme: colorScheme,
        ),
        _MetricPill(
          icon: Icons.local_fire_department_outlined,
          label: workout.caloriesLabel,
          textTheme: textTheme,
          colorScheme: colorScheme,
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              workout.difficulty.label,
              style: textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: FitoraSpacing.xs),
            WorkoutDifficultyIndicator(
              difficulty: workout.difficulty,
              accentColor: accentColor,
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final TextTheme textTheme;
  final ColorScheme colorScheme;

  const _MetricPill({
    required this.icon,
    required this.label,
    required this.textTheme,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: FitoraSpacing.sm,
        vertical: FitoraSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: FitoraSpacing.xs),
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
