import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitora/core/theme/fitora_colors.dart';
import 'package:fitora/core/services/haptic_service.dart';
import 'package:fitora/shared/widgets/scale_on_press.dart';
import 'package:fitora/features/personalization/providers/personalization_controller.dart';
import 'package:fitora/features/workouts/domain/workout_models.dart';
import 'package:fitora/features/workouts/providers/workout_provider.dart';

class LogWorkoutModal extends ConsumerStatefulWidget {
  const LogWorkoutModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const LogWorkoutModal(),
    );
  }

  @override
  ConsumerState<LogWorkoutModal> createState() => _LogWorkoutModalState();
}

class _LogWorkoutModalState extends ConsumerState<LogWorkoutModal> {
  WorkoutActivityType _selectedType = WorkoutActivityType.running;
  double _duration = 30; // default 30 minutes
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  double _calculateCalories(double weight) {
    final met = _selectedType.metMultiplier;
    return met * weight * (_duration / 60.0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tt = theme.textTheme;
    final profile = ref.watch(personalizationControllerProvider).profile;
    final weight = profile.weightKg ?? 70.0;
    final estimatedCal = _calculateCalories(weight);

    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      label: 'Log Workout Dialog',
      child: Container(
        margin: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(context).viewInsets.bottom + 24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: FitoraColors.mintGreen.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.fitness_center_rounded,
                    color: FitoraColors.mintGreen,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Log Workout',
                    style: tt.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Activity Type',
              style: tt.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: WorkoutActivityType.values.map((type) {
                final isSelected = _selectedType == type;
                return Semantics(
                  button: true,
                  selected: isSelected,
                  label: '${type.label} activity',
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 48),
                    child: ChoiceChip(
                      label: Text(type.label),
                      avatar: Icon(type.icon, size: 16, color: isSelected ? Colors.black : theme.colorScheme.onSurfaceVariant),
                      selected: isSelected,
                      onSelected: (val) {
                        if (val) {
                          ref.read(hapticServiceProvider).buttonPress();
                          setState(() {
                            _selectedType = type;
                          });
                        }
                      },
                      selectedColor: FitoraColors.mintGreen,
                      backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.black : theme.colorScheme.onSurface,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Duration',
                  style: tt.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${_duration.round()} mins',
                  style: tt.bodyMedium?.copyWith(color: FitoraColors.mintGreen, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Slider(
              value: _duration,
              min: 15,
              max: 120,
              divisions: 21,
              label: '${_duration.round()} mins',
              activeColor: FitoraColors.mintGreen,
              inactiveColor: theme.colorScheme.onSurface.withValues(alpha: 0.12),
              onChanged: (val) {
                if (val.round() != _duration.round()) {
                  ref.read(hapticServiceProvider).sliderChange();
                }
                setState(() {
                  _duration = val;
                });
              },
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.08)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Estimated Burn',
                        style: tt.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                      Text(
                        '${estimatedCal.round()} kcal',
                        style: tt.titleLarge?.copyWith(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Text(
                    '${_selectedType.metMultiplier} METs',
                    style: tt.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              maxLines: 2,
              style: TextStyle(color: theme.colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: 'Workout notes (optional)...',
                hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
                filled: true,
                fillColor: theme.colorScheme.onSurface.withValues(alpha: 0.04),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.08)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.08)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: FitoraColors.mintGreen),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Semantics(
              button: true,
              label: 'Save Workout',
              child: ScaleOnPress(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FitoraColors.mintGreen,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () async {
                    ref.read(hapticServiceProvider).buttonPress();
                    final log = WorkoutLogEntry(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      activityType: _selectedType,
                      durationMinutes: _duration.round(),
                      estimatedCalories: estimatedCal,
                      timestamp: DateTime.now(),
                      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
                    );
                    await ref.read(workoutProvider.notifier).addWorkoutLog(log);
                    if (mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Logged ${log.activityType.label} successfully!'),
                          backgroundColor: FitoraColors.mintGreen,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  child: const Text(
                    'Save Workout',
                    style: TextStyle(fontWeight: FontWeight.bold),
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
