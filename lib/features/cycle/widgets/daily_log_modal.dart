import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitora/core/theme/fitora_colors.dart';
import 'package:fitora/core/services/haptic_service.dart';
import 'package:fitora/features/cycle/domain/cycle_models.dart';
import 'package:fitora/features/cycle/providers/cycle_provider.dart';

class DailyLogModal extends ConsumerStatefulWidget {
  final DateTime date;

  const DailyLogModal({super.key, required this.date});

  static void show(BuildContext context, DateTime date) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DailyLogModal(date: date),
    );
  }

  @override
  ConsumerState<DailyLogModal> createState() => _DailyLogModalState();
}

class _DailyLogModalState extends ConsumerState<DailyLogModal> {
  FlowLevel? _selectedFlow;
  List<CycleSymptom> _selectedSymptoms = [];
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final cycleState = ref.read(cycleProvider);
    final key = formatLocalDate(widget.date);
    final existingLog = cycleState.dayLogs[key];
    if (existingLog != null) {
      _selectedFlow = existingLog.flow;
      _selectedSymptoms = List<CycleSymptom>.from(existingLog.symptoms);
      _notesController.text = existingLog.notes ?? '';
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _toggleSymptom(CycleSymptom symptom) {
    ref.read(hapticServiceProvider).lightImpact();
    setState(() {
      if (_selectedSymptoms.contains(symptom)) {
        _selectedSymptoms.remove(symptom);
      } else {
        _selectedSymptoms.add(symptom);
      }
    });
  }

  void _selectFlow(FlowLevel? flow) {
    ref.read(hapticServiceProvider).lightImpact();
    setState(() {
      if (_selectedFlow == flow) {
        _selectedFlow = null; // Toggle off if tapped again
      } else {
        _selectedFlow = flow;
      }
    });
  }

  Future<void> _save() async {
    ref.read(hapticServiceProvider).mediumImpact();
    await ref.read(cycleProvider.notifier).logDay(
          widget.date,
          flow: _selectedFlow,
          symptoms: _selectedSymptoms,
          notes: _notesController.text.trim(),
        );
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: FitoraColors.darkSurface,
        title: const Text('Clear Log', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to clear your symptoms and notes for this date?',
          style: TextStyle(color: FitoraColors.darkTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel', style: TextStyle(color: FitoraColors.mintGreen)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear', style: TextStyle(color: FitoraColors.errorRed)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      ref.read(hapticServiceProvider).mediumImpact();
      await ref.read(cycleProvider.notifier).logDay(
            widget.date,
            flow: null,
            symptoms: [],
            notes: '',
          );
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tt = theme.textTheme;

    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      label: 'Cycle Daily Log Sheet',
      child: Container(
        margin: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(context).viewInsets.bottom + 24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: SingleChildScrollView(
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
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: FitoraColors.softPink.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.calendar_today_rounded,
                      color: FitoraColors.softPink,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Log Day — ${widget.date.day} ${_getMonthName(widget.date.month)}',
                      style: tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Flow Selection
              Text(
                'Period Flow (Optional)',
                style: tt.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: FitoraColors.darkTextSecondary,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: FlowLevel.values.map((flow) {
                  final isSelected = _selectedFlow == flow;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Semantics(
                        button: true,
                        selected: isSelected,
                        label: '${flow.displayName} period flow',
                        hint: isSelected ? 'Selected' : 'Double tap to select',
                        child: InkWell(
                          onTap: () => _selectFlow(flow),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            height: 50, // touch target size >= 48
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? FitoraColors.softPink.withValues(alpha: 0.2)
                                  : FitoraColors.darkSurfaceVariant,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? FitoraColors.softPink : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (isSelected) ...[
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    color: FitoraColors.softPink,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                Text(
                                  flow.displayName,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : FitoraColors.darkTextSecondary,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Symptoms Wrap
              Text(
                'Symptoms',
                style: tt.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: FitoraColors.darkTextSecondary,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: CycleSymptom.values.map((symptom) {
                  final isSelected = _selectedSymptoms.contains(symptom);
                  return Semantics(
                    button: true,
                    selected: isSelected,
                    label: '${symptom.displayName} symptom',
                    hint: isSelected ? 'Selected' : 'Double tap to toggle',
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
                      child: InkWell(
                        onTap: () => _toggleSymptom(symptom),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? FitoraColors.softPink.withValues(alpha: 0.15)
                                : FitoraColors.darkSurfaceVariant,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? FitoraColors.softPink : Colors.transparent,
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isSelected) ...[
                                const Icon(
                                  Icons.check_rounded,
                                  color: FitoraColors.softPink,
                                  size: 14,
                                ),
                                const SizedBox(width: 6),
                              ],
                              Text(
                                symptom.displayName,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : FitoraColors.darkTextSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Notes
              Text(
                'Daily Notes',
                style: tt.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: FitoraColors.darkTextSecondary,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _notesController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Add private notes...',
                  hintStyle: const TextStyle(color: Colors.white24),
                  filled: true,
                  fillColor: FitoraColors.darkSurfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Save / Clear Row
              Row(
                children: [
                  Expanded(
                    child: Semantics(
                      button: true,
                      label: 'Clear Log',
                      child: TextButton(
                        onPressed: _delete,
                        style: TextButton.styleFrom(
                          foregroundColor: FitoraColors.errorRed,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          minimumSize: const Size.fromHeight(48),
                        ),
                        child: const Text('Clear Log', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Semantics(
                      button: true,
                      label: 'Save Log',
                      child: ElevatedButton(
                        onPressed: _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: FitoraColors.softPink,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          minimumSize: const Size.fromHeight(48),
                        ),
                        child: const Text('Save Log', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}
