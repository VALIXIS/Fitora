import 'package:flutter/material.dart';
import 'package:fitora/core/constants/spacing.dart';
import 'package:fitora/features/workouts/domain/exercise_models.dart';
import 'package:fitora/features/workouts/widgets/exercise_media.dart';
import 'package:fitora/shared/widgets/glow_container.dart';
import 'package:fitora/core/theme/fitora_colors.dart';

class ExerciseCard extends StatefulWidget {
  final Exercise exercise;

  const ExerciseCard({
    super.key,
    required this.exercise,
  });

  @override
  State<ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<ExerciseCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final ex = widget.exercise;

    // Use dynamic/fallback lists for high-fidelity completeness
    final mistakes = ex.commonMistakes ?? [
      'Rushing through reps without control',
      'Holding breath during exertion',
    ];
    final modifications = ex.modifications ?? [
      ex.beginnerTip ?? 'Perform with a lighter load or slower pace.',
    ];

    return GlowContainer(
      glowColor: FitoraColors.mintGreen.withOpacity(0.05),
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF141A1A),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
          // Visual Exercise Media
          ExerciseMedia(
            gifPath: ex.gifPath,
            targetMuscle: ex.targetMuscle,
            height: 140,
          ),
          // Content Padding
          Padding(
            padding: const EdgeInsets.all(FitoraSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ex.title,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${ex.targetMuscle.label} · ${_equipmentLabel(ex.equipment)}',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: FitoraSpacing.sm,
                        vertical: FitoraSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        ex.dose.summary,
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: FitoraSpacing.md),
                
                // Instructions list
                Text(
                  'Instructions',
                  style: textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: FitoraSpacing.xs),
                ...ex.instructions.asMap().entries.map(
                  (entry) {
                    final idx = entry.key + 1;
                    final text = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: FitoraSpacing.xs),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$idx. ',
                            style: textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              text,
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: FitoraSpacing.sm),
                const Divider(),
                const SizedBox(height: FitoraSpacing.xs),

                // Beginner Support: Mistakes & Modifications Expandable
                GestureDetector(
                  onTap: () => setState(() => _isExpanded = !_isExpanded),
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    children: [
                      Icon(
                        Icons.support_agent_rounded,
                        size: 16,
                        color: colorScheme.secondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Form Guide & Modifications',
                        style: textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.secondary,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        _isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                        size: 18,
                        color: colorScheme.secondary,
                      ),
                    ],
                  ),
                ),

                if (_isExpanded) ...[
                  const SizedBox(height: FitoraSpacing.sm),
                  
                  // Mistakes Sub-section
                  Text(
                    'Common Mistakes',
                    style: textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent,
                    ),
                  ),
                  const SizedBox(height: FitoraSpacing.xs),
                  ...mistakes.map(
                    (mistake) => Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.cancel_outlined,
                            size: 12,
                            color: Colors.redAccent,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              mistake,
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: FitoraSpacing.sm),

                  // Modifications Sub-section
                  Text(
                    'Modifications (Easier Version)',
                    style: textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: FitoraSpacing.xs),
                  ...modifications.map(
                    (mod) => Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.check_circle_outline_rounded,
                            size: 12,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              mod,
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
      ),
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
