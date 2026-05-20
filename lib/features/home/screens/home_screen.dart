import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitora/core/constants/spacing.dart';
import 'package:fitora/core/responsive/responsive_builder.dart';
import 'package:fitora/features/home/domain/home_dashboard_models.dart';
import 'package:fitora/features/home/providers/home_dashboard_providers.dart';
import 'package:fitora/features/home/widgets/home_dashboard_grid.dart';
import 'package:fitora/features/home/widgets/home_dashboard_header.dart';
import 'package:fitora/features/home/widgets/home_workout_highlight_card.dart';
import 'package:fitora/shared/widgets/app_scaffold.dart';
import 'package:fitora/shared/widgets/empty_state_widget.dart';
import 'package:fitora/shared/widgets/loading_widget.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(homeDashboardProvider);

    return AppScaffold(
      title: 'Home',
      applyPadding: false,
      body: dashboardAsync.when(
        loading: () => const LoadingWidget(message: 'Loading dashboard'),
        error: (_, __) => const EmptyStateWidget(
          icon: Icons.dashboard_outlined,
          title: 'Dashboard unavailable',
          message: 'Please check back in a moment.',
        ),
        data: (data) => ResponsiveBuilder(
          mobile: (_) => _HomeLayout(data: data, columns: 1),
          tablet: (_) => _HomeLayout(data: data, columns: 2),
          desktop: (_) => _HomeLayout(data: data, columns: 3),
        ),
      ),
    );
  }
}

class _HomeLayout extends StatelessWidget {
  final int columns;
  final HomeDashboardData data;

  const _HomeLayout({
    required this.columns,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: FitoraSpacing.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HomeDashboardHeader(
            greeting: data.greeting,
            subtitle: data.subtitle,
          ),
          const SizedBox(height: FitoraSpacing.sm),
          Text('Daily snapshot', style: textTheme.titleMedium),
          const SizedBox(height: FitoraSpacing.xs),
          HomeDashboardGrid(data: data, columns: columns),
          const SizedBox(height: FitoraSpacing.md),
          Text('Today\'s workout', style: textTheme.titleMedium),
          const SizedBox(height: FitoraSpacing.xs),
          AspectRatio(
            aspectRatio: columns == 1 ? 2.15 : 3.2,
            child: HomeWorkoutHighlightCard(
              highlight: data.workout,
              onPressed: () {},
            ),
          ),
          const SizedBox(height: FitoraSpacing.md),
        ],
      ),
    );
  }
}
