import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fitora/core/theme/fitora_colors.dart';
import 'package:fitora/core/constants/spacing.dart';
import 'package:fitora/core/health/domain/health_models.dart';
import 'package:fitora/core/health/providers/health_providers.dart';
import 'package:fitora/features/sleep/providers/sleep_providers.dart';
import 'package:fitora/features/settings/providers/settings_provider.dart';
import 'package:fitora/core/health/domain/sleep_calculations.dart';
import 'package:fitora/app/router/app_routes.dart';
import 'package:fitora/features/sleep/widgets/log_sleep_modal.dart';

class SleepDetailScreen extends ConsumerStatefulWidget {
  const SleepDetailScreen({super.key});

  @override
  ConsumerState<SleepDetailScreen> createState() => _SleepDetailScreenState();
}

class _SleepDetailScreenState extends ConsumerState<SleepDetailScreen> {
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    // Default selected day is today
    final now = DateTime.now();
    _selectedDay = DateTime(now.year, now.month, now.day);
  }

  void _navigateDay(int offset) {
    final newDate = _selectedDay.add(Duration(days: offset));
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (newDate.isAfter(today)) return; // Prevents navigating to future

    setState(() {
      _selectedDay = newDate;
    });
  }

  String _getDateHeaderString(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (date == today) {
      return 'Today, ${DateFormat('MMM d').format(date)}';
    } else if (date == yesterday) {
      return 'Yesterday, ${DateFormat('MMM d').format(date)}';
    } else {
      return DateFormat('EEEE, MMM d').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final sleep = ref.watch(sleepSummaryProvider(_selectedDay));
    final history = ref.watch(sleepHistoryProvider(_selectedDay));
    final settings = ref.watch(settingsProvider);
    final status = ref.watch(healthConnectStatusProvider);

    final hasSleepData = sleep.totalSleep.inMinutes > 0;

    final targetBedHour = settings.sleepTargetBedtimeHour;
    final targetBedMinute = settings.sleepTargetBedtimeMinute;
    final targetWakeHour = settings.sleepTargetWakeHour;
    final targetWakeMinute = settings.sleepTargetWakeMinute;
    final targetDuration = settings.sleepTargetDurationMinutes;

    final averageDuration = SleepCalculations.calculate7DayAverage(history);
    final validDaysCount = history.where((s) => s.totalSleep.inMinutes > 0).length;
    final achievedCount = SleepCalculations.countAchievedDays(
      history,
      targetBedHour,
      targetBedMinute,
      targetWakeHour,
      targetWakeMinute,
    );

    final guidance = SleepCalculations.generateBedtimeGuidance(
      summaries: history,
      targetDurationMinutes: targetDuration,
      targetBedHour: targetBedHour,
      targetBedMinute: targetBedMinute,
      targetWakeHour: targetWakeHour,
      targetWakeMinute: targetWakeMinute,
    );

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Semantics(
          button: true,
          label: 'Back',
          child: IconButton(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.pop(),
          ),
        ),
        title: Text(
          'Sleep Tracker',
          style: tt.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: FitoraSpacing.xl, vertical: FitoraSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Date Navigation Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Semantics(
                  button: true,
                  label: 'Previous day',
                  child: IconButton(
                    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                    icon: const Icon(Icons.chevron_left, color: Colors.white),
                    onPressed: () => _navigateDay(-1),
                  ),
                ),
                Text(
                  _getDateHeaderString(_selectedDay),
                  style: tt.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Semantics(
                  button: true,
                  label: 'Next day',
                  child: IconButton(
                    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                    icon: Icon(
                      Icons.chevron_right,
                      color: _selectedDay == today ? Colors.white24 : Colors.white,
                    ),
                    onPressed: _selectedDay == today ? null : () => _navigateDay(1),
                  ),
                ),
              ],
            ),
            SizedBox(height: FitoraSpacing.lg),

            // Sleep Duration Dial card
            _buildSleepDurationCard(tt, sleep, targetDuration, hasSleepData, status),
            SizedBox(height: FitoraSpacing.lg),

            // 7-Day Sleep History Chart
            _buildHistoryChartCard(tt, history, averageDuration, targetDuration),
            SizedBox(height: FitoraSpacing.lg),

            // Sleep Consistency Tracker
            _buildConsistencyCard(
              tt,
              history,
              achievedCount,
              validDaysCount,
              targetBedHour,
              targetBedMinute,
              targetWakeHour,
              targetWakeMinute,
            ),
            SizedBox(height: FitoraSpacing.lg),

            // Bedtime Guidance
            _buildGuidanceCard(tt, guidance),
            SizedBox(height: FitoraSpacing.lg),

            // Target sleep configurations card
            _buildTargetConfigurationCard(tt, targetBedHour, targetBedMinute, targetWakeHour, targetWakeMinute, targetDuration),
            SizedBox(height: FitoraSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildSleepDurationCard(
    TextTheme tt,
    SleepSummary sleep,
    int targetDurationMinutes,
    bool hasSleepData,
    HealthConnectStatus status,
  ) {
    final hours = sleep.totalSleep.inHours;
    final minutes = sleep.totalSleep.inMinutes.remainder(60);
    final progress = (sleep.totalSleep.inMinutes / targetDurationMinutes).clamp(0.0, 1.0);

    return Container(
      padding: EdgeInsets.all(FitoraSpacing.xl),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SLEEP TIME',
                style: tt.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: Colors.white54,
                ),
              ),
              if (hasSleepData)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: FitoraColors.calmCyan.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: FitoraColors.calmCyan.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    'RECORDED',
                    style: tt.labelSmall?.copyWith(
                      color: FitoraColors.calmCyan,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: FitoraSpacing.xl),
          if (!hasSleepData) ...[
            const Icon(Icons.bedtime_outlined, size: 48, color: FitoraColors.calmCyan),
            SizedBox(height: FitoraSpacing.md),
            Text(
              'No sleep logged for this night',
              style: tt.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: FitoraSpacing.xs),
            Text(
              'Log how many hours you slept or set your target sleep schedule dial.',
              style: tt.bodySmall?.copyWith(color: Colors.white54),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: FitoraSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => showSleepLogModal(context, ref),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Log Sleep'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FitoraColors.calmCyan,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () => context.pushNamed(AppRouteNames.sleepSchedule),
                  icon: const Icon(Icons.access_time_rounded, size: 18),
                  label: const Text('Target Schedule Dial'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: FitoraColors.calmCyan,
                    side: const BorderSide(color: FitoraColors.calmCyan),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                  ),
                ),
              ],
            ),
          ] else ...[
            Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 90,
                      height: 90,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 8,
                        backgroundColor: Colors.white.withValues(alpha: 0.05),
                        valueColor: const AlwaysStoppedAnimation<Color>(FitoraColors.calmCyan),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: tt.titleLarge?.copyWith(
                        color: FitoraColors.calmCyan,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                SizedBox(width: FitoraSpacing.xl),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${hours}h ${minutes}m',
                        style: tt.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (sleep.startTime != null && sleep.endTime != null)
                        Text(
                          '${DateFormat('HH:mm').format(sleep.startTime!)} - ${DateFormat('HH:mm').format(sleep.endTime!)}',
                          style: tt.bodyMedium?.copyWith(
                            color: Colors.white54,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHistoryChartCard(
    TextTheme tt,
    List<SleepSummary> history,
    Duration averageDuration,
    int targetDurationMinutes,
  ) {
    final maxMinutes = history.fold<int>(
      60,
      (curr, s) => s.totalSleep.inMinutes > curr ? s.totalSleep.inMinutes : curr,
    );
    final maxValChecked = maxMinutes == 0 ? 60.0 : maxMinutes.toDouble();

    return Container(
      padding: EdgeInsets.all(FitoraSpacing.xl),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SLEEP HISTORY',
                style: tt.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: Colors.white54,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '7-day Average',
                    style: tt.labelSmall?.copyWith(color: Colors.white30),
                  ),
                  Text(
                    '${averageDuration.inHours}h ${averageDuration.inMinutes.remainder(60)}m',
                    style: tt.titleMedium?.copyWith(
                      color: FitoraColors.calmCyan,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: FitoraSpacing.xl),
          // Chart Layout
          SizedBox(
            height: 140,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (index) {
                final summary = history[index];
                final val = summary.totalSleep.inMinutes.toDouble();
                final heightRatio = (val / maxValChecked).clamp(0.04, 1.0);
                final isSelected = summary.date.day == _selectedDay.day &&
                    summary.date.month == _selectedDay.month &&
                    summary.date.year == _selectedDay.year;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (val > 0)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '${summary.totalSleep.inHours}h',
                              style: tt.labelSmall?.copyWith(
                                color: isSelected ? FitoraColors.calmCyan : Colors.white38,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        Container(
                          height: 100 * heightRatio,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isSelected
                                  ? [FitoraColors.calmCyan, FitoraColors.calmCyan.withValues(alpha: 0.6)]
                                  : (val > 0
                                      ? [Colors.white24, Colors.white10]
                                      : [Colors.transparent, Colors.transparent]),
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            border: val == 0
                                ? Border.all(color: Colors.white12, style: BorderStyle.solid)
                                : null,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          DateFormat('E').format(summary.date).substring(0, 1),
                          style: tt.labelSmall?.copyWith(
                            color: isSelected ? FitoraColors.calmCyan : Colors.white38,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsistencyCard(
    TextTheme tt,
    List<SleepSummary> history,
    int achievedCount,
    int validDaysCount,
    int targetBedHour,
    int targetBedMinute,
    int targetWakeHour,
    int targetWakeMinute,
  ) {
    return Container(
      padding: EdgeInsets.all(FitoraSpacing.xl),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SLEEP CONSISTENCY',
            style: tt.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              color: Colors.white54,
            ),
          ),
          SizedBox(height: FitoraSpacing.md),
          Text(
            validDaysCount > 0
                ? 'Target achieved $achievedCount out of $validDaysCount recorded days'
                : 'No sleep data recorded in the last 7 days.',
            style: tt.bodyMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: FitoraSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final summary = history[index];
              final dateLabel = DateFormat('E').format(summary.date).substring(0, 1);
              final isRecorded = summary.totalSleep.inMinutes > 0;
              final isAchieved = isRecorded &&
                  SleepCalculations.isScheduleAchieved(
                    summary.startTime,
                    summary.endTime,
                    targetBedHour,
                    targetBedMinute,
                    targetWakeHour,
                    targetWakeMinute,
                  );

              Color indicatorColor = Colors.white10;
              Widget icon = const SizedBox.shrink();

              if (isRecorded) {
                if (isAchieved) {
                  indicatorColor = FitoraColors.mintGreen.withValues(alpha: 0.1);
                  icon = const Icon(Icons.check, color: FitoraColors.mintGreen, size: 14);
                } else {
                  indicatorColor = FitoraColors.errorRed.withValues(alpha: 0.1);
                  icon = const Icon(Icons.close, color: FitoraColors.errorRed, size: 14);
                }
              }

              return Column(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: indicatorColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isRecorded
                            ? (isAchieved ? FitoraColors.mintGreen : FitoraColors.errorRed)
                            : Colors.white12,
                        width: 1.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: icon,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    dateLabel,
                    style: tt.labelSmall?.copyWith(color: Colors.white30),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildGuidanceCard(TextTheme tt, String guidance) {
    return Container(
      padding: EdgeInsets.all(FitoraSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            FitoraColors.calmCyan.withValues(alpha: 0.08),
            FitoraColors.calmCyan.withValues(alpha: 0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: FitoraColors.calmCyan.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: FitoraColors.calmCyan, size: 18),
              const SizedBox(width: 8),
              Text(
                'BEDTIME GUIDANCE',
                style: tt.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: FitoraColors.calmCyan,
                ),
              ),
            ],
          ),
          SizedBox(height: FitoraSpacing.md),
          Text(
            guidance,
            style: tt.bodyMedium?.copyWith(
              color: Colors.white70,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetConfigurationCard(
    TextTheme tt,
    int bedHour,
    int bedMinute,
    int wakeHour,
    int wakeMinute,
    int durationMinutes,
  ) {
    final durHours = durationMinutes ~/ 60;
    final durMin = durationMinutes % 60;

    return Container(
      padding: EdgeInsets.all(FitoraSpacing.xl),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'SLEEP TARGETS',
            style: tt.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              color: Colors.white54,
            ),
          ),
          SizedBox(height: FitoraSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bedtime Target',
                    style: tt.labelSmall?.copyWith(color: Colors.white30),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    SleepCalculations.formatTimeOfDay(bedHour, bedMinute),
                    style: tt.bodyLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Wakeup Target',
                    style: tt.labelSmall?.copyWith(color: Colors.white30),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    SleepCalculations.formatTimeOfDay(wakeHour, wakeMinute),
                    style: tt.bodyLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Duration Goal',
                    style: tt.labelSmall?.copyWith(color: Colors.white30),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${durHours}h${durMin > 0 ? ' ${durMin}m' : ''}',
                    style: tt.bodyLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: FitoraSpacing.xl),
          ElevatedButton(
            onPressed: () => context.push('/progress/sleep-detail/schedule'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Colors.white12),
              ),
            ),
            child: const Text(
              'Change Sleep Target Schedule',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
