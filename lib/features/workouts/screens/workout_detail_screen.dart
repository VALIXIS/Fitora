import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:fitora/app/router/app_routes.dart';
import 'package:fitora/core/constants/spacing.dart';
import 'package:fitora/core/theme/fitora_colors.dart';
import 'package:fitora/features/personalization/domain/personalization_models.dart';
import 'package:fitora/features/workouts/domain/workout_models.dart';
import 'package:fitora/features/workouts/providers/workout_providers.dart';
import 'package:fitora/features/workouts/widgets/exercise_card.dart';
import 'package:fitora/features/workouts/widgets/workout_metrics_row.dart';
import 'package:fitora/features/workouts/widgets/workout_progress_indicator.dart';
import 'package:fitora/features/workouts/widgets/workout_section_header.dart';
import 'package:fitora/features/workouts/widgets/workout_tag_chip.dart';
import 'package:fitora/shared/widgets/empty_state_widget.dart';
import 'package:fitora/shared/widgets/loading_widget.dart';
import 'package:fitora/shared/widgets/glow_container.dart';

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
      error: (_, _) => const Scaffold(
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

    return Scaffold(
      backgroundColor: const Color(0xFF0E1312),
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Premium Sliver App Bar with Gradient
              SliverAppBar(
                expandedHeight: 300.0,
                floating: false,
                pinned: true,
                backgroundColor: const Color(0xFF0E1312),
                elevation: 0,
                leading: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: BackButton(color: Colors.white),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  title: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Hero(
                          tag: 'workout_title_${workout.id}',
                          child: Material(
                            color: Colors.transparent,
                            child: Text(
                              workout.title,
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Geometric Background
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0xFF142426),
                              Color(0xFF0F1A1A),
                              Color(0xFF0E1312),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: -50,
                        right: -100,
                        child: Container(
                          width: 300,
                          height: 300,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                FitoraColors.mintGreen.withOpacity(0.15),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -100,
                        left: -50,
                        child: Container(
                          width: 400,
                          height: 400,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                FitoraColors.calmCyan.withOpacity(0.1),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Workout Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: FitoraSpacing.pagePadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        workout.subtitle,
                        style: textTheme.bodyLarge?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: FitoraSpacing.md),
                      Wrap(
                        spacing: FitoraSpacing.xs,
                        runSpacing: FitoraSpacing.xs,
                        children: [
                          ...workout.tags
                              .map((tag) => WorkoutTagChip(label: _titleCase(tag))),
                          ...workout.recommendedGoals
                              .map((goal) => WorkoutTagChip(label: goal.label)),
                        ],
                      ),
                      const SizedBox(height: FitoraSpacing.xl),
                      WorkoutMetricsRow(
                        workout: workout,
                        accentColor: FitoraColors.mintGreen,
                      ),
                      const SizedBox(height: FitoraSpacing.xl),
                      WorkoutProgressIndicator(
                        completed: 0,
                        total: workout.exerciseCount,
                      ),
                      const SizedBox(height: FitoraSpacing.xl),
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
                      const SizedBox(height: 120), // Bottom padding for floating button
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Floating Start Button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(FitoraSpacing.lg),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    const Color(0xFF0E1312),
                    const Color(0xFF0E1312).withOpacity(0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: GlowContainer(
                glowColor: FitoraColors.mintGreen.withOpacity(0.4),
                padding: EdgeInsets.zero,
                borderRadius: BorderRadius.circular(100),
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    gradient: const LinearGradient(
                      colors: [FitoraColors.mintGreen, FitoraColors.calmCyan],
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(100),
                      onTap: () {
                        context.pushNamed(
                          AppRouteNames.workoutSession,
                          pathParameters: {'id': workout.id},
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
                          const SizedBox(width: 8),
                          Text(
                            'START WORKOUT',
                            style: textTheme.labelLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
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
