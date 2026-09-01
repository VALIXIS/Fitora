import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitora/core/storage/app_preferences.dart';
import 'package:fitora/core/services/notification_service.dart';
import 'package:fitora/features/cycle/domain/cycle_models.dart';
import 'package:fitora/features/personalization/data/personalization_local_data_source.dart';
import 'package:fitora/features/personalization/domain/personalization_models.dart';

class CycleState {
  final List<PeriodRange> periodRanges;
  final Map<String, PeriodDayData> dayLogs;
  final bool cycleTrackingEnabled;
  final bool remindersEnabled;
  final int reminderDaysBefore;

  const CycleState({
    required this.periodRanges,
    required this.dayLogs,
    this.cycleTrackingEnabled = false,
    this.remindersEnabled = false,
    this.reminderDaysBefore = 2,
  });

  CycleState copyWith({
    List<PeriodRange>? periodRanges,
    Map<String, PeriodDayData>? dayLogs,
    bool? cycleTrackingEnabled,
    bool? remindersEnabled,
    int? reminderDaysBefore,
  }) {
    return CycleState(
      periodRanges: periodRanges ?? this.periodRanges,
      dayLogs: dayLogs ?? this.dayLogs,
      cycleTrackingEnabled: cycleTrackingEnabled ?? this.cycleTrackingEnabled,
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
      reminderDaysBefore: reminderDaysBefore ?? this.reminderDaysBefore,
    );
  }
}

final cycleProvider = StateNotifierProvider<CycleNotifier, CycleState>((ref) {
  return CycleNotifier(ref);
});

class CycleNotifier extends StateNotifier<CycleState> {
  final Ref _ref;
  static const String _keyRanges = 'fitora_cycle_ranges';
  static const String _keyDayLogs = 'fitora_cycle_day_logs';
  static const String _keySettings = 'fitora_cycle_settings';

  Future<void>? loadFuture;

  CycleNotifier(this._ref)
      : super(const CycleState(periodRanges: [], dayLogs: {})) {
    loadFuture = load();
  }

  Future<void> load() async {
    final prefs = await AppPreferences.instance();

    // 1. Load Ranges
    final String? rangesJson = prefs.getString(_keyRanges);
    List<PeriodRange> ranges = [];
    if (rangesJson != null && rangesJson.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(rangesJson);
        ranges = decoded.map((item) => PeriodRange.fromJson(item as Map<String, dynamic>)).toList();
        ranges.sort((a, b) => a.startDate.compareTo(b.startDate));
      } catch (_) {}
    }

