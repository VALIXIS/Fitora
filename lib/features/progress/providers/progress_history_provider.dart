import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fitora/core/theme/fitora_colors.dart';
import 'package:fitora/core/services/haptic_service.dart';
import 'package:fitora/features/wellness/providers/wellness_provider.dart';

enum LogCategory {
  all,
  steps,
  sleep,
  water,
  mood;

  String get label {
    switch (this) {
      case LogCategory.all:
        return 'All';
      case LogCategory.steps:
        return 'Steps';
      case LogCategory.sleep:
        return 'Sleep';
      case LogCategory.water:
        return 'Water';
      case LogCategory.mood:
        return 'Mood';
    }
  }

  IconData get icon {
    switch (this) {
      case LogCategory.all:
        return Icons.list_alt_rounded;
      case LogCategory.steps:
        return Icons.directions_walk_rounded;
      case LogCategory.sleep:
        return Icons.bedtime_rounded;
      case LogCategory.water:
        return Icons.water_drop_rounded;
      case LogCategory.mood:
        return Icons.sentiment_satisfied_alt_rounded;
    }
  }

  Color get color {
    switch (this) {
      case LogCategory.all:
        return FitoraColors.mintGreen;
      case LogCategory.steps:
        return FitoraColors.mintGreen;
      case LogCategory.sleep:
        return FitoraColors.calmCyan;
      case LogCategory.water:
        return Colors.blueAccent;
      case LogCategory.mood:
        return FitoraColors.lavender;
    }
  }
}

class LoggedHistoryEntry {
  final String id;
  final LogCategory category;
  final String title;
  final String displayValue;
  final double numericValue;
  final String unit;
  final DateTime timestamp;
  final String? details;

  const LoggedHistoryEntry({
    required this.id,
    required this.category,
    required this.title,
    required this.displayValue,
    required this.numericValue,
    required this.unit,
    required this.timestamp,
    this.details,
  });

  LoggedHistoryEntry copyWith({
    String? id,
    LogCategory? category,
    String? title,
    String? displayValue,
    double? numericValue,
    String? unit,
    DateTime? timestamp,
    String? details,
  }) {
    return LoggedHistoryEntry(
      id: id ?? this.id,
      category: category ?? this.category,
      title: title ?? this.title,
      displayValue: displayValue ?? this.displayValue,
      numericValue: numericValue ?? this.numericValue,
      unit: unit ?? this.unit,
      timestamp: timestamp ?? this.timestamp,
      details: details ?? this.details,
    );
  }
}

class ProgressHistoryState {
  final LogCategory selectedCategory;
  final String searchQuery;
  final List<LoggedHistoryEntry> customLogs;
  final Map<String, List<LoggedHistoryEntry>> groupedLogs;
  final double weeklyAverageSteps;
  final double weeklyAverageSleepHours;
  final double weeklyAverageWaterLiters;
  final double moodPositivityScore;

  const ProgressHistoryState({
    required this.selectedCategory,
    required this.searchQuery,
    required this.customLogs,
    required this.groupedLogs,
    required this.weeklyAverageSteps,
    required this.weeklyAverageSleepHours,
    required this.weeklyAverageWaterLiters,
    required this.moodPositivityScore,
  });

  factory ProgressHistoryState.initial() {
    return const ProgressHistoryState(
      selectedCategory: LogCategory.all,
      searchQuery: '',
      customLogs: [],
      groupedLogs: {},
      weeklyAverageSteps: 0.0,
      weeklyAverageSleepHours: 0.0,
      weeklyAverageWaterLiters: 0.0,
      moodPositivityScore: 0.0,
    );
  }

