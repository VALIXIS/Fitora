import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitora/core/constants/storage_keys.dart';
import 'package:fitora/core/storage/app_preferences.dart';
import 'package:fitora/features/progress/domain/progress_models.dart';

final progressLocalDataSourceProvider = Provider<ProgressLocalDataSource>((
  ref,
) {
  return ProgressLocalDataSource();
});

class ProgressLocalDataSource {
  Future<List<WorkoutHistoryEntry>> fetchHistory() async {
    final prefs = await AppPreferences.instance();
    final raw = prefs.getString(StorageKeys.progressHistory);
    if (raw == null || raw.isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return [];
      }
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(WorkoutHistoryEntry.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveHistory(List<WorkoutHistoryEntry> history) async {
    final prefs = await AppPreferences.instance();
    final encoded = jsonEncode(history.map((e) => e.toJson()).toList());
    await prefs.setString(StorageKeys.progressHistory, encoded);
  }
}
