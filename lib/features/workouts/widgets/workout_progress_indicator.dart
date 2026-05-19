import 'package:flutter/material.dart';
import 'package:fitora/core/constants/spacing.dart';

class WorkoutProgressIndicator extends StatelessWidget {
  final int completed;
  final int total;

  const WorkoutProgressIndicator({
    super.key,
    required this.completed,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final progress = total == 0 ? 0.0 : completed / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Progress', style: textTheme.labelLarge),
            const Spacer(),
            Text(
              '$completed of $total exercises',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: FitoraSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: colorScheme.surfaceVariant,
            valueColor: AlwaysStoppedAnimation(colorScheme.primary),
          ),
        ),
      ],
    );
  }
}
