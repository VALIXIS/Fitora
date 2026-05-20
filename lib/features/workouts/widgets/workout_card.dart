import 'package:flutter/material.dart';
import 'package:fitora/core/constants/spacing.dart';
import 'package:fitora/features/workouts/domain/workout_models.dart';
import 'package:fitora/features/workouts/widgets/workout_metrics_row.dart';
import 'package:fitora/features/workouts/widgets/workout_tag_chip.dart';
import 'package:fitora/shared/widgets/fitora_card.dart';

class WorkoutCard extends StatelessWidget {
  final Workout workout;
  final VoidCallback onTap;
  final bool compact;

  const WorkoutCard({
    super.key,
    required this.workout,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final spacing = compact ? FitoraSpacing.xs : FitoraSpacing.xs;
    final tagLimit = compact ? 2 : 3;

    return FitoraCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(workout.title, style: textTheme.titleMedium),
          const SizedBox(height: FitoraSpacing.xs),
          Text(
            workout.subtitle,
            maxLines: compact ? 2 : 3,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: spacing),
          WorkoutMetricsRow(workout: workout),
          if (workout.tags.isNotEmpty) ...[
            SizedBox(height: spacing),
            Wrap(
              spacing: FitoraSpacing.sm,
              runSpacing: FitoraSpacing.xs,
              children: workout.tags
                  .take(tagLimit)
                  .map((tag) => WorkoutTagChip(label: _titleCase(tag)))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

String _titleCase(String value) {
  if (value.isEmpty) {
    return value;
  }
  final normalized = value.replaceAll('-', ' ');
  return normalized[0].toUpperCase() + normalized.substring(1);
}
