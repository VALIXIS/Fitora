import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fitora/app/router/app_routes.dart';
import 'package:fitora/core/constants/spacing.dart';
import 'package:fitora/core/responsive/breakpoints.dart';
import 'package:fitora/core/responsive/responsive_builder.dart';
import 'package:fitora/core/theme/fitora_colors.dart';
import 'package:fitora/features/personalization/domain/personalization_models.dart';
import 'package:fitora/features/personalization/providers/personalization_controller.dart';
import 'package:fitora/features/personalization/widgets/personalization_option_card.dart';
import 'package:fitora/features/personalization/widgets/personalization_step_header.dart';
import 'package:fitora/features/personalization/widgets/personalization_toggle_chip.dart';
import 'package:fitora/features/personalization/widgets/personalization_wheel_picker.dart';
import 'package:fitora/shared/widgets/fitora_button.dart';
import 'package:fitora/shared/widgets/loading_widget.dart';
import 'package:fitora/features/auth/providers/auth_providers.dart';

class PersonalizationFlowScreen extends HookConsumerWidget {
  const PersonalizationFlowScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(personalizationControllerProvider);
    final controller = ref.read(personalizationControllerProvider.notifier);
    final pageController = usePageController(initialPage: state.stepIndex);
    
    final authSession = ref.watch(authStateProvider);
    final initialName = useMemoized(() => state.profile.name ?? authSession.user?.displayName ?? '');
    final nameController = useTextEditingController(text: initialName);

    useEffect(() {
      if (!pageController.hasClients) return null;
      final currentPage = pageController.page?.round();
      if (currentPage != null && currentPage != state.stepIndex) {
        pageController.jumpToPage(state.stepIndex);
      }
      return null;
    }, [state.stepIndex]);

