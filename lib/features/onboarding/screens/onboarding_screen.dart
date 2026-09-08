import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fitora/app/router/app_routes.dart';
import 'package:fitora/core/constants/spacing.dart';
import 'package:fitora/core/theme/fitora_colors.dart';
import 'package:fitora/core/services/permission_manager.dart';
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          PermissionManager.requestFirstLaunchPermissions(context, ref);
        }
      });
      return null;
    }, const []);

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
        body: SafeArea(child: LoadingWidget(message: 'Preparing your journey')),
      );
    }

    final colorScheme = Theme.of(context).colorScheme;
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
      // Request Activity Recognition and Notifications sequentially on first launch
      await PermissionManager.requestFirstLaunchPermissions(context, ref);
      if (!context.mounted) {
        return;
      }
      context.go(AppRoutes.home);
    }

    Future<void> handleNext() async {
      final nextIndex = (state.pageIndex + 1)
          .clamp(0, state.pages.length - 1)
          .toInt();
      await pageController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }

    Future<void> handleBack() async {
      final prevIndex = (state.pageIndex - 1)
          .clamp(0, state.pages.length - 1)
          .toInt();
      await pageController.animateToPage(
        prevIndex,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    }

    Future<void> handleSkip() async {
      final lastIndex = state.pages.length - 1;
      await pageController.animateToPage(
        lastIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: pageController,
              itemCount: state.pages.length,
              physics: const BouncingScrollPhysics(),
              onPageChanged: controller.setPage,
              itemBuilder: (context, index) {
                final page = state.pages[index];
                final accent = accents[index % accents.length];
                return OnboardingPage(
                  data: page,
                  index: index,
                  accentColor: accent,
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                FitoraSpacing.xl,
                0,
                FitoraSpacing.xl,
                FitoraSpacing.lg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _OnboardingIndicator(
                    total: state.pages.length,
                    currentIndex: state.pageIndex,
                  ),
                  const SizedBox(height: FitoraSpacing.xl),
                  _OnboardingControlsRow(
                    isLastPage: state.isLastPage,
                    onBack: handleBack,
                    onNext: handleNext,
                    onSkip: handleSkip,
                    onStart: handleStart,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingControlsRow extends StatelessWidget {
  final bool isLastPage;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final VoidCallback onStart;

  const _OnboardingControlsRow({
    required this.isLastPage,
    required this.onBack,
    required this.onNext,
    required this.onSkip,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final backLabel = isLastPage ? 'Back' : 'Skip';
    final nextLabel = isLastPage ? 'Get started' : 'Next';

    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: isLastPage ? onBack : onSkip,
            child: Text(backLabel),
          ),
        ),
        const SizedBox(width: FitoraSpacing.md),
        Expanded(
          child: FilledButton(
            onPressed: isLastPage ? onStart : onNext,
            child: Text(nextLabel),
          ),
        ),
      ],
    );
  }
}

class _OnboardingIndicator extends StatelessWidget {
  final int total;
  final int currentIndex;

  const _OnboardingIndicator({required this.total, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (index) {
        final isActive = index == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? FitoraColors.mintGreen : Colors.white30,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
