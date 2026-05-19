import 'package:flutter/material.dart';
import 'package:fitora/core/constants/spacing.dart';
import 'package:fitora/shared/widgets/fitora_button.dart';

class OnboardingIndicator extends StatelessWidget {
  final int count;
  final int index;

  const OnboardingIndicator({
    super.key,
    required this.count,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (dotIndex) {
        final isActive = dotIndex == index;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: FitoraSpacing.xs),
          width: isActive ? 18 : 8,
          height: 8,
          decoration: BoxDecoration(
            color:
                isActive ? colorScheme.primary : colorScheme.outlineVariant,
            borderRadius: BorderRadius.circular(24),
          ),
        );
      }),
    );
  }
}

class OnboardingControls extends StatelessWidget {
  final bool isLastPage;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final VoidCallback onStart;

  const OnboardingControls({
    super.key,
    required this.isLastPage,
    required this.onNext,
    required this.onSkip,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    if (isLastPage) {
      return FitoraButton(
        label: 'Start Your Journey',
        onPressed: onStart,
      );
    }

    return Row(
      children: [
        TextButton(
          onPressed: onSkip,
          child: const Text('Skip'),
        ),
        const Spacer(),
        FitoraButton(
          label: 'Next',
          onPressed: onNext,
          isFullWidth: false,
        ),
      ],
    );
  }
}