    if (state.isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0E1312),
        body: SafeArea(
          child: LoadingWidget(message: 'Preparing your wellness setup...'),
        ),
      );
    }

    Future<void> handleNext() async {
      if (!state.canProceed) return;
      if (state.isLastStep) {
        await controller.completePersonalization();
        if (!context.mounted) return;
        context.go(AppRoutes.home);
        return;
      }
      final nextIndex = (state.stepIndex + 1).clamp(0, state.totalSteps - 1).toInt();
      await pageController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
      controller.setStep(nextIndex);
    }

    void handleBack() {
      if (!state.canGoBack) return;
      final prevIndex = (state.stepIndex - 1).clamp(0, state.totalSteps - 1).toInt();
      pageController.animateToPage(
        prevIndex,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
      controller.setStep(prevIndex);
    }

    Widget buildLayout(double maxWidth) {
      return Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Padding(
            padding: FitoraSpacing.pagePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (state.currentStep != PersonalizationStep.welcome && state.currentStep != PersonalizationStep.complete)
                  PersonalizationStepHeader(
                    step: state.currentStep,
                    stepIndex: state.stepIndex - 1, // Offset for welcome
                    totalSteps: state.totalSteps - 2, // Offset for welcome/complete
                    progress: (state.stepIndex) / (state.totalSteps - 2).clamp(1, 9),
                  ),
                const SizedBox(height: FitoraSpacing.lg),
                Expanded(
                  child: PageView(
                    controller: pageController,
                    physics: const NeverScrollableScrollPhysics(), // Managed by buttons
                    children: [
                      _buildWelcomeStep(nameController, controller, state),
                      _buildGoalStep(context, state, controller),
                      _buildWellnessStep(context, state, controller),
                      _buildBodyStep(context, state, controller),
                      _buildCompleteStep(),
                    ],
                  ),
                ),
                const SizedBox(height: FitoraSpacing.md),
                _PersonalizationActionBar(
                  canGoBack: state.canGoBack && state.currentStep != PersonalizationStep.welcome && state.currentStep != PersonalizationStep.complete,
                  canProceed: state.canProceed,
                  isLastStep: state.isLastStep,
                  isWelcome: state.currentStep == PersonalizationStep.welcome,
                  onBack: handleBack,
                  onNext: handleNext,
                ),
                const SizedBox(height: FitoraSpacing.lg),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0E1312),
      body: SafeArea(
        child: ResponsiveBuilder(
          mobile: (_) => buildLayout(560),
          tablet: (_) => buildLayout(760),
          desktop: (_) => buildLayout(920),
        ),
      ),
    );
  }

  Widget _buildStepContent(Widget child) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: FitoraSpacing.lg),
      child: child,
    );
  }

  // STEP 1: Welcome
  Widget _buildWelcomeStep(TextEditingController nameController, PersonalizationController controller, PersonalizationViewState state) {
    return _buildStepContent(
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: FitoraColors.mintGreen.withValues(alpha: 0.15), blurRadius: 40, spreadRadius: 10),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 200,
                  height: 200,
                  child: CircularProgressIndicator(
                    value: 0.2,
                    strokeWidth: 4,
                    color: FitoraColors.mintGreen.withValues(alpha: 0.3),
                  ),
                ).animate(onPlay: (c) => c.repeat()).rotate(duration: 10.seconds),
                SizedBox(
                  width: 170,
                  height: 170,
                  child: CircularProgressIndicator(
                    value: 0.8,
                    strokeWidth: 8,
                    color: FitoraColors.calmCyan.withValues(alpha: 0.5),
                  ),
                ).animate(onPlay: (c) => c.repeat(reverse: true)).rotate(duration: 8.seconds),
                const Icon(Icons.auto_awesome_rounded, size: 60, color: Colors.white),
              ],
            ),
          ).animate().fadeIn(duration: 1.seconds).scale(curve: Curves.easeOutBack),
          const SizedBox(height: 60),
          Text(
            "Let's build your wellness blueprint",
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, height: 1.2),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2, end: 0),
          const SizedBox(height: 20),
          Text(
            "Fitora helps you track and achieve your daily wellness goals.",
            style: TextStyle(fontSize: 18, color: Colors.white.withValues(alpha: 0.7)),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.2, end: 0),
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: FitoraSpacing.lg),
            child: TextFormField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'What should we call you?',
                labelStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.person_outline, color: Colors.white54),
              ),
              onChanged: (val) {
                controller.updateProfile(state.profile.copyWith(name: val.trim()));
              },
            ),
          ).animate().fadeIn(delay: 1000.ms).slideY(begin: 0.2, end: 0),
        ],
      ),
    );
  }

  // STEP 2: Goal
  Widget _buildGoalStep(BuildContext context, PersonalizationViewState state, PersonalizationController controller) {
    return _buildStepContent(
      GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: MediaQuery.of(context).size.width > FitoraBreakpoints.tablet ? 2 : 1,
        childAspectRatio: 3.0,
        mainAxisSpacing: FitoraSpacing.md,
        crossAxisSpacing: FitoraSpacing.md,
        children: [
          _buildOption(state, controller, PersonalizationGoal.loseWeight, Icons.local_fire_department_rounded, FitoraColors.warningOrange),
          _buildOption(state, controller, PersonalizationGoal.gainMuscle, Icons.fitness_center_rounded, FitoraColors.mintGreen),
          _buildOption(state, controller, PersonalizationGoal.stayFit, Icons.favorite_rounded, FitoraColors.softPink),
          _buildOption(state, controller, PersonalizationGoal.improveWellness, Icons.spa_rounded, FitoraColors.calmCyan),
          _buildOption(state, controller, PersonalizationGoal.buildHabits, Icons.check_circle_rounded, FitoraColors.lavender),
          _buildOption(state, controller, PersonalizationGoal.reduceStress, Icons.self_improvement_rounded, Colors.teal),
        ],
      ),
    );
  }

  Widget _buildOption(PersonalizationViewState state, PersonalizationController controller, PersonalizationGoal goal, IconData icon, Color color) {
    return PersonalizationOptionCard(
      title: goal.label,
      subtitle: goal.description,
      icon: icon,
      accentColor: color,
      isSelected: state.profile.goal == goal,
      onTap: () => controller.setGoal(goal),
    );
  }

  // (Removed activity level & workout preference questions)

  // STEP 5: Wellness Focus
  Widget _buildWellnessStep(BuildContext context, PersonalizationViewState state, PersonalizationController controller) {
    return _buildStepContent(
      Wrap(
        spacing: FitoraSpacing.md,
        runSpacing: FitoraSpacing.md,
        children: WellnessInterest.values.map((interest) {
          return PersonalizationToggleChip(
            label: interest.label,
            icon: _getWellnessIcon(interest),
            accentColor: _getWellnessColor(interest),
            isSelected: state.profile.interests.contains(interest),
            onTap: () => controller.toggleInterest(interest),
          );
        }).toList(),
      ),
    );
  }

  IconData _getWellnessIcon(WellnessInterest interest) {
    switch (interest) {
      case WellnessInterest.sleepTracking: return Icons.nights_stay_rounded;
      case WellnessInterest.hydrationReminders: return Icons.water_drop_rounded;
      case WellnessInterest.cycleTracking: return Icons.timelapse_rounded;
      case WellnessInterest.mindfulness: return Icons.self_improvement_rounded;
      case WellnessInterest.stepTracking: return Icons.directions_walk_rounded;
    }
  }

  Color _getWellnessColor(WellnessInterest interest) {
    switch (interest) {
      case WellnessInterest.sleepTracking: return FitoraColors.lavender;
      case WellnessInterest.hydrationReminders: return FitoraColors.calmCyan;
      case WellnessInterest.cycleTracking: return FitoraColors.softPink;
      case WellnessInterest.mindfulness: return FitoraColors.mintGreen;
      case WellnessInterest.stepTracking: return FitoraColors.warningOrange;
    }
  }

  // STEP 6: Body Information
  Widget _buildBodyStep(BuildContext context, PersonalizationViewState state, PersonalizationController controller) {
    final ages = List.generate(80, (index) => (16 + index).toString());
    final heights = List.generate(100, (index) => (120 + index).toString());
    final weights = List.generate(150, (index) => (40 + index).toString());

    int ageIndex = state.profile.age != null ? ages.indexOf(state.profile.age.toString()) : 14; // Default 30
    int heightIndex = state.profile.heightCm != null ? heights.indexOf(state.profile.heightCm!.toInt().toString()) : 50; // Default 170
    int weightIndex = state.profile.weightKg != null ? weights.indexOf(state.profile.weightKg!.toInt().toString()) : 30; // Default 70

    if (ageIndex == -1) ageIndex = 14;
    if (heightIndex == -1) heightIndex = 50;
    if (weightIndex == -1) weightIndex = 30;

    return _buildStepContent(
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: PersonalizationWheelPicker(
              label: 'Age',
              items: ages,
              initialIndex: ageIndex,
              accentColor: FitoraColors.mintGreen,
              onSelectedItemChanged: (index) => controller.setAge(int.parse(ages[index])),
            ),
          ),
          const SizedBox(width: FitoraSpacing.sm),
          Expanded(
            child: PersonalizationWheelPicker(
              label: 'Height (cm)',
              items: heights,
              initialIndex: heightIndex,
              accentColor: FitoraColors.calmCyan,
              onSelectedItemChanged: (index) => controller.setHeight(double.parse(heights[index])),
            ),
          ),
          const SizedBox(width: FitoraSpacing.sm),
          Expanded(
            child: PersonalizationWheelPicker(
              label: 'Weight (kg)',
              items: weights,
              initialIndex: weightIndex,
              accentColor: FitoraColors.lavender,
              onSelectedItemChanged: (index) => controller.setWeight(double.parse(weights[index])),
            ),
          ),
        ],
      ),
    );
  }

  // (Removed lifestyle assessment and AI prediction preview steps)

  // STEP 9: Complete Setup
  Widget _buildCompleteStep() {
    return _buildStepContent(
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 100),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: FitoraColors.mintGreen.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded, color: FitoraColors.mintGreen, size: 80),
          ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
          const SizedBox(height: 40),
          Text(
            "Your blueprint is ready.",
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),
        ],
      ),
    );
  }
}

