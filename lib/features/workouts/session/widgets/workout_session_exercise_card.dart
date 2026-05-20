import 'package:flutter/material.dart';
import 'package:fitora/core/constants/spacing.dart';
import 'package:fitora/features/workouts/domain/exercise_models.dart';
import 'package:fitora/shared/widgets/glow_container.dart';
import 'package:flutter/scheduler.dart';

class WorkoutSessionExerciseCard extends StatelessWidget {
  final Exercise exercise;

  const WorkoutSessionExerciseCard({
    super.key,
    required this.exercise,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: double.infinity,
      child: GlowContainer(
        glowColor: colorScheme.primary.withOpacity(0.16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExerciseVisual(target: exercise.targetMuscle),
            const SizedBox(height: FitoraSpacing.sm),
            Text(exercise.title, style: textTheme.titleLarge),
            const SizedBox(height: FitoraSpacing.xs),
            Text(
              exercise.dose.summary,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: FitoraSpacing.sm),
            Text(
              '${exercise.targetMuscle.label} · ${_equipmentLabel(exercise.equipment)}',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: FitoraSpacing.md),
            const SizedBox(height: FitoraSpacing.sm),
            _ExpandableSection(
              title: 'How to perform',
              children: exercise.instructions
                  .map((i) => Text('• $i', style: textTheme.bodySmall))
                  .toList(),
            ),
            const SizedBox(height: FitoraSpacing.sm),
            _ExpandableSection(
              title: 'Common mistakes',
              children: [
                Text('Rushing the movement', style: textTheme.bodySmall),
                Text('Incorrect alignment of joints', style: textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: FitoraSpacing.sm),
            _ExpandableSection(
              title: 'Modification',
              children: [
                Text(exercise.beginnerTip ?? 'Use a reduced range of motion', style: textTheme.bodySmall),
              ],
            ),
            if (exercise.beginnerTip != null) ...[
              const SizedBox(height: FitoraSpacing.md),
              Container(
                padding: const EdgeInsets.all(FitoraSpacing.sm),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant,
                  borderRadius: FitoraSpacing.cardRadius,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: 18,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: FitoraSpacing.sm),
                    Expanded(
                      child: Text(
                        exercise.beginnerTip!,
                        style: textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ExerciseVisual extends StatefulWidget {
  final TargetMuscle target;

  const ExerciseVisual({super.key, required this.target});

  @override
  State<ExerciseVisual> createState() => _ExerciseVisualState();
}

class _ExerciseVisualState extends State<ExerciseVisual>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl;

  @override
  void initState() {
    super.initState();
    _ctl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: SizedBox(
        height: 140,
        child: AnimatedBuilder(
          animation: _ctl,
          builder: (context, child) {
            final scale = 0.95 + (_ctl.value * 0.1);
            return Transform.scale(
              scale: scale,
              child: Container(
                width: 220,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _iconFor(widget.target),
                  size: 72,
                  color: colorScheme.primary,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  IconData _iconFor(TargetMuscle t) {
    return switch (t) {
      TargetMuscle.fullBody => Icons.self_improvement,
      TargetMuscle.upperBody => Icons.fitness_center,
      TargetMuscle.lowerBody => Icons.accessibility_new,
      TargetMuscle.core => Icons.directions_run,
      TargetMuscle.cardio => Icons.favorite,
      TargetMuscle.mobility => Icons.accessibility,
      TargetMuscle.recovery => Icons.spa,
    };
  }
}

class _ExpandableSection extends StatefulWidget {
  final String title;
  final List<Widget> children;

  const _ExpandableSection({super.key, required this.title, required this.children});

  @override
  State<_ExpandableSection> createState() => _ExpandableSectionState();
}

class _ExpandableSectionState extends State<_ExpandableSection> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _open = !_open),
          child: Row(
            children: [
              Text(widget.title, style: textTheme.titleSmall),
              const Spacer(),
              Icon(_open ? Icons.expand_less : Icons.expand_more),
            ],
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Column(children: widget.children.map((c) => Padding(
            padding: const EdgeInsets.only(top: FitoraSpacing.xs),
            child: c,
          )).toList()),
          crossFadeState: _open ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 220),
        ),
      ],
    );
  }
}

String _equipmentLabel(List<Equipment> equipment) {
  if (equipment.isEmpty) {
    return 'No equipment';
  }
  final labels = equipment.map((item) => item.label).toList();
  if (labels.length == 1) {
    return labels.first;
  }
  return labels.take(2).join(' · ');
}
