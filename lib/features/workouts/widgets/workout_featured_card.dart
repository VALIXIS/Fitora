import 'package:flutter/material.dart';
import 'package:fitora/core/constants/spacing.dart';
import 'package:fitora/features/workouts/domain/workout_models.dart';
import 'package:fitora/features/workouts/widgets/workout_metrics_row.dart';
import 'package:fitora/shared/widgets/glow_container.dart';

class WorkoutFeaturedCard extends StatelessWidget {
  final Workout workout;
  final VoidCallback onTap;

  const WorkoutFeaturedCard({
    super.key,
    required this.workout,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return GlowContainer(
      glowColor: colorScheme.primary.withOpacity(0.18),
      padding: const EdgeInsets.all(FitoraSpacing.xs),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: FitoraSpacing.cardRadius,
          child: Padding(
            padding: const EdgeInsets.all(FitoraSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(workout.title, style: textTheme.titleMedium),
                    const SizedBox(height: FitoraSpacing.xs),
                    Text(
                      workout.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                WorkoutMetricsRow(
                  workout: workout,
                  accentColor: colorScheme.secondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