class _PersonalizationActionBar extends StatelessWidget {
  final bool canGoBack;
  final bool canProceed;
  final bool isLastStep;
  final bool isWelcome;
  final VoidCallback onBack;
  final VoidCallback onNext;

  const _PersonalizationActionBar({
    required this.canGoBack,
    required this.canProceed,
    required this.isLastStep,
    required this.isWelcome,
    required this.onBack,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    if (isWelcome) {
      return FitoraButton(
        label: "Let's Begin",
        isFullWidth: true,
        onPressed: onNext,
      ).animate().fadeIn(delay: 1.2.seconds);
    }

    if (!canGoBack) {
      return FitoraButton(
        label: isLastStep ? 'Enter Fitora' : 'Next',
        isFullWidth: true,
        onPressed: canProceed ? onNext : null,
      );
    }

    return Row(
      children: [
        Expanded(
          flex: 1,
          child: FitoraButton(
            label: 'Back',
            variant: FitoraButtonVariant.secondary,
            onPressed: onBack,
          ),
        ),
        const SizedBox(width: FitoraSpacing.md),
        Expanded(
          flex: 2,
          child: FitoraButton(
            label: isLastStep ? 'Enter Fitora' : 'Next',
            onPressed: canProceed ? onNext : null,
          ),
        ),
      ],
    );
  }
}
