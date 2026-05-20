import 'package:flutter/material.dart';
import 'package:fitora/core/constants/spacing.dart';
import 'package:fitora/features/home/domain/home_dashboard_models.dart';
import 'package:fitora/shared/widgets/fitora_button.dart';
import 'package:fitora/shared/widgets/glow_container.dart';

class HomeWorkoutHighlightCard extends StatelessWidget {
  final HomeWorkoutHighlight highlight;
  final VoidCallback onPressed;

  const HomeWorkoutHighlightCard({
    super.key,
    required this.highlight,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GlowContainer(
      glowColor: colorScheme.primary.withOpacity(0.2),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final headerHeight = constraints.maxHeight * 0.26;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: headerHeight,
                decoration: BoxDecoration(
                  borderRadius: FitoraSpacing.cardRadius,
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary.withOpacity(0.3),
                      colorScheme.surfaceVariant.withOpacity(0.4),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(FitoraSpacing.md),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(FitoraSpacing.xs),
                          decoration: BoxDecoration(
                            color: colorScheme.surface.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.play_arrow_rounded,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: FitoraSpacing.sm),
                        Text(
                          'Today\'s workout',
                          style: textTheme.labelLarge,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: FitoraSpacing.xs),
              Text(highlight.title, style: textTheme.titleLarge),
              const SizedBox(height: FitoraSpacing.xs),
              Text(
                highlight.subtitle,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: FitoraSpacing.xs),
              Row(
                children: [
                  _InfoPill(label: highlight.durationLabel),
                  const SizedBox(width: FitoraSpacing.sm),
                  _InfoPill(label: highlight.difficultyLabel),
                ],
              ),
              const SizedBox(height: FitoraSpacing.xs),
              FitoraButton(
                label: highlight.ctaLabel,
                leading: const Icon(Icons.play_arrow_rounded),
                onPressed: onPressed,
                isFullWidth: false,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final String label;

  const _InfoPill({required this.label});

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
