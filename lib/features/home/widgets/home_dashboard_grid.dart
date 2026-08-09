import 'package:flutter/material.dart';
import 'package:fitora/core/constants/spacing.dart';
import 'package:fitora/features/home/domain/home_dashboard_models.dart';
import 'package:fitora/features/home/widgets/home_metric_tile.dart';
import 'package:fitora/features/home/widgets/home_step_ring_card.dart';

class HomeDashboardGrid extends StatelessWidget {
  final HomeDashboardData data;
  final int columns;

  const HomeDashboardGrid({
    super.key,
    required this.data,
    required this.columns,
  });

  @override
  Widget build(BuildContext context) {
    if (columns == 1) {
      return _MobileDashboardGrid(data: data);
    } else if (columns == 2) {
      return _TabletDashboardGrid(data: data);
    } else {
      return _DesktopDashboardGrid(data: data);
    }
  }
}

class _MobileDashboardGrid extends StatelessWidget {
  final HomeDashboardData data;

  const _MobileDashboardGrid({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HomeStepRingCard(progress: data.steps),
        const SizedBox(height: FitoraSpacing.md),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: FitoraSpacing.md,
          crossAxisSpacing: FitoraSpacing.md,
          childAspectRatio: 1.4,
          children: [
            _metricTile(context, data.metric(HomeMetricType.calories)),
            _metricTile(context, data.metric(HomeMetricType.activeMinutes)),
            _metricTile(context, data.metric(HomeMetricType.water)),
            _metricTile(context, data.metric(HomeMetricType.sleep)),
          ],
        ),
        const SizedBox(height: FitoraSpacing.md),
        AspectRatio(
          aspectRatio: 3.2,
          child: _metricTile(context, data.metric(HomeMetricType.streak)),
        ),
      ],
    );
  }
}

class _TabletDashboardGrid extends StatelessWidget {
  final HomeDashboardData data;

  const _TabletDashboardGrid({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: HomeStepRingCard(progress: data.steps),
            ),
            const SizedBox(width: FitoraSpacing.md),
            Expanded(
              flex: 6,
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: FitoraSpacing.md,
                crossAxisSpacing: FitoraSpacing.md,
                childAspectRatio: 1.35,
                children: [
                  _metricTile(context, data.metric(HomeMetricType.calories)),
                  _metricTile(context, data.metric(HomeMetricType.activeMinutes)),
                  _metricTile(context, data.metric(HomeMetricType.water)),
                  _metricTile(context, data.metric(HomeMetricType.sleep)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: FitoraSpacing.md),
        AspectRatio(
          aspectRatio: 6.0,
          child: _metricTile(context, data.metric(HomeMetricType.streak)),
        ),
      ],
    );
  }
}

class _DesktopDashboardGrid extends StatelessWidget {
  final HomeDashboardData data;

  const _DesktopDashboardGrid({required this.data});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Column(
            children: [
              HomeStepRingCard(progress: data.steps),
              const SizedBox(height: FitoraSpacing.md),
              AspectRatio(
                aspectRatio: 3.0,
                child: _metricTile(context, data.metric(HomeMetricType.streak)),
              ),
            ],
          ),
        ),
        const SizedBox(width: FitoraSpacing.md),
        Expanded(
          flex: 8,
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: FitoraSpacing.md,
            crossAxisSpacing: FitoraSpacing.md,
            childAspectRatio: 1.8,
            children: [
              _metricTile(context, data.metric(HomeMetricType.calories)),
              _metricTile(context, data.metric(HomeMetricType.activeMinutes)),
              _metricTile(context, data.metric(HomeMetricType.water)),
              _metricTile(context, data.metric(HomeMetricType.sleep)),
            ],
          ),
        ),
      ],
    );
  }
}

Widget _metricTile(BuildContext context, HomeMetricTileData data) {
  final colorScheme = Theme.of(context).colorScheme;
  IconData icon;
  switch (data.type) {
    case HomeMetricType.calories:
      icon = Icons.local_fire_department_rounded;
      break;
    case HomeMetricType.activeMinutes:
      icon = Icons.timer_rounded;
      break;
    case HomeMetricType.water:
      icon = Icons.water_drop_rounded;
      break;
    case HomeMetricType.sleep:
      icon = Icons.nights_stay_rounded;
      break;
    case HomeMetricType.streak:
      icon = Icons.auto_awesome_rounded;
      break;
  }

  Color accent;
  switch (data.type) {
    case HomeMetricType.calories:
      accent = colorScheme.tertiary;
      break;
    case HomeMetricType.activeMinutes:
      accent = colorScheme.primary;
      break;
    case HomeMetricType.water:
      accent = colorScheme.secondary;
      break;
    case HomeMetricType.sleep:
      accent = colorScheme.primaryContainer;
      break;
    case HomeMetricType.streak:
      accent = colorScheme.secondaryContainer;
      break;
  }

  return HomeMetricTile(
    data: data,
    icon: icon,
    accentColor: accent,
  );
}
