import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:fitora/app/router/app_routes.dart';
import 'package:fitora/core/constants/spacing.dart';
import 'package:fitora/core/responsive/responsive_builder.dart';
import 'package:fitora/features/workouts/domain/workout_models.dart';
import 'package:fitora/features/workouts/providers/workout_providers.dart';
import 'package:fitora/features/workouts/widgets/workout_card.dart';
import 'package:fitora/features/workouts/widgets/workout_category_section.dart';
import 'package:fitora/features/workouts/widgets/workout_featured_card.dart';
import 'package:fitora/features/workouts/widgets/workout_section_header.dart';
import 'package:fitora/shared/widgets/app_scaffold.dart';
import 'package:fitora/shared/widgets/empty_state_widget.dart';
import 'package:fitora/shared/widgets/loading_widget.dart';

class WorkoutsScreen extends ConsumerWidget {
  const WorkoutsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final browseAsync = ref.watch(workoutBrowseProvider);

    return AppScaffold(
      title: 'Workouts',
      applyPadding: false,
      body: browseAsync.when(
        loading: () => const LoadingWidget(message: 'Loading workouts'),
        error: (_, __) => const EmptyStateWidget(
          icon: Icons.fitness_center_outlined,
          title: 'Unable to load workouts',
          message: 'Please try again in a moment.',
        ),
        data: (data) => ResponsiveBuilder(
          mobile: (_) => _WorkoutsContent(
            data: data,
            maxWidth: 560,
            columns: 1,
          ),
          tablet: (_) => _WorkoutsContent(
            data: data,
            maxWidth: 900,
            columns: 2,
          ),
          desktop: (_) => _WorkoutsContent(
            data: data,
            maxWidth: 1100,
            columns: 3,
          ),
        ),
      ),
    );
  }
}

class _WorkoutsContent extends StatelessWidget {
  final WorkoutBrowseData data;
  final double maxWidth;
  final int columns;

  const _WorkoutsContent({
    required this.data,
    required this.maxWidth,
    required this.columns,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = constraints.maxWidth;
            final itemWidth = columns == 1
                ? availableWidth
                : (availableWidth - (columns - 1) * FitoraSpacing.md) / columns;

            return SingleChildScrollView(
              padding: FitoraSpacing.pagePadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (data.featured.isNotEmpty) ...[
                    const WorkoutSectionHeader(
                      title: 'Featured sessions',
                      subtitle: 'Curated plans to start your week with ease.',
                    ),
                    const SizedBox(height: FitoraSpacing.md),
                    SizedBox(
                      height: 200,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: data.featured.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: FitoraSpacing.md),
                        itemBuilder: (context, index) {
                          final workout = data.featured[index];
                          return SizedBox(
                            width: 320,
                            child: WorkoutFeaturedCard(
                              workout: workout,
                              onTap: () => _openWorkout(context, workout),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: FitoraSpacing.lg),
                  ],
                  const WorkoutSectionHeader(
                    title: 'Recommended for you',
                    subtitle: 'Based on your personalization setup.',
                  ),
                  const SizedBox(height: FitoraSpacing.md),
                  Wrap(
                    spacing: FitoraSpacing.md,
                    runSpacing: FitoraSpacing.md,
                    children: data.recommended
                        .map(
                          (workout) => SizedBox(
                            width: itemWidth,
                            child: WorkoutCard(
                              workout: workout,
                              onTap: () => _openWorkout(context, workout),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: FitoraSpacing.lg),
                  for (final group in data.categories) ...[
                    WorkoutCategorySection(
                      category: group.category,
                      workouts: group.workouts,
                      onWorkoutTap: (workout) => _openWorkout(context, workout),
                    ),
                    const SizedBox(height: FitoraSpacing.lg),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

void _openWorkout(BuildContext context, Workout workout) {
  context.pushNamed(
    AppRouteNames.workoutDetail,
    pathParameters: {'id': workout.id},
  );
}
