import 'dart:convert';
import 'package:fitora/core/health/domain/health_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HealthCacheService {
  final SharedPreferences _prefs;

  HealthCacheService(this._prefs);

  static const _dailyActivityPrefix = 'cache_daily_activity_';
  static const _sleepSummaryPrefix = 'cache_sleep_summary_';
  static const _weeklyActivityKey = 'cache_weekly_activity';

  String _getDateKey(DateTime date) => '${date.year}_${date.month}_${date.day}';

  Future<void> saveDailyActivity(DailyActivitySummary summary) async {
    final key = '$_dailyActivityPrefix${_getDateKey(summary.date)}';
    await _prefs.setString(key, jsonEncode(summary.toJson()));
  }

  DailyActivitySummary? getDailyActivity(DateTime date) {
    final key = '$_dailyActivityPrefix${_getDateKey(date)}';
    final jsonStr = _prefs.getString(key);
    if (jsonStr != null) {
      try {
        return DailyActivitySummary.fromJson(jsonDecode(jsonStr));
      } catch (e) {
        // Corrupted cache
        _prefs.remove(key);
      }
    }
    return null;
  }

  Future<void> saveWeeklyActivity(List<DailyActivitySummary> summaries) async {
    final jsonList = summaries.map((s) => s.toJson()).toList();
    await _prefs.setString(_weeklyActivityKey, jsonEncode(jsonList));
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
        // Corrupted cache
        _prefs.remove(_weeklyActivityKey);
      }
    }
    return null;
  }

  Future<void> saveSleepSummary(SleepSummary summary) async {
    final key = '$_sleepSummaryPrefix${_getDateKey(summary.date)}';
    await _prefs.setString(key, jsonEncode(summary.toJson()));
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
}
