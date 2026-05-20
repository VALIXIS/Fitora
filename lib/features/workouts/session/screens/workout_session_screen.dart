import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:fitora/core/constants/spacing.dart';
import 'package:fitora/core/responsive/responsive_builder.dart';
import 'package:fitora/features/progress/providers/progress_controller.dart';
import 'package:fitora/features/workouts/domain/workout_models.dart';
import 'package:fitora/features/workouts/providers/workout_providers.dart';
import 'package:fitora/features/workouts/session/domain/workout_session_models.dart';
import 'package:fitora/features/workouts/session/providers/workout_session_controller.dart';
import 'package:fitora/features/workouts/session/widgets/workout_session_controls.dart';
import 'package:fitora/features/workouts/session/widgets/workout_session_exercise_card.dart';
import 'package:fitora/features/workouts/session/widgets/workout_session_stats_grid.dart';
import 'package:fitora/features/workouts/widgets/workout_metrics_row.dart';
import 'package:fitora/shared/widgets/empty_state_widget.dart';
import 'package:fitora/shared/widgets/fitora_card.dart';
import 'package:fitora/shared/widgets/loading_widget.dart';

// ── Root screen ───────────────────────────────────────────────────────────────

class WorkoutSessionScreen extends ConsumerWidget {
  final String workoutId;

