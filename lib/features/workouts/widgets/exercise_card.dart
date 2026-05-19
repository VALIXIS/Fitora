import 'package:flutter/material.dart';
import 'package:fitora/core/constants/spacing.dart';
import 'package:fitora/features/workouts/domain/exercise_models.dart';
import 'package:fitora/shared/widgets/fitora_card.dart';

class ExerciseCard extends StatelessWidget {
  final Exercise exercise;

  const ExerciseCard({
    super.key,
    required this.exercise,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return FitoraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(exercise.title, style: textTheme.titleMedium),
              ),
              Text(
                exercise.dose.summary,
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: FitoraSpacing.xs),
          Text(
            '${exercise.targetMuscle.label} · ${_equipmentLabel(exercise.equipment)}',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: FitoraSpacing.sm),
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
            const SizedBox(height: FitoraSpacing.sm),
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
