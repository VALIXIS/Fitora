import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitora/core/theme/fitora_colors.dart';
import 'package:fitora/core/services/haptic_service.dart';
import 'package:fitora/features/cycle/domain/cycle_models.dart';
import 'package:fitora/features/cycle/providers/cycle_provider.dart';
import 'package:fitora/features/cycle/widgets/cycle_calendar.dart';
import 'package:fitora/shared/widgets/fitora_background.dart';

class CycleDashboardScreen extends ConsumerWidget {
  const CycleDashboardScreen({super.key});

  void _showConflictDialog(BuildContext context, WidgetRef ref, DateTime newStartDate) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: FitoraColors.darkSurface,
        title: const Text('Conflict Detected', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Another period is currently marked as ongoing. What would you like to do?',
          style: TextStyle(color: FitoraColors.darkTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: FitoraColors.mintGreen)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await ref.read(cycleProvider.notifier).resolveConflictAndStartPeriod(newStartDate);
            },
            child: const Text(
              'End previous yesterday & start new',
              style: TextStyle(color: FitoraColors.softPink, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showSettingsBottomSheet(BuildContext context, WidgetRef ref) {
    ref.read(hapticServiceProvider).lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const _CycleSettingsBottomSheet(),
    );
  }

  void _showLogPeriodStartDialog(BuildContext context, WidgetRef ref) async {
    ref.read(hapticServiceProvider).lightImpact();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: FitoraColors.softPink,
              onPrimary: Colors.white,
              surface: FitoraColors.darkSurface,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final dateOnly = DateTime(picked.year, picked.month, picked.day);
      final notifier = ref.read(cycleProvider.notifier);
      final success = await notifier.startPeriod(dateOnly);
      if (!success) {
        // Show conflict resolution if ongoing exists
        if (notifier.getOngoingPeriod() != null) {
          if (context.mounted) {
            _showConflictDialog(context, ref, dateOnly);
          }
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Period dates cannot overlap with existing logs.'),
                backgroundColor: FitoraColors.errorRed,
              ),
            );
          }
        }
      }
    }
  }

  void _showEndPeriodDialog(BuildContext context, WidgetRef ref, DateTime ongoingStart) async {
    ref.read(hapticServiceProvider).lightImpact();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().isBefore(ongoingStart) ? ongoingStart : DateTime.now(),
      firstDate: ongoingStart,
      lastDate: DateTime.now().add(const Duration(days: 14)), // Allow a buffer
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: FitoraColors.softPink,
              onPrimary: Colors.white,
              surface: FitoraColors.darkSurface,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final dateOnly = DateTime(picked.year, picked.month, picked.day);
      final success = await ref.read(cycleProvider.notifier).endPeriod(dateOnly);
      if (!success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to end period. Verify date bounds do not overlap.'),
            backgroundColor: FitoraColors.errorRed,
          ),
        );
      }
    }
  }

  void _showEditPeriodDialog(BuildContext context, WidgetRef ref, PeriodRange range) async {
    ref.read(hapticServiceProvider).lightImpact();
    
    // Choose to edit start, end or delete
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: FitoraColors.darkSurface,
        title: const Text('Edit Period Log', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final picked = await showDatePicker(
                  context: context,
                  initialDate: range.startDate,
                  firstDate: range.startDate.subtract(const Duration(days: 90)),
                  lastDate: range.endDate ?? DateTime.now(),
                  builder: (context, child) => Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.dark(primary: FitoraColors.softPink),
                    ),
                    child: child!,
                  ),
                );
                if (picked != null) {
                  final updated = range.copyWith(startDate: DateTime(picked.year, picked.month, picked.day));
                  await ref.read(cycleProvider.notifier).updatePeriod(updated);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: FitoraColors.darkSurfaceVariant),
              child: const Text('Edit Start Date', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final picked = await showDatePicker(
                  context: context,
                  initialDate: range.endDate ?? DateTime.now(),
                  firstDate: range.startDate,
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                  builder: (context, child) => Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.dark(primary: FitoraColors.softPink),
                    ),
                    child: child!,
                  ),
                );
                if (picked != null) {
                  final updated = range.copyWith(endDate: DateTime(picked.year, picked.month, picked.day));
                  await ref.read(cycleProvider.notifier).updatePeriod(updated);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: FitoraColors.darkSurfaceVariant),
              child: const Text('Edit End Date', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 16),
            const Divider(color: FitoraColors.darkBorder),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () async {
                Navigator.of(context).pop();
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: FitoraColors.darkSurface,
                    title: const Text('Delete Period Log?', style: TextStyle(color: Colors.white)),
                    content: const Text('Are you sure you want to permanently delete this logged period range?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Delete', style: TextStyle(color: FitoraColors.errorRed)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await ref.read(cycleProvider.notifier).deletePeriod(range.id);
                }
              },
              icon: const Icon(Icons.delete_rounded, color: FitoraColors.errorRed),
              label: const Text('Delete Period Record', style: TextStyle(color: FitoraColors.errorRed)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tt = theme.textTheme;
    final cycleState = ref.watch(cycleProvider);
    final cycleNotifier = ref.read(cycleProvider.notifier);

    final ongoingPeriod = cycleNotifier.getOngoingPeriod();
    final hasHistory = cycleState.periodRanges.isNotEmpty;
    
    // Cycle Day calculations
    final today = DateTime.now();
    final localToday = DateTime(today.year, today.month, today.day);
    final currentCycleDay = hasHistory ? cycleNotifier.getCycleDay(localToday) : 0;

    // Estimates
    final estimatedNext = cycleNotifier.getEstimatedNextPeriod();
    final stats = cycleNotifier.getStatistics();

    return FitoraBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            onPressed: () {
              ref.read(hapticServiceProvider).lightImpact();
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          ),
          title: Text(
            'Cycle Tracker',
            style: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          actions: [
            IconButton(
              onPressed: () => _showSettingsBottomSheet(context, ref),
              icon: const Icon(Icons.settings_rounded, color: Colors.white, size: 24),
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            // 1. Current Cycle Status Card
            _buildStatusCard(context, ref, currentCycleDay, ongoingPeriod, localToday),
            const SizedBox(height: 16),

            // 2. Predictions Card
            _buildPredictionCard(context, ref, estimatedNext, stats, localToday),
            const SizedBox(height: 16),

            // 3. Calendar Grid
            const CycleCalendar(),
            const SizedBox(height: 16),

            // 4. Statistics Panel
            _buildStatisticsPanel(context, ref, stats),
            const SizedBox(height: 16),

            // 5. Historical Completed Cycles List
            _buildHistorySection(context, ref, cycleState.periodRanges),
            const SizedBox(height: 16),

            // 6. Recent Symptoms Grid
            _buildRecentSymptomsSection(context, ref, cycleState.dayLogs),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(
    BuildContext context,
    WidgetRef ref,
    int cycleDay,
    PeriodRange? ongoingPeriod,
    DateTime today,
  ) {
    final styleTextSecondary = const TextStyle(color: FitoraColors.darkTextSecondary, fontSize: 14);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: FitoraColors.darkSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: FitoraColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cycleDay > 0 ? 'Cycle Day $cycleDay' : 'No Logged Cycles',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ongoingPeriod != null
                        ? 'Period ongoing (Started ${_formatShortDate(ongoingPeriod.startDate)})'
                        : 'No active period logged',
                    style: styleTextSecondary,
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: FitoraColors.softPink.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  ongoingPeriod != null ? Icons.water_drop_rounded : Icons.water_drop_outlined,
                  color: FitoraColors.softPink,
                  size: 28,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (ongoingPeriod != null)
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _showEndPeriodDialog(context, ref, ongoingPeriod.startDate),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FitoraColors.darkSurfaceVariant,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('End Period'),
                  ),
                )
              else
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _showLogPeriodStartDialog(context, ref),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FitoraColors.softPink,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Log Period Start', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionCard(
    BuildContext context,
    WidgetRef ref,
    DateTime? estimatedNext,
    CycleStats stats,
    DateTime today,
  ) {
    final hasPrediction = estimatedNext != null && stats.completedIntervalsCount >= 2;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: FitoraColors.darkSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: FitoraColors.darkBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Next Period Estimate',
                  style: TextStyle(
                    color: FitoraColors.darkTextSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  hasPrediction
                      ? 'Estimated: ${_formatLongDate(estimatedNext)}'
                      : 'Not enough history for an estimate yet.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: hasPrediction ? 18 : 14,
                    fontWeight: hasPrediction ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                if (hasPrediction) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Starts in ${estimatedNext.difference(today).inDays} days (based on a ${stats.averageCycleLength.round()}-day cycle average)',
                    style: const TextStyle(color: FitoraColors.darkTextSecondary, fontSize: 12),
                  ),
                ] else ...[
                  const SizedBox(height: 4),
                  const Text(
                    'At least 2 completed cycle intervals required.',
                    style: TextStyle(color: FitoraColors.darkTextSecondary, fontSize: 11),
                  ),
                ]
              ],
            ),
          ),
          Icon(
            Icons.hourglass_empty_rounded,
            color: hasPrediction ? FitoraColors.softPink : FitoraColors.darkTextSecondary.withValues(alpha: 0.3),
            size: 26,
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsPanel(BuildContext context, WidgetRef ref, CycleStats stats) {
    final hasData = stats.completedIntervalsCount >= 2;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: FitoraColors.darkSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: FitoraColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Cycle Statistics',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (!hasData)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Not enough data yet.\nKeep logging your periods to generate detailed averages, variations, and cycle stats.',
                textAlign: TextAlign.center,
                style: TextStyle(color: FitoraColors.darkTextSecondary, fontSize: 13),
              ),
            )
          else ...[
            Row(
              children: [
                _buildStatCell('Avg Cycle', '${stats.averageCycleLength.toStringAsFixed(0)} days'),
                _buildStatCell('Avg Period', '${stats.averagePeriodDuration.toStringAsFixed(1)} days'),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatCell('Shortest / Longest', '${stats.shortestCycle}d / ${stats.longestCycle}d'),
                _buildStatCell('Variability (SD)', '${stats.cycleVariability} days'),
              ],
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildStatCell(String title, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: FitoraColors.darkSurfaceVariant,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: FitoraColors.darkTextSecondary, fontSize: 11)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildHistorySection(BuildContext context, WidgetRef ref, List<PeriodRange> ranges) {
    final revRanges = ranges.reversed.toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: FitoraColors.darkSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: FitoraColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Cycle History',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (ranges.isEmpty)
            const Text(
              'No logs yet.',
              style: TextStyle(color: FitoraColors.darkTextSecondary, fontSize: 13),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: revRanges.length,
              itemBuilder: (context, idx) {
                final range = revRanges[idx];
                
                // Calculate cycle length if there is a next period
                int? cycleLength;
                if (idx < revRanges.length - 1) {
                  final nextPeriod = revRanges[idx + 1];
                  cycleLength = range.startDate.difference(nextPeriod.startDate).inDays;
                }

                return Card(
                  color: FitoraColors.darkSurfaceVariant,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    title: Text(
                      '${_formatShortDate(range.startDate)} – ${range.endDate != null ? _formatShortDate(range.endDate!) : 'Ongoing'}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        'Period duration: ${range.durationDays} days'
                        '${cycleLength != null ? '  |  Cycle: $cycleLength days' : ''}',
                        style: const TextStyle(color: FitoraColors.darkTextSecondary, fontSize: 12),
                      ),
                    ),
                    trailing: const Icon(Icons.edit_rounded, color: FitoraColors.darkTextSecondary, size: 18),
                    onTap: () => _showEditPeriodDialog(context, ref, range),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildRecentSymptomsSection(BuildContext context, WidgetRef ref, Map<String, PeriodDayData> logs) {
    // Collect symptoms logged in the last 7 days
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    final List<MapEntry<String, PeriodDayData>> recentLogs = [];
    for (int i = 0; i < 7; i++) {
      final targetDate = today.subtract(Duration(days: i));
      final key = formatLocalDate(targetDate);
      final log = logs[key];
      if (log != null && (log.flow != null || log.symptoms.isNotEmpty)) {
        recentLogs.add(MapEntry(key, log));
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: FitoraColors.darkSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: FitoraColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Recent Symptoms (Last 7 Days)',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (recentLogs.isEmpty)
            const Text(
              'No symptoms logged in the last 7 days.',
              style: TextStyle(color: FitoraColors.darkTextSecondary, fontSize: 13),
            )
          else
            Column(
              children: recentLogs.map((entry) {
                final date = parseLocalDate(entry.key);
                final log = entry.value;
                final symptomsText = log.symptoms.isNotEmpty
                    ? log.symptoms.map((s) => s.displayName).join(', ')
                    : 'No symptoms';
                final flowText = log.flow != null ? 'Flow: ${log.flow!.displayName}' : null;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${date.day} ${_getMonthAbbr(date.month)}:',
                        style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (flowText != null)
                              Text(flowText, style: const TextStyle(color: FitoraColors.softPink, fontSize: 12, fontWeight: FontWeight.bold)),
                            Text(symptomsText, style: const TextStyle(color: FitoraColors.darkTextSecondary, fontSize: 12)),
                            if (log.notes != null && log.notes!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2.0),
                                child: Text('"${log.notes}"', style: const TextStyle(color: FitoraColors.darkTextSecondary, fontStyle: FontStyle.italic, fontSize: 11)),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  String _formatShortDate(DateTime date) {
    return '${date.day} ${_getMonthAbbr(date.month)}';
  }

  String _formatLongDate(DateTime date) {
    return '${date.day} ${_getMonthName(date.month)} ${date.year}';
  }

  String _getMonthAbbr(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
}

class _CycleSettingsBottomSheet extends ConsumerWidget {
  const _CycleSettingsBottomSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tt = theme.textTheme;
    final state = ref.watch(cycleProvider);
    final notifier = ref.read(cycleProvider.notifier);

    return Container(
      margin: const EdgeInsets.all(16),
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
                color: Colors.white24,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          Text(
            'Cycle Settings',
            style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 20),
          SwitchListTile.adaptive(
            title: const Text('Enable Cycle Tracking', style: TextStyle(color: Colors.white)),
            subtitle: const Text('Show cycle summary cards and track periods', style: TextStyle(color: FitoraColors.darkTextSecondary, fontSize: 12)),
            value: state.cycleTrackingEnabled,
            activeColor: FitoraColors.softPink,
            onChanged: (val) => notifier.toggleCycleTracking(val),
          ),
          SwitchListTile.adaptive(
            title: const Text('Period Reminders', style: TextStyle(color: Colors.white)),
            subtitle: const Text('Opt-in to local estimation notifications', style: TextStyle(color: FitoraColors.darkTextSecondary, fontSize: 12)),
            value: state.remindersEnabled,
            activeColor: FitoraColors.softPink,
            onChanged: state.cycleTrackingEnabled ? (val) => notifier.toggleReminders(val) : null,
          ),
          ListTile(
            title: const Text('Reminder Timing', style: TextStyle(color: Colors.white)),
            subtitle: Text('Notify ${state.reminderDaysBefore} days before expected start', style: const TextStyle(color: FitoraColors.darkTextSecondary, fontSize: 12)),
            trailing: DropdownButton<int>(
              dropdownColor: FitoraColors.darkSurface,
              value: state.reminderDaysBefore,
              items: [1, 2, 3, 5].map((d) {
                return DropdownMenuItem(
                  value: d,
                  child: Text('$d days prior', style: const TextStyle(color: Colors.white)),
                );
              }).toList(),
              onChanged: state.cycleTrackingEnabled && state.remindersEnabled
                  ? (val) {
                      if (val != null) notifier.setReminderDaysBefore(val);
                    }
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: FitoraColors.darkBorder),
          TextButton(
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: FitoraColors.darkSurface,
                  title: const Text('Reset All Cycle Data?', style: TextStyle(color: Colors.white)),
                  content: const Text('This will delete all period ranges and daily logs permanently from this device.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Reset', style: TextStyle(color: FitoraColors.errorRed)),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await notifier.clearAllData();
                if (context.mounted) Navigator.of(context).pop();
              }
            },
            child: const Text('Clear All Cycle Logs', style: TextStyle(color: FitoraColors.errorRed, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
