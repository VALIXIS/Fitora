import 'package:flutter/material.dart';
import 'package:fitora/core/constants/spacing.dart';

class WorkoutSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;

  const WorkoutSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: textTheme.titleMedium),
              if (subtitle != null) ...[
                const SizedBox(height: FitoraSpacing.xs),
                Text(
                  subtitle!,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (action != null) ...[
          const SizedBox(width: FitoraSpacing.md),
          action!,
        ],
      ],
    );
  }
}
