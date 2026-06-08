import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fitora/app/router/app_routes.dart';
import 'package:fitora/core/constants/spacing.dart';
import 'package:fitora/core/theme/fitora_colors.dart';
import 'package:fitora/core/theme/fitora_motion.dart';
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

// StateProvider for category filtering
final workoutCategoryFilterProvider = StateProvider<WorkoutCategory?>((ref) => null);

class WorkoutsScreen extends ConsumerWidget {
  const WorkoutsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final browseAsync = ref.watch(workoutBrowseProvider);
    final selectedCategory = ref.watch(workoutCategoryFilterProvider);
    final workoutsCatalogAsync = ref.watch(workoutCatalogProvider);

    return AppScaffold(
      title: 'Workouts',
      applyPadding: false,
      body: browseAsync.when(
        loading: () => const LoadingWidget(message: 'Loading workouts'),
        error: (_, _) => const EmptyStateWidget(
          icon: Icons.fitness_center_outlined,
          title: 'Unable to load workouts',
          message: 'Please try again in a moment.',
        ),
        data: (data) => Column(
          children: [
            // Category Filter Bar
            _CategoryFilterBar(
              selected: selectedCategory,
              onSelected: (cat) => ref.read(workoutCategoryFilterProvider.notifier).state = cat,
            ),
            Expanded(
              child: workoutsCatalogAsync.when(
                loading: () => const LoadingWidget(message: 'Filtering workouts...'),
                error: (_, _) => const SizedBox.shrink(),
                data: (allWorkouts) {
                  // Filter workouts based on selection
                  final filteredWorkouts = selectedCategory == null
                      ? allWorkouts
                      : allWorkouts.where((w) => w.category == selectedCategory).toList();

                  return ResponsiveBuilder(
                    mobile: (_) => _WorkoutsContent(
                      data: data,
                      filteredWorkouts: filteredWorkouts,
                      selectedCategory: selectedCategory,
                      maxWidth: 560,
                      columns: 1,
                    ),
                    tablet: (_) => _WorkoutsContent(
                      data: data,
                      filteredWorkouts: filteredWorkouts,
                      selectedCategory: selectedCategory,
                      maxWidth: 900,
                      columns: 2,
                    ),
                    desktop: (_) => _WorkoutsContent(
                      data: data,
                      filteredWorkouts: filteredWorkouts,
                      selectedCategory: selectedCategory,
                      maxWidth: 1100,
                      columns: 3,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryFilterBar extends StatelessWidget {
  final WorkoutCategory? selected;
  final ValueChanged<WorkoutCategory?> onSelected;

  const _CategoryFilterBar({
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: FitoraSpacing.md),
        children: [
          _buildFilterChip(context, label: 'All', value: null),
          const SizedBox(width: FitoraSpacing.sm),
          ...WorkoutCategory.values.map(
            (cat) => Padding(
              padding: const EdgeInsets.only(right: FitoraSpacing.sm),
              child: _buildFilterChip(context, label: cat.label, value: cat),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, {required String label, required WorkoutCategory? value}) {
    final isSelected = selected == value;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: () => onSelected(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? FitoraColors.mintGreen.withOpacity(0.15) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? FitoraColors.mintGreen.withOpacity(0.5) : Colors.white.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: FitoraColors.mintGreen.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Text(
          label,
          style: textTheme.labelLarge?.copyWith(
            color: isSelected ? FitoraColors.mintGreen : Colors.white70,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class _WorkoutsContent extends StatelessWidget {
  final WorkoutBrowseData data;
  final List<Workout> filteredWorkouts;
  final WorkoutCategory? selectedCategory;
  final double maxWidth;
  final int columns;

  const _WorkoutsContent({
    required this.data,
    required this.filteredWorkouts,
    required this.selectedCategory,
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

            // If a specific category is selected, show distinct grid of workouts under that category
            if (selectedCategory != null) {
              if (filteredWorkouts.isEmpty) {
                return const EmptyStateWidget(
                  icon: Icons.fitness_center_outlined,
                  title: 'No workouts found',
                  message: 'Try switching to a different category.',
                );
              }

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                padding: FitoraSpacing.pagePadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    WorkoutSectionHeader(
                      title: '${selectedCategory!.label} Workouts',
                      subtitle: selectedCategory!.description,
                    )
                        .animate()
                        .fadeIn(duration: const Duration(milliseconds: 300))
                        .slideY(begin: 0.1, end: 0, curve: FitoraMotion.easeOut),
                    const SizedBox(height: FitoraSpacing.md),
                    Wrap(
                      spacing: FitoraSpacing.md,
                      runSpacing: FitoraSpacing.md,
                      children: filteredWorkouts
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
                    )
                        .animate()
                        .fadeIn(delay: const Duration(milliseconds: 100), duration: const Duration(milliseconds: 400))
                        .slideY(begin: 0.05, end: 0, curve: FitoraMotion.easeOut),
                  ],
                ),
              );
            }

            // Otherwise, show default "All" view with horizontal featured scroll, recommendations, and categories
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              padding: FitoraSpacing.pagePadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (data.featured.isNotEmpty) ...[
                    const WorkoutSectionHeader(
                      title: 'Featured sessions',
                      subtitle: 'Curated plans to start your week with ease.',
                    )
                        .animate()
                        .fadeIn(duration: const Duration(milliseconds: 300))
                        .slideY(begin: 0.1, end: 0, curve: FitoraMotion.easeOut),
                    const SizedBox(height: FitoraSpacing.md),
                    SizedBox(
                      height: 340,
                      child: ListView.separated(
                        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                        scrollDirection: Axis.horizontal,
                        itemCount: data.featured.length,
                        separatorBuilder: (_, _) =>
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
                    )
                        .animate()
                        .fadeIn(delay: const Duration(milliseconds: 100), duration: const Duration(milliseconds: 400))
                        .slideY(begin: 0.04, end: 0, curve: FitoraMotion.easeOut),
                    const SizedBox(height: FitoraSpacing.lg),
                  ],
                  const WorkoutSectionHeader(
                    title: 'Recommended for you',
                    subtitle: 'Based on your personalization setup.',
                  )
                      .animate()
                      .fadeIn(delay: const Duration(milliseconds: 180), duration: const Duration(milliseconds: 300)),
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
                  )
                      .animate()
                      .fadeIn(delay: const Duration(milliseconds: 240), duration: const Duration(milliseconds: 400))
                      .slideY(begin: 0.04, end: 0, curve: FitoraMotion.easeOut),
                  const SizedBox(height: FitoraSpacing.lg),
                  for (var i = 0; i < data.categories.length; i++) ...[
                    WorkoutCategorySection(
                      category: data.categories[i].category,
                      workouts: data.categories[i].workouts,
                      onWorkoutTap: (workout) => _openWorkout(context, workout),
                    )
                        .animate()
                        .fadeIn(delay: Duration(milliseconds: 320 + i * 100), duration: const Duration(milliseconds: 400))
                        .slideY(begin: 0.04, end: 0, curve: FitoraMotion.easeOut),
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
