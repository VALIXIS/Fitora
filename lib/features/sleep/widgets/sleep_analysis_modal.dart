import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fitora/core/constants/spacing.dart';
import 'package:fitora/core/theme/fitora_colors.dart';
import 'package:fitora/features/settings/providers/settings_provider.dart';
import 'package:fitora/shared/widgets/scale_on_press.dart';
import 'package:fitora/core/services/haptic_service.dart';

Future<void> showSleepAnalysisModal(BuildContext context, WidgetRef ref) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const _SleepAnalysisModal(),
  );
}

class _SleepAnalysisModal extends ConsumerStatefulWidget {
  const _SleepAnalysisModal();

  @override
  ConsumerState<_SleepAnalysisModal> createState() => _SleepAnalysisModalState();
}

class _SleepAnalysisModalState extends ConsumerState<_SleepAnalysisModal> {
  double _targetHours = 8.0;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _targetHours = (settings.sleepTargetDurationMinutes / 60.0).clamp(5.0, 12.0);
  }

  Future<void> _saveTargetGoal() async {
    final targetMinutes = (_targetHours * 60).round();
    final notifier = ref.read(settingsProvider.notifier);
    await notifier.updateSetting('sleepTargetDurationMinutes', targetMinutes);

    if (mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tt = theme.textTheme;

    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      label: 'Sleep Target Goal Sheet',
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        padding: const EdgeInsets.all(FitoraSpacing.xl),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: FitoraColors.calmCyan.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.track_changes_rounded,
                        color: FitoraColors.calmCyan,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Target Sleep Goal',
                      style: tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                Semantics(
                  button: true,
                  label: 'Close sleep goal dialog',
                  child: IconButton(
                    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                    icon: Icon(
                      Icons.close_rounded,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    onPressed: () => context.pop(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: FitoraSpacing.sm),

            Text(
              'Set your daily target sleep duration goal using the quick select option chips or bar slider.',
              style: tt.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: FitoraSpacing.lg),

            // Display Target Value
            Center(
              child: Column(
                children: [
                  Text(
                    '${_targetHours.toStringAsFixed(1)} hrs',
                    style: tt.displayLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: FitoraColors.calmCyan,
                    ),
                  ),
                  Text(
                    'Daily Sleep Goal Target',
                    style: tt.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: FitoraSpacing.md),

            // Target Duration Bar Slider
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: FitoraColors.calmCyan,
                inactiveTrackColor: theme.colorScheme.surfaceContainerHighest,
                thumbColor: FitoraColors.calmCyan,
                overlayColor: FitoraColors.calmCyan.withValues(alpha: 0.2),
              ),
              child: Slider(
                value: _targetHours,
                min: 5.0,
                max: 12.0,
                divisions: 14,
                label: '${_targetHours.toStringAsFixed(1)}h Target',
                onChanged: (val) {
                  if (val != _targetHours) {
                    ref.read(hapticServiceProvider).sliderChange();
                  }
                  setState(() => _targetHours = val);
                },
              ),
            ),

            // Quick Select Option Chips for Target Goal
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [6.5, 7.0, 7.5, 8.0, 8.5, 9.0].map((tVal) {
                final isSelected = (_targetHours - tVal).abs() < 0.2;
                final labelStr = '${tVal % 1 == 0 ? tVal.toInt() : tVal} hrs Goal';
                return Semantics(
                  button: true,
                  selected: isSelected,
                  label: labelStr,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
                    child: ChoiceChip(
                      label: Text(labelStr),
                      selected: isSelected,
                      selectedColor: FitoraColors.calmCyan,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? Colors.black
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      onSelected: (_) {
                        ref.read(hapticServiceProvider).buttonPress();
                        setState(() => _targetHours = tVal);
                      },
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: FitoraSpacing.xl),

            // Save Target Goal Button
            Semantics(
              button: true,
              label: 'Save Target Goal',
              child: ScaleOnPress(
                child: ElevatedButton(
                  onPressed: () {
                    ref.read(hapticServiceProvider).buttonPress();
                    _saveTargetGoal();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FitoraColors.calmCyan,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Save Target Goal',
                    style: tt.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
