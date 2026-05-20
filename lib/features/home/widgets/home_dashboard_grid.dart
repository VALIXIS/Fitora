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
    return switch (columns) {
      1 => _MobileDashboardGrid(data: data),
      2 => _TabletDashboardGrid(data: data),
      _ => _DesktopDashboardGrid(data: data),
    };
  }
}

class _MobileDashboardGrid extends StatelessWidget {
  final HomeDashboardData data;

  const _MobileDashboardGrid({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1.95,
          child: HomeStepRingCard(progress: data.steps),
        ),
        const SizedBox(height: FitoraSpacing.md),
        _TwoColumnRow(
          left: _metricTile(context, data.metric(HomeMetricType.calories)),
          right: _metricTile(context, data.metric(HomeMetricType.activeMinutes)),
        ),
        const SizedBox(height: FitoraSpacing.md),
        _TwoColumnRow(
          left: _metricTile(context, data.metric(HomeMetricType.water)),
          right: _metricTile(context, data.metric(HomeMetricType.sleep)),
        ),
        const SizedBox(height: FitoraSpacing.md),
        AspectRatio(
          aspectRatio: 4.0,
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
          children: [
            Expanded(
              child: AspectRatio(
                aspectRatio: 1.8,
                child: HomeStepRingCard(progress: data.steps),
              ),
            ),
            const SizedBox(width: FitoraSpacing.md),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AspectRatio(
                    aspectRatio: 3.0,
                    child:
                        _metricTile(context, data.metric(HomeMetricType.calories)),
                  ),
                  const SizedBox(height: FitoraSpacing.md),
                  AspectRatio(
                    aspectRatio: 3.0,
                    child: _metricTile(
                      context,
                      data.metric(HomeMetricType.activeMinutes),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: FitoraSpacing.md),
        Row(
          children: [
            Expanded(
              child: AspectRatio(
                aspectRatio: 4.0,
                child: _metricTile(context, data.metric(HomeMetricType.water)),
              ),
            ),
            const SizedBox(width: FitoraSpacing.md),
            Expanded(
              child: AspectRatio(
                aspectRatio: 4.0,
                child: _metricTile(context, data.metric(HomeMetricType.sleep)),
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
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: AspectRatio(
                aspectRatio: 1.9,
                child: HomeStepRingCard(progress: data.steps),
              ),
            ),
            const SizedBox(width: FitoraSpacing.md),
            Expanded(
              child: AspectRatio(
                aspectRatio: 2.1,
                child: _metricTile(context, data.metric(HomeMetricType.calories)),
              ),
            ),
            const SizedBox(width: FitoraSpacing.md),
            Expanded(
              child: AspectRatio(
                aspectRatio: 2.1,
                child:
                    _metricTile(context, data.metric(HomeMetricType.activeMinutes)),
              ),
            ),
          ],
        ),
        const SizedBox(height: FitoraSpacing.md),
        Row(
          children: [
            Expanded(
              child: AspectRatio(
                aspectRatio: 2.8,
                child: _metricTile(context, data.metric(HomeMetricType.water)),
              ),
            ),
            const SizedBox(width: FitoraSpacing.md),
            Expanded(
              child: AspectRatio(
                aspectRatio: 2.8,
                child: _metricTile(context, data.metric(HomeMetricType.sleep)),
              ),
            ),
            const SizedBox(width: FitoraSpacing.md),
            Expanded(
              child: AspectRatio(
                aspectRatio: 2.8,
                child: _metricTile(context, data.metric(HomeMetricType.streak)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TwoColumnRow extends StatelessWidget {
  final Widget left;
  final Widget right;

  const _TwoColumnRow({
    required this.left,
    required this.right,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 420;
        final aspectRatio = isCompact ? 1.55 : 1.75;

        return Row(
          children: [
            Expanded(
              child: AspectRatio(
                aspectRatio: aspectRatio,
                child: left,
              ),
            ),
            const SizedBox(width: FitoraSpacing.md),
            Expanded(
              child: AspectRatio(
                aspectRatio: aspectRatio,
                child: right,
              ),
            ),
          ],
        );
      },
    );
  }
}

Widget _metricTile(BuildContext context, HomeMetricTileData data) {
  final colorScheme = Theme.of(context).colorScheme;
  final icon = switch (data.type) {
    HomeMetricType.calories => Icons.local_fire_department_rounded,
    HomeMetricType.activeMinutes => Icons.timer_rounded,
    HomeMetricType.water => Icons.water_drop_rounded,
    HomeMetricType.sleep => Icons.nights_stay_rounded,
    HomeMetricType.streak => Icons.auto_awesome_rounded,
  };
  final accent = switch (data.type) {
    HomeMetricType.calories => colorScheme.tertiary,
    HomeMetricType.activeMinutes => colorScheme.primary,
    HomeMetricType.water => colorScheme.secondary,
    HomeMetricType.sleep => colorScheme.primaryContainer,
    HomeMetricType.streak => colorScheme.secondaryContainer,
  };

  return HomeMetricTile(
    data: data,
    icon: icon,
    accentColor: accent,
  );
}
