import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:fitora/core/theme/fitora_colors.dart';
import 'package:fitora/core/theme/fitora_gradients.dart';
import 'package:fitora/core/responsive/responsive_builder.dart';
import 'package:fitora/features/progress/providers/progress_controller.dart';
import 'package:fitora/features/personalization/providers/personalization_controller.dart';
import 'package:fitora/features/workouts/domain/workout_models.dart';
import 'package:fitora/features/workouts/widgets/exercise_media.dart';
import 'package:fitora/features/workouts/providers/workout_providers.dart';
import 'package:fitora/features/workouts/session/domain/workout_session_models.dart';
import 'package:fitora/features/workouts/session/providers/workout_session_controller.dart';
import 'package:fitora/shared/widgets/empty_state_widget.dart';
import 'package:fitora/shared/widgets/loading_widget.dart';

// ── Root Screen ───────────────────────────────────────────────────────────────

class WorkoutSessionScreen extends ConsumerWidget {
  final String workoutId;

  const WorkoutSessionScreen({super.key, required this.workoutId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutAsync = ref.watch(workoutByIdProvider(workoutId));

    return workoutAsync.when(
      loading: () => const Scaffold(
        backgroundColor: FitoraColors.darkBg,
        body: SafeArea(child: LoadingWidget(message: 'Preparing session…')),
      ),
      error: (e, _) => const Scaffold(
        backgroundColor: FitoraColors.darkBg,
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
            backgroundColor: FitoraColors.darkBg,
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

// ── Session Content Shell ─────────────────────────────────────────────────────

class _WorkoutSessionContent extends ConsumerStatefulWidget {
  final Workout workout;

  const _WorkoutSessionContent({required this.workout});

  @override
  ConsumerState<_WorkoutSessionContent> createState() => _WorkoutSessionContentState();
}

class _WorkoutSessionContentState extends ConsumerState<_WorkoutSessionContent> {
  bool _isImmersiveMode = false;

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(workoutSessionControllerProvider(widget.workout).notifier);
    final sessionState = ref.watch(workoutSessionControllerProvider(widget.workout));
    final isEnded = sessionState.status == WorkoutSessionStatus.ended;

    // Precise audio cues and haptic feedback
    ref.listen<WorkoutSessionState>(
      workoutSessionControllerProvider(widget.workout),
      (previous, next) {
        final prevSec = previous?.currentRemainingSeconds;
        final nextSec = next.currentRemainingSeconds;
        final prevRest = previous?.restRemainingSeconds;
        final nextRest = next.restRemainingSeconds;

        if (nextSec != null && nextSec != prevSec) {
          if (nextSec <= 3 && nextSec > 0) {
            SystemSound.play(SystemSoundType.click);
            HapticFeedback.mediumImpact();
          } else if (nextSec <= 5) {
            HapticFeedback.lightImpact();
          }
        }

        if (nextRest != null && nextRest != prevRest) {
          if (nextRest <= 3 && nextRest > 0) {
            SystemSound.play(SystemSoundType.click);
            HapticFeedback.mediumImpact();
          } else if (nextRest <= 5) {
            HapticFeedback.lightImpact();
          }
        }

        if (next.isResting != previous?.isResting || next.currentIndex != previous?.currentIndex) {
          HapticFeedback.heavyImpact();
          SystemSound.play(SystemSoundType.click);
          Future.delayed(const Duration(milliseconds: 120), () {
            SystemSound.play(SystemSoundType.click);
          });
        }
      },
    );

    return Scaffold(
      backgroundColor: FitoraColors.darkBg,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            const _SessionBackground(),
            if (isEnded)
              SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                child: _CompletionScreen(workout: widget.workout)
                    .animate()
                    .fadeIn(duration: 600.ms)
                    .scale(
                      begin: const Offset(0.95, 0.95),
                      end: const Offset(1, 1),
                      duration: 500.ms,
                      curve: Curves.easeOutBack,
                    ),
              )
            else if (_isImmersiveMode)
              _ImmersiveCoachingView(
                workout: widget.workout,
                session: sessionState,
                onExit: () => setState(() => _isImmersiveMode = false),
                onBack: controller.previousExercise,
                onNext: controller.nextExercise,
                onPause: controller.pauseSession,
                onResume: controller.resumeSession,
                onSkipRest: controller.skipRest,
              )
            else
              ResponsiveBuilder(
                mobile: (_) => _SessionLayout(
                  workout: widget.workout,
                  sessionState: sessionState,
                  maxWidth: 500,
                  onBack: controller.previousExercise,
                  onNext: controller.nextExercise,
                  onPause: controller.pauseSession,
                  onResume: controller.resumeSession,
                  onEnd: controller.endSession,
                  onSkipRest: controller.skipRest,
                  onToggleImmersive: () => setState(() => _isImmersiveMode = true),
                ),
                tablet: (_) => _SessionLayout(
                  workout: widget.workout,
                  sessionState: sessionState,
                  maxWidth: 720,
                  onBack: controller.previousExercise,
                  onNext: controller.nextExercise,
                  onPause: controller.pauseSession,
                  onResume: controller.resumeSession,
                  onEnd: controller.endSession,
                  onSkipRest: controller.skipRest,
                  onToggleImmersive: () => setState(() => _isImmersiveMode = true),
                ),
                desktop: (_) => _SessionLayout(
                  workout: widget.workout,
                  sessionState: sessionState,
                  maxWidth: 880,
                  onBack: controller.previousExercise,
                  onNext: controller.nextExercise,
                  onPause: controller.pauseSession,
                  onResume: controller.resumeSession,
                  onEnd: controller.endSession,
                  onSkipRest: controller.skipRest,
                  onToggleImmersive: () => setState(() => _isImmersiveMode = true),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Standard Session Layout (Redesigned & Minimal) ────────────────────────────

class _SessionLayout extends StatelessWidget {
  final Workout workout;
  final WorkoutSessionState sessionState;
  final double maxWidth;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onEnd;
  final VoidCallback? onSkipRest;
  final VoidCallback onToggleImmersive;

  const _SessionLayout({
    required this.workout,
    required this.sessionState,
    required this.maxWidth,
    required this.onBack,
    required this.onNext,
    required this.onPause,
    required this.onResume,
    required this.onEnd,
    this.onSkipRest,
    required this.onToggleImmersive,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isResting = sessionState.isResting;
    final progress = sessionState.progress;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header & Overall Progress Indicator ─────────────────────────
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ELAPSED TIME',
                        style: textTheme.labelSmall?.copyWith(
                          color: FitoraColors.darkTextSecondary.withOpacity(0.5),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        sessionState.totalElapsedLabel,
                        style: textTheme.titleLarge?.copyWith(
                          color: FitoraColors.darkTextPrimary,
                          fontWeight: FontWeight.bold,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Immersive Toggle button
                  IconButton(
                    icon: const Icon(Icons.fullscreen_rounded, color: FitoraColors.mintGreen, size: 28),
                    tooltip: 'Guided Immersive Mode',
                    onPressed: onToggleImmersive,
                  ),
                  const SizedBox(width: 8),
                  // Sleek exit button
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: FitoraColors.darkTextSecondary, size: 26),
                    onPressed: onEnd,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              
              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: progress),
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOut,
                  builder: (context, v, _) => LinearProgressIndicator(
                    value: v,
                    minHeight: 4,
                    backgroundColor: FitoraColors.darkBorder,
                    valueColor: const AlwaysStoppedAnimation(FitoraColors.mintGreen),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Main Exercise / Rest Content Area ──────────────────────────
              Expanded(
                child: isResting
                    ? _buildRestContent(context)
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.05, end: 0, duration: 400.ms)
                    : _buildWorkoutContent(context)
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.05, end: 0, duration: 400.ms),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Rest Phase UI
  Widget _buildRestContent(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final restSeconds = sessionState.restRemainingSeconds ?? 0;
    final totalRest = sessionState.currentExercise.dose.rest?.inSeconds ?? 30;
    final progress = totalRest > 0 ? (restSeconds / totalRest).clamp(0.0, 1.0) : 1.0;

    final nextIndex = sessionState.currentIndex + 1;
    final hasNext = nextIndex < sessionState.totalExercises;
    final nextExercise = hasNext ? workout.exercises[nextIndex] : null;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'REST PERIOD',
          style: textTheme.labelMedium?.copyWith(
            color: FitoraColors.lavender,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 16),
        
        // Large elegant countdown timer
        SizedBox(
          width: 140,
          height: 140,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: progress,
                strokeWidth: 8,
                backgroundColor: FitoraColors.darkBorder,
                valueColor: const AlwaysStoppedAnimation(FitoraColors.lavender),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$restSeconds',
                    style: textTheme.displayMedium?.copyWith(
                      color: FitoraColors.darkTextPrimary,
                      fontWeight: FontWeight.bold,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  Text(
                    'seconds',
                    style: textTheme.labelSmall?.copyWith(color: FitoraColors.darkTextSecondary),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Spacer(),

        // Next Exercise Preview Card (minimal, clean)
        if (nextExercise != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: FitoraColors.darkSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: FitoraColors.darkBorder),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 72,
                    height: 72,
                    child: ExerciseMedia(
                      gifPath: nextExercise.gifPath,
                      targetMuscle: nextExercise.targetMuscle,
                      height: 72,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'UP NEXT',
                        style: textTheme.labelSmall?.copyWith(
                          color: FitoraColors.lavender,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        nextExercise.title,
                        style: textTheme.titleMedium?.copyWith(
                          color: FitoraColors.darkTextPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        nextExercise.dose.summary,
                        style: textTheme.bodySmall?.copyWith(color: FitoraColors.darkTextSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
        ],

        // Rest controls
        _buildControlsDock(context, isResting: true),
      ],
    );
  }

  // Work Phase UI
  Widget _buildWorkoutContent(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final exercise = sessionState.currentExercise;
    final remaining = sessionState.currentRemainingSeconds;
    final total = exercise.dose.duration?.inSeconds ?? 30;
    
    final hasTimer = remaining != null;
    final progress = hasTimer && total > 0 ? (1.0 - (remaining / total)).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Exercise Name & Coaching Cue (Top of block)
        Center(
          child: Column(
            children: [
              Text(
                exercise.title.toUpperCase(),
                style: textTheme.headlineMedium?.copyWith(
                  color: FitoraColors.darkTextPrimary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              if (exercise.instructions.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  exercise.instructions.first,
                  style: textTheme.bodyMedium?.copyWith(
                    color: FitoraColors.darkTextSecondary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Large Animated Exercise Visual
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: FitoraColors.darkSurface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: FitoraColors.darkBorder, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: FitoraColors.mintGreen.withOpacity(0.04),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: ExerciseMedia(
                gifPath: exercise.gifPath,
                targetMuscle: exercise.targetMuscle,
                height: double.infinity,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Combined Timer and Media Controls Row (Apple Fitness Inspired)
        _buildBottomInteractiveDock(context, hasTimer, remaining, progress),
      ],
    );
  }

  // Bottom interactive row combining digital timer and media controls
  Widget _buildBottomInteractiveDock(BuildContext context, bool hasTimer, int? remaining, double progress) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: FitoraColors.darkSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: FitoraColors.darkBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Timer Widget
          Row(
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: hasTimer ? progress : 0.0,
                      strokeWidth: 4.5,
                      backgroundColor: FitoraColors.darkBorder,
                      valueColor: const AlwaysStoppedAnimation(FitoraColors.mintGreen),
                    ),
                    Icon(
                      hasTimer ? Icons.timer_outlined : Icons.repeat_rounded,
                      size: 20,
                      color: FitoraColors.mintGreen,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    hasTimer ? '${remaining}s' : 'Reps',
                    style: textTheme.titleLarge?.copyWith(
                      color: FitoraColors.darkTextPrimary,
                      fontWeight: FontWeight.bold,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  Text(
                    hasTimer ? 'remaining' : sessionState.currentExercise.dose.summary,
                    style: textTheme.labelSmall?.copyWith(color: FitoraColors.darkTextSecondary),
                  ),
                ],
              ),
            ],
          ),

          // Action Controls
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.skip_previous_rounded, size: 28),
                color: FitoraColors.darkTextPrimary,
                disabledColor: FitoraColors.darkBorder,
                onPressed: sessionState.hasPrevious ? onBack : null,
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: sessionState.isPaused ? onResume : onPause,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: FitoraColors.mintGreen,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: FitoraColors.mintGreen,
                        blurRadius: 12,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    sessionState.isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.skip_next_rounded, size: 28),
                color: FitoraColors.darkTextPrimary,
                disabledColor: FitoraColors.darkBorder,
                onPressed: sessionState.hasNext ? onNext : onEnd,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Classic rest control dock
  Widget _buildControlsDock(BuildContext context, {required bool isResting}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: FitoraColors.darkSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: FitoraColors.darkBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: const Icon(Icons.skip_previous_rounded, size: 28),
            color: FitoraColors.darkTextPrimary,
            disabledColor: FitoraColors.darkBorder,
            onPressed: sessionState.hasPrevious ? onBack : null,
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: sessionState.isPaused ? onResume : onPause,
            child: Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: FitoraColors.lavender,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: FitoraColors.lavender,
                    blurRadius: 12,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                sessionState.isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
          const SizedBox(width: 12),
          if (isResting && onSkipRest != null)
            TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: FitoraColors.lavender,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              icon: const Icon(Icons.flash_on_rounded, size: 18),
              label: const Text('Skip Rest', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: onSkipRest,
            )
          else
            IconButton(
              icon: const Icon(Icons.skip_next_rounded, size: 28),
              color: FitoraColors.darkTextPrimary,
              disabledColor: FitoraColors.darkBorder,
              onPressed: sessionState.hasNext ? onNext : onEnd,
            ),
        ],
      ),
    );
  }
}

// ── Immersive Coaching Full Screen Mode UI ───────────────────────────────────

class _ImmersiveCoachingView extends StatefulWidget {
  final Workout workout;
  final WorkoutSessionState session;
  final VoidCallback onExit;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onSkipRest;

  const _ImmersiveCoachingView({
    required this.workout,
    required this.session,
    required this.onExit,
    required this.onBack,
    required this.onNext,
    required this.onPause,
    required this.onResume,
    required this.onSkipRest,
  });

  @override
  State<_ImmersiveCoachingView> createState() => _ImmersiveCoachingViewState();
}

class _ImmersiveCoachingViewState extends State<_ImmersiveCoachingView> with SingleTickerProviderStateMixin {
  late final AnimationController _breathController;
  late final Animation<double> _breathAnimation;

  @override
  void initState() {
    super.initState();
    // 5-second complete slow breath cycle (inhale 2.5s, exhale 2.5s)
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);

    _breathAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(
        parent: _breathController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _breathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final exercise = widget.session.currentExercise;
    final isResting = widget.session.isResting;
    final glowColor = isResting ? FitoraColors.lavender : FitoraColors.mintGreen;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity == null) return;
        // Swipe left -> next, Swipe right -> previous
        if (details.primaryVelocity! < -300) {
          if (widget.session.hasNext) {
            widget.onNext();
          }
        } else if (details.primaryVelocity! > 300) {
          if (widget.session.hasPrevious) {
            widget.onBack();
          }
        }
      },
      child: Container(
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Immersive Dark Background with Breathing Pulse Glow ──
            AnimatedBuilder(
              animation: _breathAnimation,
              builder: (context, _) {
                final scale = _breathAnimation.value;
                return Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 1.3 * scale,
                      colors: [
                        glowColor.withValues(alpha: 0.12 * scale),
                        const Color(0xFF040606),
                        Colors.black,
                      ],
                      stops: const [0.0, 0.7, 1.0],
                    ),
                  ),
                );
              },
            ),

            // ── Prioritized Exercise Demonstration (Primary Hero Focus) ──
            if (!isResting)
              Positioned.fill(
                top: 80,
                bottom: 210, // Generous spacing for coaching overlay & dock
                left: 20,
                right: 20,
                child: Center(
                  child: AnimatedBuilder(
                    animation: _breathAnimation,
                    builder: (context, child) {
                      final scale = _breathAnimation.value;
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: glowColor.withValues(alpha: 0.08 * scale),
                              blurRadius: 40 * scale,
                              spreadRadius: 2 * scale,
                            ),
                          ],
                        ),
                        child: child,
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: ExerciseMedia(
                        gifPath: exercise.gifPath,
                        targetMuscle: exercise.targetMuscle,
                        height: double.infinity,
                      ),
                    ),
                  ),
                ),
              )
            else
              // Rest content layout
              Positioned.fill(
                child: _buildImmersiveRest(context),
              ),

            // ── Bottom Dark Scrim for Readability ──────────────────────────────
            if (!isResting)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 260,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.7),
                        Colors.black,
                      ],
                    ),
                  ),
                ),
              ),

            // ── Floating Exit Button (Top Left) ────────────────────────────────
            Positioned(
              top: 20,
              left: 20,
              child: ClipOval(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    color: Colors.white.withValues(alpha: 0.1),
                    child: IconButton(
                      icon: const Icon(Icons.fullscreen_exit_rounded, color: Colors.white, size: 28),
                      onPressed: widget.onExit,
                    ),
                  ),
                ),
              ),
            ),

            // ── Floating Timer Widget (Top Right - Subtle Overlay) ────────────
            if (!isResting)
              Positioned(
                top: 20,
                right: 20,
                child: _buildImmersiveFloatingTimer(context),
              ),

            // ── Bottom Immersive Overlay (Title, Minimal Coaching Text & Controls) ──
            if (!isResting)
              Positioned(
                left: 24,
                right: 24,
                bottom: 24,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Progress Indicator
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: widget.session.progress,
                        minHeight: 3.0,
                        backgroundColor: Colors.white12,
                        valueColor: AlwaysStoppedAnimation(glowColor),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Centered Exercise Name
                    Text(
                      exercise.title.toUpperCase(),
                      style: textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),

                    // Minimal Coaching Text
                    if (exercise.instructions.isNotEmpty)
                      Text(
                        exercise.instructions.first,
                        style: textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 20),

                    // Translucent Glass Controls Bar
                    _buildImmersiveControlsDock(context, isResting: false),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Floating glassy timer overlay for full screen mode
  Widget _buildImmersiveFloatingTimer(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final remaining = widget.session.currentRemainingSeconds;
    final total = widget.session.currentExercise.dose.duration?.inSeconds ?? 30;
    final hasTimer = remaining != null;
    final progress = hasTimer && total > 0 ? (remaining / total).clamp(0.0, 1.0) : 0.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  value: hasTimer ? progress : 0.0,
                  strokeWidth: 2.5,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation(FitoraColors.mintGreen),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                hasTimer ? '${remaining}s' : 'Reps',
                style: textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Custom Full Screen Rest layout
  Widget _buildImmersiveRest(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final restSeconds = widget.session.restRemainingSeconds ?? 0;
    final nextIndex = widget.session.currentIndex + 1;
    final hasNext = nextIndex < widget.session.totalExercises;
    final nextExercise = hasNext ? widget.workout.exercises[nextIndex] : null;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            Text(
              'REST PERIOD',
              style: textTheme.labelLarge?.copyWith(
                color: FitoraColors.lavender,
                fontWeight: FontWeight.bold,
                letterSpacing: 3.0,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '$restSeconds',
              style: textTheme.displayLarge?.copyWith(
                color: Colors.white,
                fontSize: 88,
                fontWeight: FontWeight.bold,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ).animate().scale(duration: 300.ms, curve: Curves.bounceOut),
            Text(
              'seconds left',
              style: textTheme.bodyLarge?.copyWith(color: Colors.white60),
            ),
            const Spacer(),

            // Next Up glassmorphic preview during rest
            if (nextExercise != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            width: 64,
                            height: 64,
                            child: ExerciseMedia(
                              gifPath: nextExercise.gifPath,
                              targetMuscle: nextExercise.targetMuscle,
                              height: 64,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'COMING UP NEXT',
                                style: TextStyle(
                                  color: FitoraColors.lavender,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                nextExercise.title,
                                style: textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                nextExercise.dose.summary,
                                style: const TextStyle(color: Colors.white54, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Spacer(),
            ],

            // Translucent glass controls dock
            _buildImmersiveControlsDock(context, isResting: true),
          ],
        ),
      ),
    );
  }

  // Shared glassmorphic controls deck for immersive mode
  Widget _buildImmersiveControlsDock(BuildContext context, {required bool isResting}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(Icons.skip_previous_rounded, size: 28, color: Colors.white),
                onPressed: widget.session.hasPrevious ? widget.onBack : null,
              ),
              GestureDetector(
                onTap: widget.session.isPaused ? widget.onResume : widget.onPause,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: isResting ? FitoraColors.lavender : FitoraColors.mintGreen,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.session.isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                    color: Colors.black,
                    size: 30,
                  ),
                ),
              ),
              if (isResting)
                TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: FitoraColors.lavender),
                  icon: const Icon(Icons.flash_on_rounded, size: 16),
                  label: const Text('Skip', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: widget.onSkipRest,
                )
              else
                IconButton(
                  icon: const Icon(Icons.skip_next_rounded, size: 28, color: Colors.white),
                  onPressed: widget.session.hasNext ? widget.onNext : widget.onPause,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Completion Screen (Calm & Elegant Glassmorphic) ──────────────────────────

class _CompletionScreen extends ConsumerWidget {
  final Workout workout;

  const _CompletionScreen({required this.workout});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;

    final session = ref.watch(workoutSessionControllerProvider(workout));
    final progressState = ref.watch(progressControllerProvider);
    final streak = progressState.streak;

    // Fetch Personalized weight metrics for dynamic calories formulas
    final profile = ref.watch(personalizationControllerProvider.select((state) => state.profile));
    final userWeight = profile.weightKg ?? 70.0;

    // MET calculations based on category
    double met = 6.0;
    if (workout.category == WorkoutCategory.wellness) met = 3.5;
    if (workout.category == WorkoutCategory.gym) met = 7.5;

    final completionRatio = session.totalExercises == 0 ? 0.0 : session.completedExercises / session.totalExercises;

    // Calories: hours * MET * weightKg * 1.05
    final activeHours = session.totalElapsedSeconds / 3600.0;
    final estimatedCalories = (activeHours * met * userWeight * 1.05).round();
    
    final isFullCompletion = completionRatio >= 1.0;
    final motivational = isFullCompletion ? 'You crushed it! Every rep counts. 💪' : 'Great effort! Progress, not perfection.';

    return Column(
      children: [
        // Trophy celebration header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32.0),
          decoration: BoxDecoration(
            gradient: FitoraGradients.calm,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: FitoraColors.mintGreen.withOpacity(0.2),
                blurRadius: 30,
                spreadRadius: 2,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
                ),
                child: const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 34),
              ).animate().scale(delay: 200.ms, duration: 600.ms, curve: Curves.elasticOut),
              const SizedBox(height: 16),
              Text(
                isFullCompletion ? 'Workout Complete!' : 'Session Ended',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                motivational,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Statistics Summary
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: FitoraColors.darkSurface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: FitoraColors.darkBorder),
          ),
          child: Column(
            children: [
              _StatRow(
                icon: Icons.timer_outlined,
                label: 'Duration',
                value: session.totalElapsedLabel,
              ),
              const Divider(height: 24, color: FitoraColors.darkBorder),
              _StatRow(
                icon: Icons.fitness_center_outlined,
                label: 'Exercises',
                value: '${session.completedExercises} / ${session.totalExercises}',
              ),
              const Divider(height: 24, color: FitoraColors.darkBorder),
              _StatRow(
                icon: Icons.local_fire_department_outlined,
                label: 'Est. Cal Burn',
                value: '$estimatedCalories kcal',
                accentColor: FitoraColors.mintGreen,
              ),
              if (streak.currentStreak > 0) ...[
                const Divider(height: 24, color: FitoraColors.darkBorder),
                _StatRow(
                  icon: Icons.whatshot_outlined,
                  label: 'Streak',
                  value: '${streak.currentStreak} day${streak.currentStreak == 1 ? '' : 's'} 🔥',
                  accentColor: FitoraColors.lavender,
                ),
              ],
            ],
          ),
        ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
        const SizedBox(height: 32),

        // Complete Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: FitoraColors.mintGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 4,
            ),
            onPressed: () => context.pop(),
            child: const Text('Return to Home', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ).animate().fadeIn(delay: 450.ms, duration: 400.ms),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? accentColor;

  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Icon(icon, size: 20, color: accentColor ?? FitoraColors.darkTextSecondary),
        const SizedBox(width: 12),
        Text(
          label,
          style: textTheme.bodyMedium?.copyWith(color: FitoraColors.darkTextSecondary),
        ),
        const Spacer(),
        Text(
          value,
          style: textTheme.titleSmall?.copyWith(
            color: accentColor ?? FitoraColors.darkTextPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// ── Gradient Session Background ───────────────────────────────────────────────

class _SessionBackground extends StatelessWidget {
  const _SessionBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            FitoraColors.darkBg,
            Color(0xFF070B0B),
          ],
        ),
      ),
    );
  }
}
