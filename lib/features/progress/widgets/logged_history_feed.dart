import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fitora/core/constants/spacing.dart';
import 'package:fitora/core/theme/fitora_colors.dart';
import 'package:fitora/shared/widgets/glow_container.dart';
import 'package:fitora/shared/widgets/scale_on_press.dart';
import 'package:fitora/features/progress/providers/progress_history_provider.dart';

class LoggedHistoryFeed extends ConsumerStatefulWidget {
  const LoggedHistoryFeed({super.key});

  @override
  ConsumerState<LoggedHistoryFeed> createState() => _LoggedHistoryFeedState();
}

class _LoggedHistoryFeedState extends ConsumerState<LoggedHistoryFeed> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final historyState = ref.watch(progressHistoryProvider);
    final historyNotifier = ref.read(progressHistoryProvider.notifier);

    final groupedLogs = historyState.groupedLogs;
    final isEmpty = groupedLogs.isEmpty;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: FitoraSpacing.xl,
            vertical: FitoraSpacing.xs,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Input Field
              TextField(
                controller: _searchController,
                onChanged: (val) {
                  historyNotifier.setSearchQuery(val);
                },
                decoration: InputDecoration(
                  hintText: 'Search logs (steps, sleep, water, mood)...',
                  hintStyle: textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                  suffixIcon: historyState.searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            historyNotifier.setSearchQuery('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: theme.colorScheme.onSurface.withValues(alpha: 0.04),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: FitoraColors.mintGreen,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: FitoraSpacing.sm),

              // Filter Category Chips: [All, Steps, Sleep, Water, Mood]
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: LogCategory.values.map((cat) {
                    final isSelected = historyState.selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        selected: isSelected,
                        avatar: Icon(
                          cat.icon,
                          size: 16,
                          color: isSelected ? Colors.black : cat.color,
                        ),
                        label: Text(cat.label),
                        labelStyle: textTheme.labelSmall?.copyWith(
                          color: isSelected
                              ? Colors.black
                              : theme.colorScheme.onSurface,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w600,
                        ),
                        selectedColor: FitoraColors.mintGreen,
                        backgroundColor: theme.colorScheme.onSurface
                            .withValues(alpha: 0.05),
                        onSelected: (_) {
                          historyNotifier.setCategory(cat);
                        },
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isSelected
                                ? FitoraColors.mintGreen
                                : theme.colorScheme.outlineVariant
                                    .withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: FitoraSpacing.sm),

              // Recalculated Weekly Averages Summary Banner
              _buildRecalculatedAveragesBanner(context, historyState),
            ],
          ),
        ),

        const SizedBox(height: FitoraSpacing.xs),

        // Timeline Feed List
        Expanded(
          child: isEmpty
              ? _buildEmptyState(context, textTheme)
              : ListView.builder(
                  padding: const EdgeInsets.only(
                    left: FitoraSpacing.xl,
                    right: FitoraSpacing.xl,
                    top: FitoraSpacing.xs,
                    bottom: 110,
                  ),
                  physics: const BouncingScrollPhysics(),
                  itemCount: groupedLogs.keys.length,
                  itemBuilder: (context, index) {
                    final dateHeader = groupedLogs.keys.elementAt(index);
                    final entries = groupedLogs[dateHeader]!;
                    return _buildDateGroupSection(
                      context,
                      dateHeader,
                      entries,
                      historyNotifier,
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ── Recalculated Averages Banner ──────────────────────────────────────────
  Widget _buildRecalculatedAveragesBanner(
    BuildContext context,
    ProgressHistoryState state,
  ) {
    final theme = Theme.of(context);
    final tt = theme.textTheme;

    return GlowContainer(
      glowColor: FitoraColors.mintGreen.withValues(alpha: 0.04),
      borderRadius: BorderRadius.circular(16),
      padding: EdgeInsets.zero,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildAverageStat(
              tt,
              theme,
              'AVG STEPS',
              '${state.weeklyAverageSteps.round()} /d',
              FitoraColors.mintGreen,
            ),
            Container(
              width: 1,
              height: 24,
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
            _buildAverageStat(
              tt,
              theme,
              'AVG SLEEP',
              '${state.weeklyAverageSleepHours.toStringAsFixed(1)} h/d',
              FitoraColors.calmCyan,
            ),
            Container(
              width: 1,
              height: 24,
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
            _buildAverageStat(
              tt,
              theme,
              'AVG WATER',
              '${state.weeklyAverageWaterLiters.toStringAsFixed(1)} L/d',
              Colors.blueAccent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAverageStat(
    TextTheme tt,
    ThemeData theme,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: tt.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.bold,
            fontSize: 9,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: tt.bodyMedium?.copyWith(
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ],
    );
  }

  // ── Date Group Section ─────────────────────────────────────────────────────
  Widget _buildDateGroupSection(
    BuildContext context,
    String dateHeader,
    List<LoggedHistoryEntry> entries,
    ProgressHistoryNotifier notifier,
  ) {
    final theme = Theme.of(context);
    final tt = theme.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 8, left: 4),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: FitoraColors.mintGreen,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                dateHeader,
                style: tt.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 10.5,
                ),
              ),
            ],
          ),
        ),
        ...entries.map((entry) => _buildEntryCard(context, entry, notifier)),
      ],
    );
  }

  // ── Individual Entry Card ──────────────────────────────────────────────────
  Widget _buildEntryCard(
    BuildContext context,
    LoggedHistoryEntry entry,
    ProgressHistoryNotifier notifier,
  ) {
    final theme = Theme.of(context);
    final tt = theme.textTheme;
    final timeStr = DateFormat('hh:mm a').format(entry.timestamp);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          // Category Icon Circle
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: entry.category.color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: entry.category.color.withValues(alpha: 0.3),
              ),
            ),
            child: Icon(
              entry.category.icon,
              color: entry.category.color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),

          // Log details (Title & Timestamp)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      entry.title,
                      style: tt.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        timeStr,
                        style: tt.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 9.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  entry.displayValue,
                  style: tt.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: entry.category.color,
                  ),
                ),
                if (entry.details != null && entry.details!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    entry.details!,
                    style: tt.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Action Buttons: Edit & Delete
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(
                button: true,
                label: 'Edit ${entry.title}',
                child: ScaleOnPress(
                  child: IconButton(
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                    icon: Icon(
                      Icons.edit_outlined,
                      color: theme.colorScheme.onSurfaceVariant,
                      size: 18,
                    ),
                    onPressed: () {
                      notifier.editEntry(context, entry);
                    },
                    tooltip: 'Edit entry',
                  ),
                ),
              ),
              Semantics(
                button: true,
                label: 'Delete ${entry.title}',
                child: ScaleOnPress(
                  child: IconButton(
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.redAccent,
                      size: 18,
                    ),
                    onPressed: () {
                      notifier.confirmAndDeleteEntry(context, entry);
                    },
                    tooltip: 'Delete entry',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Empty State ────────────────────────────────────────────────────────────
  Widget _buildEmptyState(BuildContext context, TextTheme tt) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history_toggle_off_rounded,
              size: 56,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No Log Entries Found',
              style: tt.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No logged history matches your search query or selected category filter.',
              textAlign: TextAlign.center,
              style: tt.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
