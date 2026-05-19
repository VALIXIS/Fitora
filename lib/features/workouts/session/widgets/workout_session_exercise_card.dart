import 'package:flutter/material.dart';
import 'package:fitora/core/constants/spacing.dart';
import 'package:fitora/features/workouts/domain/exercise_models.dart';
import 'package:fitora/shared/widgets/glow_container.dart';

class WorkoutSessionExerciseCard extends StatelessWidget {
  final Exercise exercise;

  const WorkoutSessionExerciseCard({
    super.key,
    required this.exercise,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return GlowContainer(
      glowColor: colorScheme.primary.withOpacity(0.16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(exercise.title, style: textTheme.titleLarge),
          const SizedBox(height: FitoraSpacing.xs),
          Text(
            exercise.dose.summary,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: FitoraSpacing.sm),
          Text(
            '${exercise.targetMuscle.label} · ${_equipmentLabel(exercise.equipment)}',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: FitoraSpacing.md),
          ...exercise.instructions.map(
            (instruction) => Padding(
              padding: const EdgeInsets.only(bottom: FitoraSpacing.xs),
              child: Text(
                '• $instruction',
                style: textTheme.bodySmall,
              ),
            ),
          ),
          if (exercise.beginnerTip != null) ...[
            const SizedBox(height: FitoraSpacing.md),
            Container(
              padding: const EdgeInsets.all(FitoraSpacing.sm),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant,
                borderRadius: FitoraSpacing.cardRadius,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 18,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: FitoraSpacing.sm),
                  Expanded(
                    child: Text(
                      exercise.beginnerTip!,
                      style: textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

String _equipmentLabel(List<Equipment> equipment) {
  if (equipment.isEmpty) {
    return 'No equipment';
  }
  final labels = equipment.map((item) => item.label).toList();
  if (labels.length == 1) {
    return labels.first;
  }
  return labels.take(2).join(' · ');
}
