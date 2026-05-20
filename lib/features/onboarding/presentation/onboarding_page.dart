import 'package:flutter/material.dart';
import 'package:fitora/core/constants/spacing.dart';
import 'package:fitora/features/onboarding/domain/onboarding_models.dart';
import 'package:fitora/shared/widgets/glow_container.dart';

class OnboardingPage extends StatelessWidget {
  final OnboardingPageData data;
  final IconData icon;
  final Color accentColor;

  const OnboardingPage({
    super.key,
    required this.data,
    required this.icon,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final hero = GlowContainer(
      glowColor: accentColor.withOpacity(0.2),
      child: Container(
        padding: const EdgeInsets.all(FitoraSpacing.md),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 40, color: accentColor),
      ),
    );

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        hero,
        const SizedBox(height: FitoraSpacing.md),
        Text(
          data.title,
          style: textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: FitoraSpacing.sm),
        Text(
          data.subtitle,
          style: textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
