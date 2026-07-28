import 'package:flutter/material.dart';
import 'package:fitora/core/constants/spacing.dart';
import 'package:fitora/features/workouts/domain/workout_models.dart';
import 'package:fitora/features/workouts/widgets/workout_metrics_row.dart';
import 'package:fitora/features/workouts/widgets/workout_tag_chip.dart';
import 'package:fitora/core/theme/fitora_colors.dart';
import 'package:fitora/shared/widgets/glow_container.dart';

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
    final spacing = compact ? FitoraSpacing.xs : FitoraSpacing.xs;
    final tagLimit = compact ? 2 : 3;

    return GlowContainer(
      glowColor: FitoraColors.mintGreen.withValues(alpha: 0.15),
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Stack(
              children: [
                // Subtle gradient background
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomLeft,
                        end: Alignment.topRight,
                        colors: [
                          const Color(0xFF142020),
                          const Color(0xFF1A2626).withOpacity(0.8),
                        ],
                      ),
                    ),
                  ),
                ),
                // Decorative shape
                Positioned(
                  top: -20,
                  right: -20,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.15),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(FitoraSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Hero(
                        tag: 'workout_title_${workout.id}',
                        child: Material(
                          color: Colors.transparent,
                          child: Text(
                            workout.title,
                            maxLines: compact ? 1 : 2,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        workout.subtitle,
                        maxLines: compact ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: Colors.white60,
                        ),
                      ),
                      SizedBox(height: spacing + 8),
                      WorkoutMetricsRow(
                        workout: workout,
                        accentColor: FitoraColors.mintGreen,
                      ),
                      if (workout.tags.isNotEmpty) ...[
                        SizedBox(height: spacing + 8),
                        Wrap(
                          spacing: FitoraSpacing.xs,
                          runSpacing: FitoraSpacing.xs,
                          children: workout.tags
                              .take(tagLimit)
                              .map((tag) => WorkoutTagChip(label: _titleCase(tag)))
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
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
