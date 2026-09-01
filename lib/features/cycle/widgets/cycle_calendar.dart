import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitora/core/theme/fitora_colors.dart';
import 'package:fitora/core/services/haptic_service.dart';
import 'package:fitora/features/cycle/domain/cycle_models.dart';
import 'package:fitora/features/cycle/providers/cycle_provider.dart';
import 'package:fitora/features/cycle/widgets/daily_log_modal.dart';

class CycleCalendar extends ConsumerStatefulWidget {
  const CycleCalendar({super.key});

  @override
  ConsumerState<CycleCalendar> createState() => _CycleCalendarState();
}

class _CycleCalendarState extends ConsumerState<CycleCalendar> {
  late DateTime _focusedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month, 1);
  }

  void _nextMonth() {
    ref.read(hapticServiceProvider).lightImpact();
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);
    });
  }

  void _prevMonth() {
    ref.read(hapticServiceProvider).lightImpact();
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
    });
  }

  int _daysInMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0).day;
  }

  int _firstWeekday(DateTime date) {
    // 1 = Monday, 7 = Sunday
    return DateTime(date.year, date.month, 1).weekday;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tt = theme.textTheme;
    final cycleState = ref.watch(cycleProvider);
    final cycleNotifier = ref.read(cycleProvider.notifier);

    final ranges = cycleState.periodRanges;
    final nextPeriodStart = cycleNotifier.getEstimatedNextPeriod();
    final stats = cycleNotifier.getStatistics();
    final estimatedDuration = stats.averagePeriodDuration > 0 ? stats.averagePeriodDuration.round() : 5;

    // Helper to check if a specific local date is inside a confirmed range
    bool isConfirmedPeriod(DateTime date) {
      for (final range in ranges) {
        final start = range.startDate;
        final end = range.endDate;
        if (end == null) {
          if (date.isAtSameMomentAs(start) || date.isAfter(start)) {
            final now = DateTime.now();
            final localToday = DateTime(now.year, now.month, now.day);
            if (date.isBefore(localToday) || date.isAtSameMomentAs(localToday)) {
              return true;
            }
          }
        } else {
          if ((date.isAfter(start) || date.isAtSameMomentAs(start)) &&
              (date.isBefore(end) || date.isAtSameMomentAs(end))) {
            return true;
          }
        }
      }
      return false;
    }

    // Helper to check if a specific local date falls inside estimated prediction range
    bool isEstimatedPeriod(DateTime date) {
      if (nextPeriodStart == null) return false;
      final nextPeriodEnd = nextPeriodStart.add(Duration(days: estimatedDuration - 1));
      return (date.isAfter(nextPeriodStart) || date.isAtSameMomentAs(nextPeriodStart)) &&
          (date.isBefore(nextPeriodEnd) || date.isAtSameMomentAs(nextPeriodEnd));
    }

    final totalDays = _daysInMonth(_focusedMonth);
    final startOffset = _firstWeekday(_focusedMonth) - 1; // Monday start
    final totalGridCells = totalDays + startOffset;

    final weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final now = DateTime.now();
    final localToday = DateTime(now.year, now.month, now.day);

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
          // Month navigation header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: _prevMonth,
                icon: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 28),
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              ),
              Text(
                '${_getMonthName(_focusedMonth.month)} ${_focusedMonth.year}',
                style: tt.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              IconButton(
                onPressed: _nextMonth,
                icon: const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 28),
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Weekday Labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekdays.map((label) {
              return SizedBox(
                width: 36,
                child: Center(
                  child: Text(
                    label,
                    style: tt.bodySmall?.copyWith(
                      color: FitoraColors.darkTextSecondary.withValues(alpha: 0.7),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),

          // Calendar Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: totalGridCells,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemBuilder: (context, index) {
              if (index < startOffset) {
                return const SizedBox.shrink();
              }

              final dayNum = index - startOffset + 1;
              final cellDate = DateTime(_focusedMonth.year, _focusedMonth.month, dayNum);
              final isToday = cellDate.isAtSameMomentAs(localToday);
              
              final confirmed = isConfirmedPeriod(cellDate);
              final estimated = !confirmed && isEstimatedPeriod(cellDate);

              // Styling flags
              Color? cellBg;
              BoxBorder? cellBorder;
              Color textColor = Colors.white;

              if (confirmed) {
                cellBg = FitoraColors.softPink;
                textColor = Colors.white;
              } else if (estimated) {
                cellBg = FitoraColors.softPink.withValues(alpha: 0.15);
                cellBorder = Border.all(color: FitoraColors.softPink, style: BorderStyle.solid, width: 1.5);
                textColor = FitoraColors.softPink;
              } else if (isToday) {
                cellBg = FitoraColors.mintGreen.withValues(alpha: 0.2);
                cellBorder = Border.all(color: FitoraColors.mintGreen, width: 1.5);
                textColor = Colors.white;
              }

              final key = formatLocalDate(cellDate);
              final hasLogDetails = cycleState.dayLogs.containsKey(key);

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    ref.read(hapticServiceProvider).lightImpact();
                    DailyLogModal.show(context, cellDate);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: cellBg ?? FitoraColors.darkSurfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      border: cellBorder,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          '$dayNum',
                          style: TextStyle(
                            color: textColor,
                            fontWeight: (confirmed || estimated || isToday) ? FontWeight.bold : FontWeight.normal,
                            fontSize: 14,
                          ),
                        ),
                        if (hasLogDetails && !confirmed)
                          Positioned(
                            bottom: 4,
                            child: Container(
                              width: 5,
                              height: 5,
                              decoration: const BoxDecoration(
                                color: FitoraColors.mintGreen,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),

          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLegendItem(
                color: FitoraColors.softPink,
                label: 'Period (Logged)',
                isEstimated: false,
              ),
              _buildLegendItem(
                color: FitoraColors.softPink.withValues(alpha: 0.15),
                borderColor: FitoraColors.softPink,
                label: 'Prediction (Est.)',
                isEstimated: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({
    required Color color,
    Color? borderColor,
    required String label,
    required bool isEstimated,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: borderColor != null ? Border.all(color: borderColor, width: 1.2) : null,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: FitoraColors.darkTextSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
}
