import 'package:flutter/material.dart';
import 'package:fitora/core/constants/spacing.dart';
import 'package:fitora/features/workouts/domain/workout_models.dart';

class WorkoutDifficultyIndicator extends StatelessWidget {
  final WorkoutDifficulty difficulty;
  final Color? accentColor;

  const WorkoutDifficultyIndicator({
    super.key,
    required this.difficulty,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final activeColor = accentColor ?? colorScheme.primary;
    final inactiveColor = colorScheme.outlineVariant;
    final level = switch (difficulty) {
      WorkoutDifficulty.beginner => 1,
      WorkoutDifficulty.intermediate => 2,
      WorkoutDifficulty.advanced => 3,
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        final isActive = index < level;
        return Container(
          width: 10,
          height: 10,
          margin: EdgeInsets.only(
            right: index == 2 ? 0 : FitoraSpacing.xs,
          ),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? activeColor : Colors.transparent,
            border: Border.all(color: isActive ? activeColor : inactiveColor),
          ),
        );
      }),
    );
  }
}
