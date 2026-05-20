import 'package:flutter/material.dart';
import 'package:fitora/core/constants/spacing.dart';
import 'package:fitora/features/workouts/domain/exercise_models.dart';

class WorkoutSessionStatsGrid extends StatelessWidget {
  final ExerciseDose dose;

  const WorkoutSessionStatsGrid({
    super.key,
    required this.dose,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      _SessionStatItem(
        label: 'Duration',
        value: _formatDuration(dose.duration),
        icon: Icons.timer_outlined,
      ),
      _SessionStatItem(
        label: 'Sets',
        value: _formatNumber(dose.sets),
        icon: Icons.layers_outlined,
      ),
      _SessionStatItem(
        label: 'Reps',
        value: _formatNumber(dose.reps),
        icon: Icons.repeat_rounded,
      ),
      _SessionStatItem(
        label: 'Rest',
        value: _formatDuration(dose.rest),
        icon: Icons.pause_circle_outline,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = FitoraSpacing.sm;
        final isCompact = constraints.maxWidth < 520;

        if (isCompact) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: _SessionStatCard(item: items[0])),
                  SizedBox(width: spacing),
                  Expanded(child: _SessionStatCard(item: items[1])),
                ],
              ),
              SizedBox(height: spacing),
              Row(
                children: [
                  Expanded(child: _SessionStatCard(item: items[2])),
                  SizedBox(width: spacing),
                  Expanded(child: _SessionStatCard(item: items[3])),
                ],
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: _SessionStatCard(item: items[0])),
            SizedBox(width: spacing),
            Expanded(child: _SessionStatCard(item: items[1])),
            SizedBox(width: spacing),
            Expanded(child: _SessionStatCard(item: items[2])),
            SizedBox(width: spacing),
            Expanded(child: _SessionStatCard(item: items[3])),
          ],
        );
      },
    );
  }
}

class _SessionStatItem {
  final String label;
  final String value;
  final IconData icon;

  const _SessionStatItem({
    required this.label,
    required this.value,
    required this.icon,
  });
}

class _SessionStatCard extends StatelessWidget {
  final _SessionStatItem item;

  const _SessionStatCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(FitoraSpacing.sm),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant,
        borderRadius: FitoraSpacing.cardRadius,
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(item.icon, size: 18, color: colorScheme.primary),
          const SizedBox(height: FitoraSpacing.xs),
          Text(
            item.value,
            style: textTheme.titleMedium,
          ),
          const SizedBox(height: FitoraSpacing.xs),
          Text(
            item.label,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatNumber(int? value) {
  return value?.toString() ?? '—';
}

String _formatDuration(Duration? duration) {
  if (duration == null) {
    return '—';
  }
  final minutes = duration.inMinutes;
  final seconds = duration.inSeconds % 60;
  if (minutes == 0) {
    return '${seconds}s';
  }
  if (seconds == 0) {
    return '${minutes} min';
  }
  return '${minutes}m ${seconds}s';
}
