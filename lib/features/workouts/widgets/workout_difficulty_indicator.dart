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
    int level;
    switch (difficulty) {
      case WorkoutDifficulty.beginner:
        level = 1;
        break;
      case WorkoutDifficulty.intermediate:
        level = 2;
        break;
      case WorkoutDifficulty.advanced:
        level = 3;
        break;
    }

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