  ProgressHistoryState copyWith({
    LogCategory? selectedCategory,
    String? searchQuery,
    List<LoggedHistoryEntry>? customLogs,
    Map<String, List<LoggedHistoryEntry>>? groupedLogs,
    double? weeklyAverageSteps,
    double? weeklyAverageSleepHours,
    double? weeklyAverageWaterLiters,
    double? moodPositivityScore,
  }) {
    return ProgressHistoryState(
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
      customLogs: customLogs ?? this.customLogs,
      groupedLogs: groupedLogs ?? this.groupedLogs,
      weeklyAverageSteps: weeklyAverageSteps ?? this.weeklyAverageSteps,
      weeklyAverageSleepHours:
          weeklyAverageSleepHours ?? this.weeklyAverageSleepHours,
      weeklyAverageWaterLiters:
          weeklyAverageWaterLiters ?? this.weeklyAverageWaterLiters,
      moodPositivityScore: moodPositivityScore ?? this.moodPositivityScore,
    );
  }
}

final progressHistoryProvider = StateNotifierProvider<
  ProgressHistoryNotifier,
  ProgressHistoryState
>((ref) {
  return ProgressHistoryNotifier(ref);
});

class ProgressHistoryNotifier extends StateNotifier<ProgressHistoryState> {
  final Ref _ref;
  final Set<String> _deletedIds = {};

  ProgressHistoryNotifier(this._ref) : super(ProgressHistoryState.initial()) {
    _loadInitialData();
  }

  void _loadInitialData() {
    _refreshLogsAndStats();
  }

