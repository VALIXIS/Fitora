import 'package:flutter/material.dart';
import 'package:fitora/core/constants/spacing.dart';
import 'package:fitora/features/personalization/domain/personalization_models.dart';
import 'package:fitora/shared/widgets/glow_container.dart';

class PersonalizationStepHeader extends StatelessWidget {
  final PersonalizationStep step;
  final int stepIndex;
  final int totalSteps;
  final double progress;

  const PersonalizationStepHeader({
    super.key,
    required this.step,
    required this.stepIndex,
    required this.totalSteps,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GlowContainer(
      glowColor: colorScheme.primary.withOpacity(0.14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step ${stepIndex + 1} of $totalSteps',
            style: textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: FitoraSpacing.sm),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 240),
            child: Text(
              step.title,
              key: ValueKey(step),
              style: textTheme.headlineSmall,
            ),
          ),
          const SizedBox(height: FitoraSpacing.xs),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 240),
            child: Text(
              step.subtitle,
              key: ValueKey('${step.name}-subtitle'),
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: FitoraSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }
}
