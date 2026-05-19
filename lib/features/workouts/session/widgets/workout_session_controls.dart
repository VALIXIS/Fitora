import 'package:flutter/material.dart';
import 'package:fitora/core/constants/spacing.dart';
import 'package:fitora/shared/widgets/fitora_button.dart';

class WorkoutSessionControls extends StatelessWidget {
  final bool canGoBack;
  final bool canGoNext;
  final bool isPaused;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onEnd;

  const WorkoutSessionControls({
    super.key,
    required this.canGoBack,
    required this.canGoNext,
    required this.isPaused,
    required this.onBack,
    required this.onNext,
    required this.onPause,
    required this.onResume,
    required this.onEnd,
  });

  @override
  Widget build(BuildContext context) {
    final pauseLabel = isPaused ? 'Resume' : 'Pause';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: FitoraButton(
                label: 'Previous',
                variant: FitoraButtonVariant.secondary,
                onPressed: canGoBack ? onBack : null,
              ),
            ),
            const SizedBox(width: FitoraSpacing.md),
            Expanded(
              child: FitoraButton(
                label: 'Next',
                onPressed: canGoNext ? onNext : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: FitoraSpacing.md),
        Row(
          children: [
            Expanded(
              child: FitoraButton(
                label: pauseLabel,
                variant: FitoraButtonVariant.ghost,
                onPressed: isPaused ? onResume : onPause,
              ),
            ),
            const SizedBox(width: FitoraSpacing.md),
            Expanded(
              child: FitoraButton(
                label: 'End session',
                variant: FitoraButtonVariant.secondary,
                onPressed: onEnd,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
