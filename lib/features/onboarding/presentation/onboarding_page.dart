import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fitora/core/constants/spacing.dart';
import 'package:fitora/core/theme/fitora_colors.dart';
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

  IconData _getIconForIndex(int idx) {
    switch (idx) {
      case 0:
        return Icons.directions_run_rounded;
      case 1:
        return Icons.water_drop_rounded;
      case 2:
        return Icons.nightlight_round;
      case 3:
        return Icons.emoji_events_rounded;
      default:
        return Icons.fitness_center_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Stack(
      children: [
        // Background Image with dark gradient overlay
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 14,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      data.imagePath,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                    ),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Color(0xBB0E1312),
                            Color(0xFF0E1312),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Expanded(flex: 9, child: SizedBox()),
          ],
        ),

        // Floating Content Card
        Positioned.fill(
          child: SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: FitoraSpacing.xl,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(FitoraSpacing.xl),
                    decoration: BoxDecoration(
                      color: const Color(0xFF161E1C).withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: FitoraColors.mintGreen.withValues(alpha: 0.2),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: FitoraColors.mintGreen.withValues(alpha: 0.1),
                          blurRadius: 30,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: FitoraColors.mintGreen.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _getIconForIndex(index),
                                color: FitoraColors.mintGreen,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'STEP ${index + 1} OF 4',
                              style: textTheme.labelSmall?.copyWith(
                                color: FitoraColors.mintGreen,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ).animate().fadeIn(duration: 300.ms),
                        const SizedBox(height: FitoraSpacing.md),
                        Text(
                          data.title,
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        )
                            .animate()
                            .fadeIn(duration: 400.ms)
                            .slideY(begin: 0.1, end: 0),
                        const SizedBox(height: FitoraSpacing.sm),
                        Text(
                          data.subtitle,
                          style: textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                            height: 1.5,
                          ),
                        )
                            .animate()
                            .fadeIn(delay: 100.ms, duration: 400.ms)
                            .slideY(begin: 0.1, end: 0),
                      ],
                    ),
                  ),
                ),
                const Spacer(flex: 3),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
