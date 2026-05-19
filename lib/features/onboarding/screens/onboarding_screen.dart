import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fitora/app/router/app_routes.dart';
import 'package:fitora/core/constants/spacing.dart';
import 'package:fitora/features/onboarding/presentation/onboarding_page.dart';
import 'package:fitora/features/onboarding/providers/onboarding_controller.dart';
import 'package:fitora/shared/widgets/loading_widget.dart';

class OnboardingScreen extends HookConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);
    final pageController = usePageController(initialPage: state.pageIndex);

    useEffect(() {
      if (!pageController.hasClients) {
        return null;
      }
      final currentPage = pageController.page?.round();
      if (currentPage != null && currentPage != state.pageIndex) {
        pageController.jumpToPage(state.pageIndex);
      }
      return null;
    }, [state.pageIndex]);

    if (state.isLoading) {
      return const Scaffold(
        body: SafeArea(
          child: LoadingWidget(message: 'Preparing your journey'),
        ),
      );
    }

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final icons = [
      Icons.auto_awesome_rounded,
      Icons.dashboard_rounded,
      Icons.psychology_alt_rounded,
      Icons.spa_rounded,
      Icons.favorite_rounded,
    ];
    final accents = [
      colorScheme.primary,
      colorScheme.secondary,
      colorScheme.tertiary,
      colorScheme.primaryContainer,
      colorScheme.secondaryContainer,
    ];

    Future<void> handleStart() async {
      await controller.completeOnboarding();
      if (!context.mounted) {
        return;
      }
      context.go(AppRoutes.home);
    }

    void handleNext() {
      final nextIndex =
          (state.pageIndex + 1).clamp(0, state.pages.length - 1).toInt();
      pageController.jumpToPage(nextIndex);
      controller.setPage(nextIndex);
    }

    void handleSkip() {
      final lastIndex = state.pages.length - 1;
      pageController.jumpToPage(lastIndex);
      controller.skipToLastPage();
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Temporary debug background to validate layout bounds.
            Expanded(
              child: Container(
                color: colorScheme.surfaceVariant.withOpacity(0.18),
                child: PageView.builder(
                  controller: pageController,
                  itemCount: state.pages.length,
                  physics: const BouncingScrollPhysics(),
                  onPageChanged: controller.setPage,
                  itemBuilder: (context, index) {
                    final page = state.pages[index];
                    final icon = icons[index % icons.length];
                    final accent = accents[index % accents.length];

                    return Padding(
                      padding: FitoraSpacing.pagePadding,
                      child: OnboardingPage(
                        data: page,
                        icon: icon,
                        accentColor: accent,
                      ),
                    );
                  },
                ),
              ),
            ),
            Container(
              color: colorScheme.secondaryContainer.withOpacity(0.18),
              padding: const EdgeInsets.fromLTRB(
                FitoraSpacing.md,
                FitoraSpacing.sm,
                FitoraSpacing.md,
                FitoraSpacing.lg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Onboarding controls', style: textTheme.labelLarge),
                  const SizedBox(height: FitoraSpacing.md),
                  TextButton(
                    onPressed: state.isLastPage ? handleStart : handleNext,
                    child: const Text('Next'),
                  ),
                  const SizedBox(height: FitoraSpacing.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(state.pages.length, (dotIndex) {
                      final isActive = dotIndex == state.pageIndex;
                      return Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: FitoraSpacing.xs,
                        ),
                        width: isActive ? 18 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive
                              ? colorScheme.primary
                              : colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(24),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: FitoraSpacing.md),
                  TextButton(
                    onPressed: handleSkip,
                    child: const Text('Skip'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
