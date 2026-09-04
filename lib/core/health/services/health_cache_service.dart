import 'dart:convert';
import 'package:fitora/core/health/domain/health_models.dart';
import 'package:fitora/core/storage/local_database_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HealthCacheService {
  final SharedPreferences _prefs;
  final LocalDatabaseService _dbService;

  HealthCacheService(this._prefs, [LocalDatabaseService? dbService])
      : _dbService = dbService ?? LocalDatabaseService();

  static const _dailyActivityPrefix = 'cache_daily_activity_';
  static const _sleepSummaryPrefix = 'cache_sleep_summary_';
  static const _weeklyActivityKey = 'cache_weekly_activity';

  String _getDateKey(DateTime date) => '${date.year}_${date.month}_${date.day}';

  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  Future<void> saveDailyActivity(DailyActivitySummary summary) async {
    final key = '$_dailyActivityPrefix${_getDateKey(summary.date)}';
    await _prefs.setString(key, jsonEncode(summary.toJson()));

    // Persist into SQLite daily_logs database
    final dateStr = _formatDate(summary.date);
    await _dbService.upsertDailyLog(
      DailyLogRecord(
        date: dateStr,
        steps: summary.steps,
        caloriesBurned: summary.caloriesBurned,
        distanceKm: summary.distanceKm,
        activeMinutes: summary.activeMinutes,
      ),
    );
  }

  DailyActivitySummary? getDailyActivity(DateTime date) {
    final key = '$_dailyActivityPrefix${_getDateKey(date)}';
    final jsonStr = _prefs.getString(key);
    if (jsonStr != null) {
      try {
        return DailyActivitySummary.fromJson(jsonDecode(jsonStr));
      } catch (e) {
        _prefs.remove(key);
      }
    }
    return null;
  }

  Future<void> saveWeeklyActivity(List<DailyActivitySummary> summaries) async {
    final jsonList = summaries.map((s) => s.toJson()).toList();
    await _prefs.setString(_weeklyActivityKey, jsonEncode(jsonList));

    // Persist all summaries to SQLite
    for (final summary in summaries) {
      final dateStr = _formatDate(summary.date);
      await _dbService.upsertDailyLog(
        DailyLogRecord(
          date: dateStr,
          steps: summary.steps,
          caloriesBurned: summary.caloriesBurned,
          distanceKm: summary.distanceKm,
          activeMinutes: summary.activeMinutes,
        ),
      );
    }
  }

  List<DailyActivitySummary>? getWeeklyActivity() {
    final jsonStr = _prefs.getString(_weeklyActivityKey);
    if (jsonStr != null) {
      try {
        final List<dynamic> decoded = jsonDecode(jsonStr);
        return decoded
            .map((json) => DailyActivitySummary.fromJson(json))
            .toList();
      } catch (e) {
        _prefs.remove(_weeklyActivityKey);
      }
    }
    return null;
  }

  Future<void> saveSleepSummary(SleepSummary summary) async {
    final key = '$_sleepSummaryPrefix${_getDateKey(summary.date)}';
    await _prefs.setString(key, jsonEncode(summary.toJson()));

    // Update sleep_minutes in SQLite
    final dateStr = _formatDate(summary.date);
    await _dbService.upsertDailyLog(
      DailyLogRecord(
        date: dateStr,
        sleepMinutes: summary.totalSleep.inMinutes,
      ),
    );
  }

  SleepSummary? getSleepSummary(DateTime date) {
    final key = '$_sleepSummaryPrefix${_getDateKey(date)}';
    final jsonStr = _prefs.getString(key);
    if (jsonStr != null) {
      try {
        return SleepSummary.fromJson(jsonDecode(jsonStr));
      } catch (e) {
        _prefs.remove(key);
      }
    }
    return null;
  }

  bool getBgSyncEnabled() {
    return _prefs.getBool('fitora_health_bg_sync') ?? true;
  }

  int getBgSyncInterval() {
    return _prefs.getInt('fitora_health_bg_sync_interval') ?? 60;
  }
}
