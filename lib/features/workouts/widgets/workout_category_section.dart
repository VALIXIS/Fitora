import 'package:flutter/material.dart';
import 'package:fitora/core/constants/spacing.dart';
import 'package:fitora/features/workouts/domain/workout_models.dart';
import 'package:fitora/features/workouts/widgets/workout_card.dart';
import 'package:fitora/features/workouts/widgets/workout_section_header.dart';

class WorkoutCategorySection extends StatelessWidget {
  final WorkoutCategory category;
  final List<Workout> workouts;
  final ValueChanged<Workout> onWorkoutTap;

  const WorkoutCategorySection({
    super.key,
    required this.category,
    required this.workouts,
    required this.onWorkoutTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 520;
        final textScale = MediaQuery.textScaleFactorOf(context);
        final cardHeight = 176 * (textScale < 1 ? 1 : textScale);

        Widget content;

        if (isNarrow) {
          content = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final workout in workouts) ...[
                WorkoutCard(
                  workout: workout,
                  onTap: () => onWorkoutTap(workout),
                ),
                const SizedBox(height: FitoraSpacing.md),
              ],
            ],
          );
        } else {
          content = SizedBox(
            height: cardHeight.toDouble(),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: workouts.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: FitoraSpacing.md),
              itemBuilder: (context, index) {
                final workout = workouts[index];
                return SizedBox(
                  width: 260,
                  child: WorkoutCard(
                    workout: workout,
                    compact: true,
                    onTap: () => onWorkoutTap(workout),
                  ),
                );
              },
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            WorkoutSectionHeader(
              title: category.label,
              subtitle: category.description,
            ),
            const SizedBox(height: FitoraSpacing.md),
            content,
          ],
        );
      },
    );
  }
}
