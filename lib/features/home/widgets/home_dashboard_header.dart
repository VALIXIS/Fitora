import 'package:flutter/material.dart';
import 'package:fitora/core/constants/spacing.dart';
import 'package:fitora/shared/widgets/glow_container.dart';

class HomeDashboardHeader extends StatelessWidget {
  final String greeting;
  final String subtitle;

  const HomeDashboardHeader({
    super.key,
    required this.greeting,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(greeting, style: textTheme.titleMedium),
              const SizedBox(height: FitoraSpacing.xs),
              Text(
                subtitle,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: FitoraSpacing.md),
        GlowContainer(
          glowColor: colorScheme.primary.withOpacity(0.18),
          padding: const EdgeInsets.all(FitoraSpacing.xs),
          borderRadius: BorderRadius.circular(999),
          child: CircleAvatar(
            radius: 20,
            backgroundColor: colorScheme.surface,
            child: Icon(Icons.person, color: colorScheme.primary),
          ),
        ),
      ],
    );
  }
}