  void setCategory(LogCategory category) {
    state = state.copyWith(selectedCategory: category);
    _refreshLogsAndStats();
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query.trim().toLowerCase());
    _refreshLogsAndStats();
  }

  void refresh() {
    _refreshLogsAndStats();
  }

  List<LoggedHistoryEntry> _buildBaseLogs() {
    final now = DateTime.now();
    final wellnessState = _ref.read(wellnessProvider);
    final List<LoggedHistoryEntry> entries = [];

    // 1. Water Logs
    for (final waterEntry in wellnessState.waterLogs) {
      if (_deletedIds.contains(waterEntry.id)) continue;
      entries.add(
        LoggedHistoryEntry(
          id: waterEntry.id,
          category: LogCategory.water,
          title: 'Water Hydration',
          displayValue: '${waterEntry.amountMl} ml',
          numericValue: waterEntry.amountMl / 1000.0,
          unit: 'L',
          timestamp: waterEntry.timestamp,
          details: 'Hydration log',
        ),
      );
    }

    // 2. Sleep Logs
    wellnessState.sleepLogHistory.forEach((dateStr, minutes) {
      final id = 'sleep_$dateStr';
      if (_deletedIds.contains(id)) return;
      try {
        final dateParts = dateStr.split('-');
        if (dateParts.length == 3) {
          final dt = DateTime(
            int.parse(dateParts[0]),
            int.parse(dateParts[1]),
            int.parse(dateParts[2]),
            8,
            0,
          );
          final hours = minutes / 60.0;
          final score = wellnessState.sleepScoreHistory[dateStr] ?? 80;
          entries.add(
            LoggedHistoryEntry(
              id: id,
              category: LogCategory.sleep,
              title: 'Night Sleep Log',
              displayValue: '${hours.toStringAsFixed(1)} hrs',
              numericValue: hours,
              unit: 'hrs',
              timestamp: dt,
              details: 'Sleep Quality: $score%',
            ),
          );
        }
      } catch (_) {}
    });

    // 3. Mood Logs
    wellnessState.loggedMoods.forEach((dateStr, mood) {
      final id = 'mood_$dateStr';
      if (_deletedIds.contains(id)) return;
      try {
        final dateParts = dateStr.split('-');
        if (dateParts.length == 3) {
          final dt = DateTime(
            int.parse(dateParts[0]),
            int.parse(dateParts[1]),
            int.parse(dateParts[2]),
            12,
            0,
          );
          entries.add(
            LoggedHistoryEntry(
              id: id,
              category: LogCategory.mood,
              title: 'Daily Mood Log',
              displayValue: mood,
              numericValue: 1.0,
              unit: 'score',
              timestamp: dt,
              details: 'Mood Check-in: $mood',
            ),
          );
        }
      } catch (_) {}
    });

    // 4. Default Steps Entries (Past 7 Days default baseline)
    for (int i = 0; i < 7; i++) {
      final dt = now.subtract(Duration(days: i));
      final dateStr =
          '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      final id = 'step_$dateStr';
      if (_deletedIds.contains(id)) continue;
      
      // Calculate realistic baseline steps for demo/history
      final stepCount = i == 0 ? 8450 : 7200 + (i * 350) % 3100;
      entries.add(
        LoggedHistoryEntry(
          id: id,
          category: LogCategory.steps,
          title: i == 0 ? "Today's Step Count" : "Daily Steps Log",
          displayValue: '$stepCount steps',
          numericValue: stepCount.toDouble(),
          unit: 'steps',
          timestamp: DateTime(dt.year, dt.month, dt.day, 20, 0),
          details: 'Pedometer auto-sync',
        ),
      );
    }

    // Add custom/modified logs
    for (final custom in state.customLogs) {
      if (!_deletedIds.contains(custom.id)) {
        entries.add(custom);
      }
    }

    // Sort descending by timestamp
    entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return entries;
  }

  void _refreshLogsAndStats() {
    final allEntries = _buildBaseLogs();

    // Filter by selected category & search query
    final filtered = allEntries.where((entry) {
      if (state.selectedCategory != LogCategory.all &&
          entry.category != state.selectedCategory) {
        return false;
      }
      if (state.searchQuery.isNotEmpty) {
        final q = state.searchQuery;
        final matchesTitle = entry.title.toLowerCase().contains(q);
        final matchesVal = entry.displayValue.toLowerCase().contains(q);
        final matchesCat = entry.category.label.toLowerCase().contains(q);
        final matchesDetails =
            entry.details?.toLowerCase().contains(q) ?? false;
        if (!matchesTitle && !matchesVal && !matchesCat && !matchesDetails) {
          return false;
        }
      }
      return true;
    }).toList();

    // Date-grouped map: Key is "YYYY-MM-DD" or formatted date header
    final Map<String, List<LoggedHistoryEntry>> grouped = {};
    for (final entry in filtered) {
      final dateHeader = _formatDateHeader(entry.timestamp);
      grouped.putIfAbsent(dateHeader, () => []).add(entry);
    }

    // Recalculate Averages from active logs
    double totalSteps = 0;
    int stepDays = 0;
    double totalSleepMinutes = 0;
    int sleepDays = 0;
    double totalWaterLiters = 0;
    int waterDays = 0;
    int moodCount = 0;

    for (final entry in allEntries) {
      if (entry.category == LogCategory.steps) {
        totalSteps += entry.numericValue;
        stepDays++;
      } else if (entry.category == LogCategory.sleep) {
        totalSleepMinutes += entry.numericValue * 60;
        sleepDays++;
      } else if (entry.category == LogCategory.water) {
        totalWaterLiters += entry.numericValue;
        waterDays++;
      } else if (entry.category == LogCategory.mood) {
        moodCount++;
      }
    }

    final avgSteps = stepDays > 0 ? totalSteps / stepDays : 0.0;
    final avgSleep = sleepDays > 0 ? (totalSleepMinutes / sleepDays) / 60.0 : 0.0;
    final avgWater = waterDays > 0 ? totalWaterLiters / waterDays : 0.0;
    final moodScore = moodCount > 0 ? (moodCount * 20.0).clamp(0.0, 100.0) : 85.0;

    state = state.copyWith(
      groupedLogs: grouped,
      weeklyAverageSteps: avgSteps,
      weeklyAverageSleepHours: avgSleep,
      weeklyAverageWaterLiters: avgWater,
      moodPositivityScore: moodScore,
    );
  }

  String _formatDateHeader(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final checkDate = DateTime(dt.year, dt.month, dt.day);

    if (checkDate == today) {
      return 'TODAY, ${DateFormat('MMM d').format(dt).toUpperCase()}';
    } else if (checkDate == yesterday) {
      return 'YESTERDAY, ${DateFormat('MMM d').format(dt).toUpperCase()}';
    } else {
      return DateFormat('EEEE, MMM d, yyyy').format(dt).toUpperCase();
    }
  }

  // ── Action: Delete Log Entry with Confirmation ─────────────────────────────
  Future<void> confirmAndDeleteEntry(
    BuildContext context,
    LoggedHistoryEntry entry,
  ) async {
    final theme = Theme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.redAccent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Text('Delete Log Entry?'),
            ],
          ),
          content: Text(
            'Are you sure you want to remove this ${entry.category.label} entry (${entry.displayValue})? Averages will recalculate immediately.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      _ref.read(hapticServiceProvider).buttonPress();

      // Soft delete ID
      _deletedIds.add(entry.id);

      // If it's a water entry, also update wellness provider
      if (entry.category == LogCategory.water) {
        await _ref
            .read(wellnessProvider.notifier)
            .deleteWaterLogEntry(entry.id);
      }

      // Remove from custom logs if present
      final updatedCustom = state.customLogs
          .where((e) => e.id != entry.id)
          .toList();

      state = state.copyWith(customLogs: updatedCustom);

      // Instant Recalculation of weekly & daily averages
      _refreshLogsAndStats();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${entry.title} deleted. Totals recalculated!'),
            backgroundColor: FitoraColors.darkSurface,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // ── Action: Edit Log Entry ──────────────────────────────────────────────────
  Future<void> editEntry(
    BuildContext context,
    LoggedHistoryEntry entry,
  ) async {
    final theme = Theme.of(context);
    final textController = TextEditingController(
      text: entry.numericValue > 0
          ? (entry.numericValue % 1 == 0
              ? entry.numericValue.toInt().toString()
              : entry.numericValue.toStringAsFixed(1))
          : entry.displayValue,
    );

    final updated = await showDialog<LoggedHistoryEntry>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          title: Row(
            children: [
              Icon(Icons.edit_rounded, color: entry.category.color, size: 22),
              const SizedBox(width: 12),
              Text('Edit ${entry.category.label} Log'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Update value for ${entry.title}:',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: textController,
                keyboardType: entry.category == LogCategory.mood
                    ? TextInputType.text
                    : TextInputType.number,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: entry.category == LogCategory.mood
                      ? 'Mood (e.g. Calm, Energized)'
                      : 'Amount (${entry.unit})',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final input = textController.text.trim();
                if (input.isEmpty) return;

                double numVal = entry.numericValue;
                String displayStr = input;

                if (entry.category != LogCategory.mood) {
                  final parsed = double.tryParse(input);
                  if (parsed != null && parsed > 0) {
                    numVal = parsed;
                    if (entry.category == LogCategory.steps) {
                      displayStr = '${parsed.toInt()} steps';
                    } else if (entry.category == LogCategory.water) {
                      displayStr = '${parsed.toStringAsFixed(1)} L';
                    } else if (entry.category == LogCategory.sleep) {
                      displayStr = '${parsed.toStringAsFixed(1)} hrs';
                    }
                  }
                }

                final newEntry = entry.copyWith(
                  displayValue: displayStr,
                  numericValue: numVal,
                );
                Navigator.of(ctx).pop(newEntry);
              },
              style: FilledButton.styleFrom(
                backgroundColor: entry.category.color,
                foregroundColor: Colors.black,
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (updated != null) {
      _ref.read(hapticServiceProvider).buttonPress();

      // Update custom logs list
      final customList = List<LoggedHistoryEntry>.from(state.customLogs);
      final index = customList.indexWhere((e) => e.id == updated.id);
      if (index >= 0) {
        customList[index] = updated;
      } else {
        customList.add(updated);
      }

      state = state.copyWith(customLogs: customList);

      // Instant Recalculation
      _refreshLogsAndStats();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${updated.title} updated! Totals recalculated.'),
            backgroundColor: FitoraColors.mintGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
