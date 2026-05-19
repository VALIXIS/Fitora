import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fitora/app/router/app_routes.dart';
import 'package:fitora/core/constants/spacing.dart';
import 'package:fitora/core/responsive/breakpoints.dart';
import 'package:fitora/core/responsive/responsive_builder.dart';
import 'package:fitora/features/personalization/domain/personalization_models.dart';
import 'package:fitora/features/personalization/providers/personalization_controller.dart';
import 'package:fitora/features/personalization/widgets/personalization_metric_field.dart';
import 'package:fitora/features/personalization/widgets/personalization_option_card.dart';
import 'package:fitora/features/personalization/widgets/personalization_step_header.dart';
import 'package:fitora/features/personalization/widgets/personalization_toggle_chip.dart';
import 'package:fitora/shared/widgets/fitora_button.dart';
import 'package:fitora/shared/widgets/loading_widget.dart';

class PersonalizationFlowScreen extends HookConsumerWidget {
  const PersonalizationFlowScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(personalizationControllerProvider);
    final controller = ref.read(personalizationControllerProvider.notifier);
    final pageController = usePageController(initialPage: state.stepIndex);

    useEffect(() {
      if (!pageController.hasClients) {
        return null;
      }
      final currentPage = pageController.page?.round();
      if (currentPage != null && currentPage != state.stepIndex) {
        pageController.jumpToPage(state.stepIndex);
      }
      return null;
    }, [state.stepIndex]);

    final ageController =
        useTextEditingController(text: _formatInt(state.profile.age));
    final heightController =
        useTextEditingController(text: _formatDouble(state.profile.heightCm));
    final weightController =
        useTextEditingController(text: _formatDouble(state.profile.weightKg));

    useEffect(() {
      _syncController(ageController, _formatInt(state.profile.age));
      _syncController(heightController, _formatDouble(state.profile.heightCm));
      _syncController(weightController, _formatDouble(state.profile.weightKg));
      return null;
    }, [state.profile.age, state.profile.heightCm, state.profile.weightKg]);

    if (state.isLoading) {
      return const Scaffold(
        body: SafeArea(
          child: LoadingWidget(message: 'Preparing your plan'),
        ),
      );
    }

    Future<void> handleNext() async {
      if (!state.canProceed) {
        return;
      }

      if (state.isLastStep) {
        await controller.completePersonalization();
        if (!context.mounted) {
          return;
        }
        context.go(AppRoutes.home);
        return;
      }

      final nextIndex =
          (state.stepIndex + 1).clamp(0, state.totalSteps - 1).toInt();
      await pageController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
      controller.setStep(nextIndex);
    }

