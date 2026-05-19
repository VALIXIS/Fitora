import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:fitora/app/router/app_routes.dart';
import 'package:fitora/core/constants/spacing.dart';
import 'package:fitora/features/personalization/domain/personalization_models.dart';
import 'package:fitora/features/workouts/domain/workout_models.dart';
import 'package:fitora/features/workouts/providers/workout_providers.dart';
import 'package:fitora/features/workouts/widgets/exercise_card.dart';
import 'package:fitora/features/workouts/widgets/workout_metrics_row.dart';
import 'package:fitora/features/workouts/widgets/workout_progress_indicator.dart';
import 'package:fitora/features/workouts/widgets/workout_section_header.dart';
import 'package:fitora/features/workouts/widgets/workout_tag_chip.dart';
import 'package:fitora/shared/widgets/empty_state_widget.dart';
import 'package:fitora/shared/widgets/fitora_button.dart';
import 'package:fitora/shared/widgets/loading_widget.dart';

class WorkoutDetailScreen extends ConsumerWidget {
  final String workoutId;

  const WorkoutDetailScreen({
    super.key,
    required this.workoutId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutAsync = ref.watch(workoutByIdProvider(workoutId));

    return workoutAsync.when(
      loading: () => const Scaffold(
        body: SafeArea(
          child: LoadingWidget(message: 'Loading workout'),
        ),
      ),
      error: (_, __) => const Scaffold(
        body: SafeArea(
          child: EmptyStateWidget(
            icon: Icons.fitness_center_outlined,
            title: 'Workout unavailable',
            message: 'Please try again later.',
          ),
        ),
      ),
      data: (workout) {
        if (workout == null) {
          return const Scaffold(
            body: SafeArea(
              child: EmptyStateWidget(
                icon: Icons.fitness_center_outlined,
                title: 'Workout not found',
                message: 'This workout is no longer available.',
              ),
            ),
          );
        }

        return _WorkoutDetailContent(workout: workout);
      },
    );
  }
}

class _WorkoutDetailContent extends StatelessWidget {
  final Workout workout;

  const _WorkoutDetailContent({required this.workout});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(workout.title),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            const _WorkoutDetailBackground(),
            SingleChildScrollView(
              padding: FitoraSpacing.pagePadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    workout.subtitle,
                    style: textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: FitoraSpacing.md),
                  Wrap(
                    spacing: FitoraSpacing.xs,
                    runSpacing: FitoraSpacing.xs,
                    children: [
                      ...workout.tags
                          .map((tag) => WorkoutTagChip(label: _titleCase(tag)))
                          .toList(),
                      ...workout.recommendedGoals
                          .map((goal) => WorkoutTagChip(label: goal.label))
                          .toList(),
                    ],
                  ),
                  const SizedBox(height: FitoraSpacing.md),
                  WorkoutMetricsRow(
                    workout: workout,
                    accentColor: colorScheme.secondary,
                  ),
                  const SizedBox(height: FitoraSpacing.lg),
                  WorkoutProgressIndicator(
                    completed: 0,
                    total: workout.exerciseCount,
                  ),
                  const SizedBox(height: FitoraSpacing.lg),
                  const WorkoutSectionHeader(
                    title: 'Exercises',
                    subtitle: 'Follow the flow and move at your pace.',
                  ),
                  const SizedBox(height: FitoraSpacing.md),
                  ...workout.exercises.map(
                    (exercise) => Padding(
                      padding: const EdgeInsets.only(bottom: FitoraSpacing.md),
                      child: ExerciseCard(exercise: exercise),
                    ),
                  ),
                  const SizedBox(height: FitoraSpacing.sm),
                  FitoraButton(
                    label: 'Start workout',
                    leading: const Icon(Icons.play_arrow),
                    onPressed: () {
                      context.pushNamed(
                        AppRouteNames.workoutSession,
                        pathParameters: {'id': workout.id},
                      );
                    },
                  ),
                  const SizedBox(height: FitoraSpacing.lg),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkoutDetailBackground extends StatelessWidget {
  const _WorkoutDetailBackground();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colorScheme.background,
            colorScheme.surfaceVariant.withOpacity(0.6),
          ],
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