  const WorkoutSessionScreen({super.key, required this.workoutId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutAsync = ref.watch(workoutByIdProvider(workoutId));

    return workoutAsync.when(
      loading: () => const Scaffold(
        body: SafeArea(child: LoadingWidget(message: 'Preparing session…')),
      ),
      error: (e, _) => const Scaffold(
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

// ── Session content shell ─────────────────────────────────────────────────────

class _WorkoutSessionContent extends ConsumerWidget {
  final Workout workout;

  const _WorkoutSessionContent({required this.workout});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller =
        ref.read(workoutSessionControllerProvider(workout).notifier);
    final status = ref.watch(
      workoutSessionControllerProvider(workout).select((s) => s.status),
    );
    final isEnded = status == WorkoutSessionStatus.ended;

    void handleEnd() {
      controller.endSession();
      // Don't pop — let the user see the completion screen.
    }

    return Scaffold(
      // Hide AppBar on completion to give full celebration focus
      appBar: isEnded
          ? null
          : AppBar(
              title: Text(
                workout.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  controller.endSession();
                  context.pop();
                },
              ),
              automaticallyImplyLeading: false,
            ),
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            const _SessionBackground(),
            ResponsiveBuilder(
              mobile: (_) => _SessionLayout(
                workout: workout,
                maxWidth: 560,
                onBack: controller.previousExercise,
                onNext: controller.nextExercise,
                onPause: controller.pauseSession,
                onResume: controller.resumeSession,
                onEnd: handleEnd,
                onSkipRest: controller.skipRest,
              ),
              tablet: (_) => _SessionLayout(
                workout: workout,
                maxWidth: 820,
                onBack: controller.previousExercise,
                onNext: controller.nextExercise,
                onPause: controller.pauseSession,
                onResume: controller.resumeSession,
                onEnd: handleEnd,
                onSkipRest: controller.skipRest,
              ),
              desktop: (_) => _SessionLayout(
                workout: workout,
                maxWidth: 1040,
                onBack: controller.previousExercise,
                onNext: controller.nextExercise,
                onPause: controller.pauseSession,
                onResume: controller.resumeSession,
                onEnd: handleEnd,
                onSkipRest: controller.skipRest,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Layout ────────────────────────────────────────────────────────────────────

class _SessionLayout extends StatelessWidget {
  final Workout workout;
  final double maxWidth;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onEnd;
  final VoidCallback? onSkipRest;

  const _SessionLayout({
    required this.workout,
    required this.maxWidth,
    required this.onBack,
    required this.onNext,
    required this.onPause,
    required this.onResume,
    required this.onEnd,
    this.onSkipRest,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: SingleChildScrollView(
          padding: FitoraSpacing.pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Status bar ────────────────────────────────────────────
              Consumer(builder: (context, ref, _) {
                final status = ref.watch(workoutSessionControllerProvider(workout)
                    .select((s) => s.status));
                if (status == WorkoutSessionStatus.ended) {
                  return const SizedBox.shrink();
                }
                final elapsed = ref.watch(workoutSessionControllerProvider(workout)
                    .select((s) => s.totalElapsedLabel));
                final completed = ref.watch(workoutSessionControllerProvider(workout)
                    .select((s) => s.completedExercises));
                final total = ref.watch(workoutSessionControllerProvider(workout)
                    .select((s) => s.totalExercises));
                final isPaused = ref.watch(workoutSessionControllerProvider(workout)
                    .select((s) => s.isPaused));
                return _TopBar(
                  elapsedLabel: elapsed,
                  completed: completed,
                  total: total,
                  isPaused: isPaused,
                );
              }),

              // ── Center card (exercise / rest / completion) ─────────────
              Consumer(builder: (context, ref, _) {
                final status = ref.watch(workoutSessionControllerProvider(workout)
                    .select((s) => s.status));
                final isResting = ref.watch(workoutSessionControllerProvider(workout)
                    .select((s) => s.isResting));

                if (status == WorkoutSessionStatus.ended) {
                  return _CompletionScreen(workout: workout)
                      .animate()
                      .fadeIn(duration: 600.ms)
                      .scale(
                        begin: const Offset(0.92, 0.92),
                        end: const Offset(1, 1),
                        duration: 500.ms,
                        curve: Curves.easeOutBack,
                      );
                }

                if (isResting) {
                  return Column(children: [
                    const SizedBox(height: FitoraSpacing.lg),
                    _RestCard(workout: workout),
                  ]);
                }

                final exercise = ref.watch(workoutSessionControllerProvider(workout)
                    .select((s) => s.currentExercise));
                final remaining = ref.watch(workoutSessionControllerProvider(workout)
                    .select((s) => s.currentRemainingSeconds));

                return Column(children: [
                  const SizedBox(height: FitoraSpacing.lg),
                  WorkoutSessionExerciseCard(exercise: exercise),
                  const SizedBox(height: FitoraSpacing.md),
                  Center(
                    child: _TimerRing(
                      remainingSeconds: remaining,
                      totalSeconds: exercise.dose.duration?.inSeconds,
                    ),
                  ),
                  const SizedBox(height: FitoraSpacing.md),
                  WorkoutSessionStatsGrid(dose: exercise.dose),
                ]);
              }),

              // ── Overview + controls (hide on completion) ──────────────
              Consumer(builder: (context, ref, _) {
                final status = ref.watch(workoutSessionControllerProvider(workout)
                    .select((s) => s.status));
                if (status == WorkoutSessionStatus.ended) {
                  return const SizedBox.shrink();
                }
                return Column(children: [
                  const SizedBox(height: FitoraSpacing.lg),
                  _OverviewCard(workout: workout),
                  const SizedBox(height: FitoraSpacing.md),
                  Consumer(builder: (context, ref, _) {
                    final canGoBack = ref.watch(workoutSessionControllerProvider(workout)
                        .select((s) => s.hasPrevious));
                    final canGoNext = ref.watch(workoutSessionControllerProvider(workout)
                        .select((s) => s.hasNext));
                    final isPaused = ref.watch(workoutSessionControllerProvider(workout)
                        .select((s) => s.isPaused));
                    final isResting = ref.watch(workoutSessionControllerProvider(workout)
                        .select((s) => s.isResting));
                    return FitoraCard(
                      child: WorkoutSessionControls(
                        canGoBack: canGoBack,
                        canGoNext: canGoNext,
                        isPaused: isPaused,
                        isResting: isResting,
                        onBack: onBack,
                        onNext: onNext,
                        onPause: onPause,
                        onResume: onResume,
                        onEnd: onEnd,
                        onSkipRest: onSkipRest,
                      ),
                    );
                  }),
                  const SizedBox(height: FitoraSpacing.xl),
                ]);
              }),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Top bar ───────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final String elapsedLabel;
  final int completed;
  final int total;
  final bool isPaused;

  const _TopBar({
    required this.elapsedLabel,
    required this.completed,
    required this.total,
    required this.isPaused,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final progress = total == 0 ? 0.0 : completed / total;

    return FitoraCard(
      child: Column(
        children: [
          Row(
            children: [
              // Elapsed
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Elapsed', style: textTheme.labelSmall),
                  const SizedBox(height: 2),
                  Text(elapsedLabel,
                      style: textTheme.titleMedium?.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                      )),
                ],
              ),
              const Spacer(),
              // Exercises count
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: FitoraSpacing.sm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isPaused
                      ? colorScheme.secondaryContainer
                      : colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  isPaused ? 'Paused' : '$completed / $total',
                  style: textTheme.labelMedium?.copyWith(
                    color: isPaused
                        ? colorScheme.onSecondaryContainer
                        : colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: FitoraSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOut,
              builder: (context, v, _) => LinearProgressIndicator(
                value: v,
                minHeight: 4,
                backgroundColor: colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation(colorScheme.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Timer ring ────────────────────────────────────────────────────────────────

class _TimerRing extends StatelessWidget {
  final int? remainingSeconds;
  final int? totalSeconds;

  const _TimerRing({this.remainingSeconds, this.totalSeconds});

  String _fmt(int? s) {
    if (s == null) return '--:--';
    final m = s ~/ 60;
    final sec = s % 60;
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final hasTimer = remainingSeconds != null && totalSeconds != null && totalSeconds! > 0;
    final progress = hasTimer ? 1.0 - (remainingSeconds! / totalSeconds!) : 0.0;

    // Warning color when < 10 seconds remain
    final isUrgent = hasTimer && remainingSeconds! < 10;
    final ringColor = isUrgent ? colorScheme.error : colorScheme.primary;

    return SizedBox(
      width: 110,
      height: 110,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 400),
            builder: (context, v, _) => CircularProgressIndicator(
              value: v,
              strokeWidth: 9,
              backgroundColor: colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(ringColor),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _fmt(remainingSeconds),
                style: textTheme.titleLarge?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: isUrgent ? colorScheme.error : null,
                ),
              ),
              Text(
                hasTimer ? 'remaining' : 'reps',
                style: textTheme.labelSmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Rest card ─────────────────────────────────────────────────────────────────

class _RestCard extends ConsumerWidget {
  final Workout workout;

  const _RestCard({required this.workout});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final restRemaining = ref.watch(
      workoutSessionControllerProvider(workout).select((s) => s.restRemainingSeconds),
    );
    final currentIndex = ref.watch(
      workoutSessionControllerProvider(workout).select((s) => s.currentIndex),
    );
    final totalExercises = ref.watch(
      workoutSessionControllerProvider(workout).select((s) => s.totalExercises),
    );

    final restSeconds = restRemaining ?? 0;
    final nextIndex = currentIndex + 1;
    final preview =
        nextIndex < totalExercises ? workout.exercises[nextIndex] : null;

    return FitoraCard(
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.self_improvement_outlined,
                  color: colorScheme.secondary, size: 20),
              const SizedBox(width: FitoraSpacing.xs),
              Text('Rest', style: textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: FitoraSpacing.lg),

          // Countdown ring
          SizedBox(
            width: 100,
            height: 100,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: 1.0, // full ring as backdrop
                  strokeWidth: 8,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  valueColor:
                      AlwaysStoppedAnimation(colorScheme.secondary.withValues(alpha: 0.25)),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$restSeconds',
                      style: textTheme.headlineMedium?.copyWith(
                        color: colorScheme.secondary,
                        fontWeight: FontWeight.bold,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    Text('sec', style: textTheme.labelSmall),
                  ],
                ),
              ],
            ),
          ),

          if (preview != null) ...[
            const SizedBox(height: FitoraSpacing.lg),
            const Divider(height: 1),
            const SizedBox(height: FitoraSpacing.md),
            Text('Up next', style: textTheme.labelSmall),
            const SizedBox(height: FitoraSpacing.xs),
            Text(
              preview.title,
              style: textTheme.titleSmall,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

// ── Completion screen ─────────────────────────────────────────────────────────

class _CompletionScreen extends ConsumerWidget {
  final Workout workout;

  const _CompletionScreen({required this.workout});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final session = ref.watch(workoutSessionControllerProvider(workout));
    final progressState = ref.watch(progressControllerProvider);
    final streak = progressState.streak;

    final completionRatio = session.totalExercises == 0
        ? 0.0
        : session.completedExercises / session.totalExercises;
    final estimatedCalories = (workout.calories * completionRatio).round();
    final isFullCompletion = completionRatio >= 1.0;

    final motivational = isFullCompletion
        ? 'You crushed it! Every rep counts. 💪'
        : 'Great effort! Progress, not perfection.';

    return Column(
      children: [
        // Hero celebration area
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(FitoraSpacing.xl),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.primaryContainer,
                colorScheme.secondaryContainer,
              ],
            ),
            borderRadius: FitoraSpacing.cardRadius,
          ),
          child: Column(
            children: [
              // Trophy / medal icon
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.35),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Icon(
                  isFullCompletion ? Icons.emoji_events : Icons.check_rounded,
                  color: colorScheme.onPrimary,
                  size: 38,
                ),
              )
                  .animate()
                  .scale(
                    begin: const Offset(0.4, 0.4),
                    end: const Offset(1, 1),
                    delay: 200.ms,
                    duration: 600.ms,
                    curve: Curves.elasticOut,
                  ),
              const SizedBox(height: FitoraSpacing.md),
              Text(
                isFullCompletion ? 'Workout complete!' : 'Session ended',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onPrimaryContainer,
                ),
                textAlign: TextAlign.center,
              )
                  .animate()
                  .fadeIn(delay: 350.ms, duration: 400.ms)
                  .slideY(begin: 0.2, end: 0, duration: 400.ms),
              const SizedBox(height: FitoraSpacing.xs),
              Text(
                motivational,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                ),
                textAlign: TextAlign.center,
              )
                  .animate()
                  .fadeIn(delay: 450.ms, duration: 400.ms),
            ],
          ),
        ),

        const SizedBox(height: FitoraSpacing.lg),

        // Stats card
        FitoraCard(
          child: Column(
            children: [
              _StatRow(
                icon: Icons.timer_outlined,
                label: 'Duration',
                value: session.totalElapsedLabel,
              ),
              const Divider(height: FitoraSpacing.lg),
              _StatRow(
                icon: Icons.fitness_center_outlined,
                label: 'Exercises',
                value:
                    '${session.completedExercises} / ${session.totalExercises}',
              ),
              const Divider(height: FitoraSpacing.lg),
              _StatRow(
                icon: Icons.local_fire_department_outlined,
                label: 'Calories',
                value: '$estimatedCalories kcal',
                accent: true,
                accentColor: colorScheme.tertiary,
              ),
              if (streak.currentStreak > 0) ...[
                const Divider(height: FitoraSpacing.lg),
                _StatRow(
                  icon: Icons.whatshot_outlined,
                  label: 'Streak',
                  value: '${streak.currentStreak} day${streak.currentStreak == 1 ? '' : 's'} 🔥',
                  accent: true,
                  accentColor: colorScheme.secondary,
                ),
              ],
            ],
          ),
        )
            .animate()
            .fadeIn(delay: 300.ms, duration: 400.ms)
            .slideY(begin: 0.1, end: 0, duration: 400.ms),

        const SizedBox(height: FitoraSpacing.lg),

        // Done button
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => context.pop(),
            child: const Text('Done'),
          ),
        )
            .animate()
            .fadeIn(delay: 500.ms, duration: 400.ms)
            .slideY(begin: 0.15, end: 0, duration: 400.ms),

        const SizedBox(height: FitoraSpacing.xl),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool accent;
  final Color? accentColor;

  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
    this.accent = false,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final color = accent ? (accentColor ?? colorScheme.primary) : colorScheme.onSurfaceVariant;

    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: FitoraSpacing.sm),
        Text(
          label,
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: textTheme.titleSmall?.copyWith(
            color: accent ? color : null,
            fontWeight: accent ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ── Overview card ─────────────────────────────────────────────────────────────

class _OverviewCard extends StatelessWidget {
  final Workout workout;

  const _OverviewCard({required this.workout});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return FitoraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Workout overview', style: textTheme.titleSmall),
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
        ],
      ),
    );
  }
}

// ── Background ────────────────────────────────────────────────────────────────

class _SessionBackground extends StatelessWidget {
  const _SessionBackground();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colorScheme.surface,
            colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
          ],
        ),
      ),
    );
  }
}
