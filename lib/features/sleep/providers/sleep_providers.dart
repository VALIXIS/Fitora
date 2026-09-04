import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitora/core/health/domain/health_models.dart';
import 'package:fitora/core/health/providers/health_providers.dart';

/// Provider for a list of 7 sleep summaries ending on the given [endDate].
/// Reacts to health synchronization events.
final sleepHistoryProvider = Provider.family.autoDispose<List<SleepSummary>, DateTime>((ref, endDate) {
  ref.watch(healthSyncServiceProvider);
  final startDate = endDate.subtract(const Duration(days: 6));
  return List.generate(7, (i) {
    final date = startDate.add(Duration(days: i));
    return ref.watch(sleepSummaryProvider(date));
  });
});
