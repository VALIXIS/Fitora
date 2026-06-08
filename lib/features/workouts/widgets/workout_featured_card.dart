import 'package:flutter/material.dart';
import 'package:fitora/core/constants/spacing.dart';
import 'package:fitora/features/workouts/domain/workout_models.dart';
import 'package:fitora/features/workouts/widgets/workout_metrics_row.dart';
import 'package:fitora/shared/widgets/glow_container.dart';
import 'package:fitora/core/theme/fitora_colors.dart';

class WorkoutFeaturedCard extends StatelessWidget {
  final Workout workout;
  final VoidCallback onTap;

  const WorkoutFeaturedCard({
    super.key,
    required this.workout,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GlowContainer(
      glowColor: FitoraColors.calmCyan.withValues(alpha: 0.3),
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(28),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Stack(
              children: [
                // Geometric Gradient Background
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF1E3A3A),
                          Color(0xFF0F1A1A),
                          Color(0xFF142426),
                        ],
                      ),
                    ),
                  ),
                ),
                // Decorative Geometric shapes
                Positioned(
                  top: -50,
                  right: -30,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          FitoraColors.mintGreen.withValues(alpha: 0.15),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -80,
                  left: -50,
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          FitoraColors.calmCyan.withValues(alpha: 0.1),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.all(FitoraSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'FEATURED',
                          style: textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: FitoraSpacing.lg),
                      Hero(
                        tag: 'workout_title_${workout.id}',
                        child: Material(
                          color: Colors.transparent,
                          child: Text(
                            workout.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              height: 1.1,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: FitoraSpacing.xs),
                      Text(
                        workout.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyLarge?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: FitoraSpacing.xl),
                      WorkoutMetricsRow(
                        workout: workout,
                        accentColor: FitoraColors.mintGreen,
                      ),
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