    void handleBack() {
      if (!state.canGoBack) {
        return;
      }

      final prevIndex =
          (state.stepIndex - 1).clamp(0, state.totalSteps - 1).toInt();
      pageController.animateToPage(
        prevIndex,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
      controller.setStep(prevIndex);
    }

    Widget buildOptionGrid<T>({
      required List<_OptionDefinition<T>> options,
      required bool Function(T value) isSelected,
      required ValueChanged<T> onSelected,
    }) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final isTwoColumn = constraints.maxWidth >= FitoraBreakpoints.tablet;
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isTwoColumn ? 2 : 1,
              crossAxisSpacing: FitoraSpacing.md,
              mainAxisSpacing: FitoraSpacing.md,
              childAspectRatio: isTwoColumn ? 2.7 : 2.9,
            ),
            itemCount: options.length,
            itemBuilder: (context, index) {
              final option = options[index];
              return PersonalizationOptionCard(
                title: option.title,
                subtitle: option.subtitle,
                icon: option.icon,
                accentColor: option.accentColor,
                isSelected: isSelected(option.value),
                onTap: () => onSelected(option.value),
              );
            },
          );
        },
      );
    }

    Widget buildStepContent(Widget child) {
      return SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: FitoraSpacing.lg),
        child: child,
      );
    }

    Widget buildGoalStep(ColorScheme colorScheme) {
      final options = [
        _OptionDefinition(
          value: PersonalizationGoal.loseWeight,
          title: PersonalizationGoal.loseWeight.label,
          subtitle: PersonalizationGoal.loseWeight.description,
          icon: Icons.local_fire_department_rounded,
          accentColor: colorScheme.tertiary,
        ),
        _OptionDefinition(
          value: PersonalizationGoal.gainMuscle,
          title: PersonalizationGoal.gainMuscle.label,
          subtitle: PersonalizationGoal.gainMuscle.description,
          icon: Icons.fitness_center_rounded,
          accentColor: colorScheme.primary,
        ),
        _OptionDefinition(
          value: PersonalizationGoal.stayFit,
          title: PersonalizationGoal.stayFit.label,
          subtitle: PersonalizationGoal.stayFit.description,
          icon: Icons.favorite_rounded,
          accentColor: colorScheme.secondary,
        ),
        _OptionDefinition(
          value: PersonalizationGoal.improveWellness,
          title: PersonalizationGoal.improveWellness.label,
          subtitle: PersonalizationGoal.improveWellness.description,
          icon: Icons.spa_rounded,
          accentColor: colorScheme.primaryContainer,
        ),
        _OptionDefinition(
          value: PersonalizationGoal.buildHabits,
          title: PersonalizationGoal.buildHabits.label,
          subtitle: PersonalizationGoal.buildHabits.description,
          icon: Icons.auto_awesome_rounded,
          accentColor: colorScheme.secondaryContainer,
        ),
        _OptionDefinition(
          value: PersonalizationGoal.reduceStress,
          title: PersonalizationGoal.reduceStress.label,
          subtitle: PersonalizationGoal.reduceStress.description,
          icon: Icons.self_improvement_rounded,
          accentColor: colorScheme.tertiaryContainer,
        ),
      ];

      return buildStepContent(
        buildOptionGrid<PersonalizationGoal>(
          options: options,
          isSelected: (value) => state.profile.goal == value,
          onSelected: controller.setGoal,
        ),
      );
    }

    Widget buildWorkoutStep(ColorScheme colorScheme) {
      final options = [
        _OptionDefinition(
          value: WorkoutPreference.home,
          title: WorkoutPreference.home.label,
          subtitle: WorkoutPreference.home.description,
          icon: Icons.home_rounded,
          accentColor: colorScheme.primary,
        ),
        _OptionDefinition(
          value: WorkoutPreference.gym,
          title: WorkoutPreference.gym.label,
          subtitle: WorkoutPreference.gym.description,
          icon: Icons.fitness_center_rounded,
          accentColor: colorScheme.secondary,
        ),
        _OptionDefinition(
          value: WorkoutPreference.mixed,
          title: WorkoutPreference.mixed.label,
          subtitle: WorkoutPreference.mixed.description,
          icon: Icons.shuffle_rounded,
          accentColor: colorScheme.tertiary,
        ),
      ];

      return buildStepContent(
        buildOptionGrid<WorkoutPreference>(
          options: options,
          isSelected: (value) => state.profile.workoutPreference == value,
          onSelected: controller.setWorkoutPreference,
        ),
      );
    }

    Widget buildExperienceStep(ColorScheme colorScheme) {
      final options = [
        _OptionDefinition(
          value: ExperienceLevel.beginner,
          title: ExperienceLevel.beginner.label,
          subtitle: ExperienceLevel.beginner.description,
          icon: Icons.emoji_nature_rounded,
          accentColor: colorScheme.primaryContainer,
        ),
        _OptionDefinition(
          value: ExperienceLevel.intermediate,
          title: ExperienceLevel.intermediate.label,
          subtitle: ExperienceLevel.intermediate.description,
          icon: Icons.trending_up_rounded,
          accentColor: colorScheme.primary,
        ),
        _OptionDefinition(
          value: ExperienceLevel.advanced,
          title: ExperienceLevel.advanced.label,
          subtitle: ExperienceLevel.advanced.description,
          icon: Icons.bolt_rounded,
          accentColor: colorScheme.secondary,
        ),
      ];

      return buildStepContent(
        buildOptionGrid<ExperienceLevel>(
          options: options,
          isSelected: (value) => state.profile.experienceLevel == value,
          onSelected: controller.setExperienceLevel,
        ),
      );
    }

    Widget buildMetricsStep(ColorScheme colorScheme, TextTheme textTheme) {
      return buildStepContent(
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'We use metric units. You can update these later in settings.',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: FitoraSpacing.lg),
            PersonalizationMetricField(
              label: 'Age',
              hint: 'e.g. 28',
              suffix: 'years',
              controller: ageController,
              keyboardType: TextInputType.number,
              onChanged: (value) =>
                  controller.setAge(_parseInt(value)),
            ),
            const SizedBox(height: FitoraSpacing.md),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide =
                    constraints.maxWidth >= FitoraBreakpoints.tablet;
                final heightField = PersonalizationMetricField(
                  label: 'Height',
                  hint: 'e.g. 170',
                  suffix: 'cm',
                  controller: heightController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (value) =>
                      controller.setHeight(_parseDouble(value)),
                );
                final weightField = PersonalizationMetricField(
                  label: 'Weight',
                  hint: 'e.g. 68',
                  suffix: 'kg',
                  controller: weightController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (value) =>
                      controller.setWeight(_parseDouble(value)),
                );

                if (isWide) {
                  return Row(
                    children: [
                      Expanded(child: heightField),
                      const SizedBox(width: FitoraSpacing.md),
                      Expanded(child: weightField),
                    ],
                  );
                }

                return Column(
                  children: [
                    heightField,
                    const SizedBox(height: FitoraSpacing.md),
                    weightField,
                  ],
                );
              },
            ),
          ],
        ),
      );
    }

    Widget buildWellnessStep(ColorScheme colorScheme, TextTheme textTheme) {
      final options = [
        _ChipDefinition(
          value: WellnessInterest.sleepTracking,
          label: WellnessInterest.sleepTracking.label,
          icon: Icons.nights_stay_rounded,
          accentColor: colorScheme.primary,
        ),
        _ChipDefinition(
          value: WellnessInterest.hydrationReminders,
          label: WellnessInterest.hydrationReminders.label,
          icon: Icons.water_drop_rounded,
          accentColor: colorScheme.secondary,
        ),
        _ChipDefinition(
          value: WellnessInterest.cycleTracking,
          label: WellnessInterest.cycleTracking.label,
          icon: Icons.timelapse_rounded,
          accentColor: colorScheme.tertiary,
        ),
        _ChipDefinition(
          value: WellnessInterest.mindfulness,
          label: WellnessInterest.mindfulness.label,
          icon: Icons.self_improvement_rounded,
          accentColor: colorScheme.primaryContainer,
        ),
        _ChipDefinition(
          value: WellnessInterest.stepTracking,
          label: WellnessInterest.stepTracking.label,
          icon: Icons.directions_walk_rounded,
          accentColor: colorScheme.secondaryContainer,
        ),
      ];

      return buildStepContent(
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Optional. Choose as many as you like.',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: FitoraSpacing.md),
            Wrap(
              spacing: FitoraSpacing.sm,
              runSpacing: FitoraSpacing.sm,
              children: options
                  .map(
                    (option) => PersonalizationToggleChip(
                      label: option.label,
                      icon: option.icon,
                      accentColor: option.accentColor,
                      isSelected:
                          state.profile.interests.contains(option.value),
                      onTap: () => controller.toggleInterest(option.value),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: FitoraSpacing.md),
            Text(
              'You can fine-tune these any time from your profile.',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    Widget buildLayout(double maxWidth) {
      final colorScheme = Theme.of(context).colorScheme;
      final textTheme = Theme.of(context).textTheme;

      return Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Padding(
            padding: FitoraSpacing.pagePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PersonalizationStepHeader(
                  step: state.currentStep,
                  stepIndex: state.stepIndex,
                  totalSteps: state.totalSteps,
                  progress: state.progress,
                ),
                const SizedBox(height: FitoraSpacing.lg),
                Expanded(
                  child: PageView(
                    controller: pageController,
                    physics: const BouncingScrollPhysics(),
                    onPageChanged: controller.setStep,
                    children: [
                      buildGoalStep(colorScheme),
                      buildWorkoutStep(colorScheme),
                      buildExperienceStep(colorScheme),
                      buildMetricsStep(colorScheme, textTheme),
                      buildWellnessStep(colorScheme, textTheme),
                    ],
                  ),
                ),
                const SizedBox(height: FitoraSpacing.md),
                _PersonalizationActionBar(
                  canGoBack: state.canGoBack,
                  canProceed: state.canProceed,
                  isLastStep: state.isLastStep,
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
      body: SafeArea(
        child: Stack(
          children: [
            const _PersonalizationBackground(),
            ResponsiveBuilder(
              mobile: (_) => buildLayout(560),
              tablet: (_) => buildLayout(760),
              desktop: (_) => buildLayout(920),
            ),
          ],
        ),
      ),
    );
  }
}

class _PersonalizationActionBar extends StatelessWidget {
  final bool canGoBack;
  final bool canProceed;
  final bool isLastStep;
  final VoidCallback onBack;
  final VoidCallback onNext;

  const _PersonalizationActionBar({
    required this.canGoBack,
    required this.canProceed,
    required this.isLastStep,
    required this.onBack,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    if (!canGoBack) {
      return FitoraButton(
        label: isLastStep ? 'Finish setup' : 'Next',
        onPressed: canProceed ? onNext : null,
      );
    }

    return Row(
      children: [
        Expanded(
          child: FitoraButton(
            label: 'Back',
            variant: FitoraButtonVariant.secondary,
            onPressed: onBack,
          ),
        ),
        const SizedBox(width: FitoraSpacing.md),
        Expanded(
          child: FitoraButton(
            label: isLastStep ? 'Finish setup' : 'Next',
            onPressed: canProceed ? onNext : null,
          ),
        ),
      ],
    );
  }
}

class _PersonalizationBackground extends StatelessWidget {
  const _PersonalizationBackground();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colorScheme.background,
            colorScheme.surfaceVariant.withOpacity(0.55),
          ],
        ),
      ),
    );
  }
}

class _OptionDefinition<T> {
  final T value;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;

  const _OptionDefinition({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
  });
}

class _ChipDefinition<T> {
  final T value;
  final String label;
  final IconData icon;
  final Color accentColor;

  const _ChipDefinition({
    required this.value,
    required this.label,
    required this.icon,
    required this.accentColor,
  });
}

int? _parseInt(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  return int.tryParse(trimmed);
}

double? _parseDouble(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  return double.tryParse(trimmed);
}

String _formatInt(int? value) {
  if (value == null) {
    return '';
  }
  return value.toString();
}

String _formatDouble(double? value) {
  if (value == null) {
    return '';
  }
  final isWhole = value % 1 == 0;
  return isWhole ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
}

void _syncController(TextEditingController controller, String text) {
  if (controller.text == text) {
    return;
  }
  controller.value = controller.value.copyWith(
    text: text,
    selection: TextSelection.collapsed(offset: text.length),
    composing: TextRange.empty,
  );
}
