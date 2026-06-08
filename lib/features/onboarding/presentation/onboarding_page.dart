import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fitora/core/constants/spacing.dart';
import 'package:fitora/features/onboarding/domain/onboarding_models.dart';

class OnboardingPage extends StatelessWidget {
  final OnboardingPageData data;
  final int index;
  final Color accentColor;

  const OnboardingPage({
    super.key,
    required this.data,
    required this.index,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 14,
          child: Image.asset(
            data.imagePath,
            fit: BoxFit.cover,
            width: double.infinity,
            alignment: Alignment.topCenter,
          ),
        ),
        Expanded(
          flex: 9,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: FitoraSpacing.xl,
              vertical: FitoraSpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
                const SizedBox(height: FitoraSpacing.md),
                Text(
                  data.subtitle,
                  style: textTheme.bodyLarge?.copyWith(
                    color: Colors.white70,
                    height: 1.5,
                  ),
                ).animate().fadeIn(delay: 100.ms, duration: 400.ms).slideY(begin: 0.1, end: 0),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
