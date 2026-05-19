import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fitora/core/constants/app_constants.dart';
import 'package:fitora/core/constants/spacing.dart';
import 'package:fitora/features/onboarding/providers/onboarding_controller.dart';
import 'package:fitora/shared/widgets/app_scaffold.dart';
import 'package:fitora/shared/widgets/glow_container.dart';
import 'package:fitora/shared/widgets/loading_widget.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _startFlow();
  }

  Future<void> _startFlow() async {
    final controller = ref.read(onboardingControllerProvider.notifier);
    await controller.ensureLoaded();
    await Future.delayed(AppConstants.splashDelay);
    if (!mounted) {
      return;
    }
    final nextRoute = await controller.resolveNextRoute();
    if (!mounted) {
      return;
    }
    context.go(nextRoute);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return AppScaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GlowContainer(
              glowColor: colorScheme.primary.withOpacity(0.18),
              child: Container(
                padding: const EdgeInsets.all(FitoraSpacing.md),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  size: 44,
                  color: colorScheme.primary,
                ),
              ),
            )
                .animate()
                .fadeIn(duration: const Duration(milliseconds: 420))
                .scale(
                  begin: const Offset(0.9, 0.9),
                  end: const Offset(1, 1),
                  curve: Curves.easeOutCubic,
                ),
            const SizedBox(height: FitoraSpacing.lg),
            Text(AppConstants.appName, style: textTheme.headlineLarge)
                .animate()
                .fadeIn(
                  delay: const Duration(milliseconds: 120),
                  duration: const Duration(milliseconds: 360),
                ),
            const SizedBox(height: FitoraSpacing.sm),
            Text(
              AppConstants.tagline,
              style: textTheme.bodyMedium,
              textAlign: TextAlign.center,
            )
                .animate()
                .fadeIn(
                  delay: const Duration(milliseconds: 200),
                  duration: const Duration(milliseconds: 360),
                ),
            const SizedBox(height: FitoraSpacing.xl),
            const LoadingWidget(message: 'Setting up your space', center: false),
          ],
        ),
      ),
    );
  }
}