    // 2. Load Day Logs
    final String? dayLogsJson = prefs.getString(_keyDayLogs);
    Map<String, PeriodDayData> logs = {};
    if (dayLogsJson != null && dayLogsJson.isNotEmpty) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(dayLogsJson);
        logs = decoded.map((key, val) => MapEntry(key, PeriodDayData.fromJson(val as Map<String, dynamic>)));
      } catch (_) {}
    }

    // 3. Load Settings
    final String? settingsJson = prefs.getString(_keySettings);
    bool enabled = false;
    bool reminders = false;
    int daysBefore = 2;
    if (settingsJson != null && settingsJson.isNotEmpty) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(settingsJson);
        enabled = decoded['cycleTrackingEnabled'] as bool? ?? false;
        reminders = decoded['remindersEnabled'] as bool? ?? false;
        daysBefore = decoded['reminderDaysBefore'] as int? ?? 2;
      } catch (_) {}
    } else {
      // Check personalization profile for existing focus (onboarding selection or upgrade fallback)
      try {
        final personalDS = PersonalizationLocalDataSource();
        final completed = await personalDS.isCompleted();
        if (completed) {
          final profile = await personalDS.fetchProfile();
          if (profile != null) {
            enabled = profile.interests.contains(WellnessInterest.cycleTracking);
            reminders = enabled;
          }
        }
      } catch (_) {}
    }

    state = CycleState(
      periodRanges: ranges,
      dayLogs: logs,
      cycleTrackingEnabled: enabled,
      remindersEnabled: reminders,
      reminderDaysBefore: daysBefore,
    );

    _rescheduleReminders();
  }

  Future<void> _save() async {
    final prefs = await AppPreferences.instance();

    // Save Ranges
    final List<Map<String, dynamic>> rangesJson = state.periodRanges.map((r) => r.toJson()).toList();
    await prefs.setString(_keyRanges, jsonEncode(rangesJson));

    // Save Day Logs
    final Map<String, Map<String, dynamic>> dayLogsJson = state.dayLogs.map((key, val) => MapEntry(key, val.toJson()));
    await prefs.setString(_keyDayLogs, jsonEncode(dayLogsJson));

    // Save Settings
    final Map<String, dynamic> settingsJson = {
      'cycleTrackingEnabled': state.cycleTrackingEnabled,
      'remindersEnabled': state.remindersEnabled,
      'reminderDaysBefore': state.reminderDaysBefore,
    };
    await prefs.setString(_keySettings, jsonEncode(settingsJson));
  }

  // Check for any ongoing period
  PeriodRange? getOngoingPeriod() {
    try {
      return state.periodRanges.firstWhere((r) => r.endDate == null);
    } catch (_) {
      return null;
    }
  }

  // Check for overlapping period records
  bool hasOverlapConflict(DateTime start, DateTime? end, {String? excludeId}) {
    for (final range in state.periodRanges) {
      if (excludeId != null && range.id == excludeId) continue;
      
      // If there is overlap
      final rStart = range.startDate;
      final rEnd = range.endDate;

      if (rEnd == null) {
        // Ongoing range conflict check
        if (end == null) return true; // Two ongoing ranges always conflict
        if (end.isAfter(rStart) || end.isAtSameMomentAs(rStart)) return true;
      } else {
        if (end == null) {
          if (start.isBefore(rEnd) || start.isAtSameMomentAs(rEnd)) return true;
        } else {
          // Standard range intersection check
          if (!(end.isBefore(rStart) || start.isAfter(rEnd))) {
            return true;
          }
        }
      }
    }
    return false;
  }

  // Start a new period (no silent override)
  Future<bool> startPeriod(DateTime date, {bool forceResolve = false}) async {
    final ongoing = getOngoingPeriod();
    if (ongoing != null) {
      if (forceResolve) {
        await resolveConflictAndStartPeriod(date);
        return true;
      }
      return false; // Conflicting, UI must handle showing warning
    }

    if (hasOverlapConflict(date, null)) {
      return false; // Simple overlap conflict
    }

    final newRange = PeriodRange(
      id: '${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(1000000)}',
      startDate: date,
      endDate: null,
    );

    final updatedRanges = List<PeriodRange>.from(state.periodRanges)..add(newRange);
    updatedRanges.sort((a, b) => a.startDate.compareTo(b.startDate));

    state = state.copyWith(periodRanges: updatedRanges);
    await _save();
    _rescheduleReminders();
    return true;
  }

  // Resolve conflict: close ongoing period yesterday and start new one today
  Future<void> resolveConflictAndStartPeriod(DateTime newStartDate) async {
    final ongoing = getOngoingPeriod();
    if (ongoing == null) return;

    final updatedPrevious = ongoing.copyWith(
      endDate: newStartDate.subtract(const Duration(days: 1)),
    );

    final newPeriod = PeriodRange(
      id: '${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(1000000)}',
      startDate: newStartDate,
      endDate: null,
    );

    final updatedRanges = state.periodRanges.map((r) => r.id == ongoing.id ? updatedPrevious : r).toList();
    updatedRanges.add(newPeriod);
    updatedRanges.sort((a, b) => a.startDate.compareTo(b.startDate));

    state = state.copyWith(periodRanges: updatedRanges);
    await _save();
    _rescheduleReminders();
  }

  // Close the active period
  Future<bool> endPeriod(DateTime date) async {
    final ongoing = getOngoingPeriod();
    if (ongoing == null) return false;

    if (date.isBefore(ongoing.startDate)) {
      return false; // Validation error: end date before start
    }

    if (hasOverlapConflict(ongoing.startDate, date, excludeId: ongoing.id)) {
      return false; // Would overlap another range
    }

    final updated = ongoing.copyWith(endDate: date);
    final updatedRanges = state.periodRanges.map((r) => r.id == ongoing.id ? updated : r).toList();
    
    state = state.copyWith(periodRanges: updatedRanges);
    await _save();
    _rescheduleReminders();
    return true;
  }

  // Update an existing period range
  Future<bool> updatePeriod(PeriodRange range) async {
    if (range.endDate != null && range.endDate!.isBefore(range.startDate)) {
      return false;
    }

    if (hasOverlapConflict(range.startDate, range.endDate, excludeId: range.id)) {
      return false;
    }

    final updatedRanges = state.periodRanges.map((r) => r.id == range.id ? range : r).toList();
    updatedRanges.sort((a, b) => a.startDate.compareTo(b.startDate));

    state = state.copyWith(periodRanges: updatedRanges);
    await _save();
    _rescheduleReminders();
    return true;
  }

  // Delete a period record
  Future<void> deletePeriod(String id) async {
    final updatedRanges = state.periodRanges.where((r) => r.id != id).toList();
    state = state.copyWith(periodRanges: updatedRanges);
    await _save();
    _rescheduleReminders();
  }

  // Log daily symptoms and flow info
  Future<void> logDay(DateTime date, {FlowLevel? flow, List<CycleSymptom>? symptoms, String? notes}) async {
    final key = formatLocalDate(date);
    final dayLog = PeriodDayData(
      date: date,
      flow: flow,
      symptoms: symptoms ?? const [],
      notes: notes,
    );

    final updatedLogs = Map<String, PeriodDayData>.from(state.dayLogs);
    if (dayLog.isEmpty) {
      updatedLogs.remove(key);
    } else {
      updatedLogs[key] = dayLog;
    }

    state = state.copyWith(dayLogs: updatedLogs);
    await _save();
  }

  // Toggle cycle settings
  Future<void> toggleCycleTracking(bool enabled) async {
    state = state.copyWith(cycleTrackingEnabled: enabled);
    await _save();
    _rescheduleReminders();
  }

  Future<void> toggleReminders(bool enabled) async {
    state = state.copyWith(remindersEnabled: enabled);
    await _save();
    _rescheduleReminders();
  }

  Future<void> setReminderDaysBefore(int days) async {
    state = state.copyWith(reminderDaysBefore: days);
    await _save();
    _rescheduleReminders();
  }

  // Clear all data
  Future<void> clearAllData() async {
    state = const CycleState(
      periodRanges: [],
      dayLogs: {},
      cycleTrackingEnabled: true,
      remindersEnabled: true,
      reminderDaysBefore: 2,
    );
    await _save();
    _rescheduleReminders();
  }

  // Core calculations (pure logic derived dynamically)
  List<int> getCompletedCycleIntervals() {
    final List<int> lengths = [];
    final ranges = state.periodRanges;
    if (ranges.length < 2) return lengths;

    for (int i = 0; i < ranges.length - 1; i++) {
      final len = ranges[i+1].startDate.difference(ranges[i].startDate).inDays;
      if (len > 0) {
        lengths.add(len);
      }
    }
    return lengths;
  }

  CycleStats getStatistics() {
    final intervals = getCompletedCycleIntervals();
    if (intervals.isEmpty) return CycleStats.empty();

    // Use last 3 completed cycle lengths for average
    final recentIntervals = intervals.length > 3
        ? intervals.sublist(intervals.length - 3)
        : intervals;

    final double avgCycle = recentIntervals.reduce((a, b) => a + b) / recentIntervals.length;

    // Use period lengths of completed ranges
    final completedRanges = state.periodRanges
        .where((r) => r.endDate != null)
        .toList();
    
    final recentRanges = completedRanges.length > 3
        ? completedRanges.sublist(completedRanges.length - 3)
        : completedRanges;

    double avgPeriod = 0.0;
    if (recentRanges.isNotEmpty) {
      final totalPeriodDays = recentRanges.fold<int>(0, (sum, r) => sum + r.durationDays);
      avgPeriod = totalPeriodDays / recentRanges.length;
    }

    final int shortest = intervals.reduce((a, b) => a < b ? a : b);
    final int longest = intervals.reduce((a, b) => a > b ? a : b);

    // Std Dev of recent completed cycle lengths
    double varianceSum = 0.0;
    for (final val in recentIntervals) {
      varianceSum += (val - avgCycle) * (val - avgCycle);
    }
    final double stdDev = math.sqrt(varianceSum / recentIntervals.length);
    final double roundedStdDev = double.parse(stdDev.toStringAsFixed(1));

    return CycleStats(
      averageCycleLength: avgCycle,
      averagePeriodDuration: avgPeriod,
      shortestCycle: shortest,
      longestCycle: longest,
      cycleVariability: roundedStdDev,
      completedIntervalsCount: intervals.length,
    );
  }

  DateTime? getEstimatedNextPeriod() {
    final intervals = getCompletedCycleIntervals();
    if (intervals.length < 2 || state.periodRanges.isEmpty) return null;

    final stats = getStatistics();
    final latestStart = state.periodRanges.last.startDate;
    return latestStart.add(Duration(days: stats.averageCycleLength.round()));
  }

  int getCycleDay(DateTime date) {
    if (state.periodRanges.isEmpty) return 0;
    
    // Sort ranges and find the latest period that started on or before the given date
    final rangesBefore = state.periodRanges.where((r) => !r.startDate.isAfter(date)).toList();
    if (rangesBefore.isEmpty) return 0;

    final latestStart = rangesBefore.last.startDate;
    return date.difference(latestStart).inDays + 1;
  }

  void _rescheduleReminders() {
    final notificationService = _ref.read(notificationServiceProvider);
    
    // Cancel any existing cycle notifications
    for (int id = 600; id <= 650; id++) {
      notificationService.cancelCycleReminder(id);
    }

    if (!state.cycleTrackingEnabled || !state.remindersEnabled) return;

    final nextPeriod = getEstimatedNextPeriod();
    if (nextPeriod == null) return;

    // 1. "Period Approaching" reminder (daysBefore days before)
    final approachingDate = nextPeriod.subtract(Duration(days: state.reminderDaysBefore));
    final approachingDateTime = DateTime(approachingDate.year, approachingDate.month, approachingDate.day, 9, 0);

    notificationService.scheduleCycleReminder(
      id: 600,
      title: 'Estimated Period Approaching 🌸',
      body: 'Your period may be approaching in about ${state.reminderDaysBefore} days based on your cycle history.',
      date: approachingDateTime,
    );

    // 2. "Expected Today" reminder
    final expectedTodayDateTime = DateTime(nextPeriod.year, nextPeriod.month, nextPeriod.day, 8, 0);
    notificationService.scheduleCycleReminder(
      id: 601,
      title: 'Estimated Period Expected Today 🌸',
      body: 'Your period is expected today based on your cycle history.',
      date: expectedTodayDateTime,
    );
  }
}
