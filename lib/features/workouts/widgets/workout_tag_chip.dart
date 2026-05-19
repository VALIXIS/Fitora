import 'package:flutter/material.dart';
import 'package:fitora/core/constants/spacing.dart';

class WorkoutTagChip extends StatelessWidget {
  final String label;

  const WorkoutTagChip({
    super.key,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: FitoraSpacing.sm,
        vertical: FitoraSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Text(
        label,
        style: textTheme.labelSmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
