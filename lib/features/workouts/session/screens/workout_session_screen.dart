import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:fitora/core/constants/spacing.dart';
import 'package:fitora/core/responsive/responsive_builder.dart';
import 'package:fitora/features/workouts/domain/workout_models.dart';
import 'package:fitora/features/workouts/providers/workout_providers.dart';
import 'package:fitora/features/workouts/session/domain/workout_session_models.dart';
import 'package:fitora/features/workouts/session/providers/workout_session_controller.dart';
import 'package:fitora/features/workouts/session/widgets/workout_session_controls.dart';
import 'package:fitora/features/workouts/session/widgets/workout_session_exercise_card.dart';
import 'package:fitora/features/workouts/widgets/workout_metrics_row.dart';
import 'package:fitora/features/workouts/widgets/workout_progress_indicator.dart';
import 'package:fitora/shared/widgets/empty_state_widget.dart';
import 'package:fitora/shared/widgets/loading_widget.dart';

class WorkoutSessionScreen extends ConsumerWidget {
  final String workoutId;

  const WorkoutSessionScreen({
    super.key,
    required this.workoutId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutAsync = ref.watch(workoutByIdProvider(workoutId));

    return workoutAsync.when(
      loading: () => const Scaffold(
        body: SafeArea(
          child: LoadingWidget(message: 'Preparing session'),
        ),
      ),
      error: (_, __) => const Scaffold(
        body: SafeArea(
          child: EmptyStateWidget(
            icon: Icons.fitness_center_outlined,
            title: 'Unable to start session',
            message: 'Please try again in a moment.',
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

        return _WorkoutSessionContent(workout: workout);
      },
    );
  }
}

class _WorkoutSessionContent extends ConsumerWidget {
  final Workout workout;

  const _WorkoutSessionContent({required this.workout});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(workoutSessionControllerProvider(workout));
    final controller =
        ref.read(workoutSessionControllerProvider(workout).notifier);

    void handleEnd() {
      controller.endSession();
      context.pop();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(workout.title),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            const _WorkoutSessionBackground(),
            ResponsiveBuilder(
              mobile: (_) => _WorkoutSessionLayout(
                workout: workout,
                session: session,
                maxWidth: 560,
                onBack: controller.previousExercise,
                onNext: controller.nextExercise,
                onPause: controller.pauseSession,
                onResume: controller.resumeSession,
                onEnd: handleEnd,
              ),
              tablet: (_) => _WorkoutSessionLayout(
                workout: workout,
                session: session,
                maxWidth: 820,
                onBack: controller.previousExercise,
                onNext: controller.nextExercise,
                onPause: controller.pauseSession,
                onResume: controller.resumeSession,
                onEnd: handleEnd,
              ),
              desktop: (_) => _WorkoutSessionLayout(
                workout: workout,
                session: session,
                maxWidth: 1040,
                onBack: controller.previousExercise,
                onNext: controller.nextExercise,
                onPause: controller.pauseSession,
                onResume: controller.resumeSession,
                onEnd: handleEnd,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkoutSessionLayout extends StatelessWidget {
  final Workout workout;
  final WorkoutSessionState session;
  final double maxWidth;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onEnd;

  const _WorkoutSessionLayout({
    required this.workout,
    required this.session,
    required this.maxWidth,
    required this.onBack,
    required this.onNext,
    required this.onPause,
    required this.onResume,
    required this.onEnd,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: SingleChildScrollView(
          padding: FitoraSpacing.pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Exercise ${session.completedExercises} of ${session.totalExercises}',
                    style: textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  _SessionStatusPill(isPaused: session.isPaused),
                ],
              ),
              const SizedBox(height: FitoraSpacing.sm),
              WorkoutProgressIndicator(
                completed: session.completedExercises,
                total: session.totalExercises,
              ),
              const SizedBox(height: FitoraSpacing.lg),
              WorkoutSessionExerciseCard(exercise: session.currentExercise),
              const SizedBox(height: FitoraSpacing.lg),
              Text('Workout overview', style: textTheme.titleMedium),
              const SizedBox(height: FitoraSpacing.xs),
              Text(
                workout.subtitle,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: FitoraSpacing.sm),
              WorkoutMetricsRow(
                workout: workout,
                accentColor: colorScheme.secondary,
              ),
              const SizedBox(height: FitoraSpacing.lg),
              WorkoutSessionControls(
                canGoBack: session.hasPrevious,
                canGoNext: session.hasNext,
                isPaused: session.isPaused,
                onBack: onBack,
                onNext: onNext,
                onPause: onPause,
                onResume: onResume,
                onEnd: onEnd,
              ),
              const SizedBox(height: FitoraSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionStatusPill extends StatelessWidget {
  final bool isPaused;

  const _SessionStatusPill({required this.isPaused});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final background = isPaused
        ? colorScheme.secondaryContainer
        : colorScheme.surfaceVariant;
    final label = isPaused ? 'Paused' : 'Active';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: FitoraSpacing.sm,
        vertical: FitoraSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: background,
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

class _WorkoutSessionBackground extends StatelessWidget {
  const _WorkoutSessionBackground();

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
            colorScheme.surfaceVariant.withOpacity(0.55),
          ],
        ),
      ),
    );
  }
}
