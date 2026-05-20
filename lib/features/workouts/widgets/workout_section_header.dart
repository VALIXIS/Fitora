import 'package:flutter/material.dart';
import 'package:fitora/core/constants/spacing.dart';
import 'package:fitora/shared/widgets/glow_container.dart';

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
        GlowContainer(
          glowColor: colorScheme.primary.withOpacity(0.12),
          padding: const EdgeInsets.all(FitoraSpacing.xs),
          borderRadius: BorderRadius.circular(12),
          child: Icon(Icons.auto_awesome_rounded, size: 16, color: colorScheme.primary),
        ),
        const SizedBox(width: FitoraSpacing.sm),
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
