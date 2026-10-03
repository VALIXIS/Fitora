import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:confetti/confetti.dart';
import 'package:go_router/go_router.dart';
import 'package:fitora/core/theme/fitora_colors.dart';
import 'package:fitora/core/theme/fitora_spacing.dart';
import 'package:fitora/core/services/haptic_service.dart';
import 'package:fitora/features/gamification/domain/gamification_models.dart';
import 'package:fitora/features/gamification/providers/gamification_provider.dart';
import 'package:fitora/features/gamification/widgets/badge_3d_card.dart';

/// 3D Trophy Shelf Screen displaying unlocked and locked wellness milestone badges
/// with metallic shine effects, interactive 3D perspective tilt, and confetti explosions.
class BadgesScreen extends ConsumerStatefulWidget {
  const BadgesScreen({super.key});

  @override
  ConsumerState<BadgesScreen> createState() => _BadgesScreenState();
}

class _BadgesScreenState extends ConsumerState<BadgesScreen> {
  late ConfettiController _confettiController;
  String _selectedCategory = 'all';

  final List<Map<String, String>> _categories = const [
    {'id': 'all', 'label': 'All Trophies'},
    {'id': 'streak', 'label': 'Streaks'},
    {'id': 'sleep', 'label': 'Sleep'},
    {'id': 'water', 'label': 'Hydration'},
    {'id': 'steps', 'label': 'Movement'},
    {'id': 'workout', 'label': 'Workouts'},
    {'id': 'wellness', 'label': 'Wellness'},
  ];

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _confettiController.stop();
    _confettiController.dispose();
    super.dispose();
  }

  void _triggerCelebration() {
    ref.read(hapticServiceProvider).goalCompleted();
    _confettiController.play();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final gamification = ref.watch(gamificationProvider);
    final allBadges = gamification.badges;

    final unlockedCount = allBadges.where((b) => b.isUnlocked).length;
    final totalCount = allBadges.length;
    final completionPct = totalCount > 0 ? (unlockedCount / totalCount) : 0.0;

    // Filter badges based on selected category
    final filteredBadges = _selectedCategory == 'all'
        ? allBadges
        : allBadges.where((b) => b.category == _selectedCategory).toList();

    return Stack(
      children: [
        Scaffold(
          backgroundColor: isDark ? FitoraColors.darkBg : FitoraColors.lightBg,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              tooltip: 'Back to Profile',
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  Navigator.of(context).maybePop();
                }
              },
            ),
            title: Text(
              'Trophy Shelf',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 0.2,
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.celebration_rounded),
                tooltip: 'Celebrate Milestone Explosion',
                onPressed: _triggerCelebration,
              ),
            ],
          ),
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── 1. Hero Trophy Showcase Header ────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: FitoraSpacing.md,
                    vertical: FitoraSpacing.sm,
                  ),
                  child: _buildShelfHeader(
                    context,
                    unlockedCount,
                    totalCount,
                    completionPct,
                    isDark,
                  ),
                ),
              ),

              // ── 2. Category Filter Pills ──────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: FitoraSpacing.sm),
                  child: SizedBox(
                    height: 38,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: FitoraSpacing.md),
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final cat = _categories[index];
                        final isSelected = _selectedCategory == cat['id'];
                        return _buildCategoryChip(
                          label: cat['label']!,
                          isSelected: isSelected,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _selectedCategory = cat['id']!;
                            });
                          },
                          isDark: isDark,
                        );
                      },
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: FitoraSpacing.sm),
              ),

              // ── 3. 3D Trophy Shelf Grid ───────────────────────────────────
              if (filteredBadges.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      'No badges found in this category.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white54,
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: FitoraSpacing.md),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, rowIndex) {
                        final startIndex = rowIndex * 2;
                        final firstBadge = filteredBadges[startIndex];
                        final secondBadge = (startIndex + 1 < filteredBadges.length)
                            ? filteredBadges[startIndex + 1]
                            : null;

                        return _buildShelfRow(
                          firstBadge: firstBadge,
                          secondBadge: secondBadge,
                          isDark: isDark,
                        );
                      },
                      childCount: (filteredBadges.length / 2).ceil(),
                    ),
                  ),
                ),

              const SliverToBoxAdapter(
                child: SizedBox(height: 80),
              ),
            ],
          ),
        ),

        // ── Confetti Particle Cannon ────────────────────────────────────────
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            numberOfParticles: 45,
            emissionFrequency: 0.05,
            gravity: 0.18,
            colors: const [
              FitoraColors.mintGreen,
              FitoraColors.calmCyan,
              FitoraColors.softPink,
              Colors.amber,
              Color(0xFF10B981), // Emerald
              Color(0xFF3B82F6), // Blue
              Color(0xFFF97316), // Coral
              Color(0xFFEAB308), // Gold
            ],
          ),
        ),
      ],
    );
  }

  /// Builds the top trophy showcase banner with status and progress bar
  Widget _buildShelfHeader(
    BuildContext context,
    int unlocked,
    int total,
    double pct,
    bool isDark,
  ) {
    final theme = Theme.of(context);

    String rankTitle = 'Novice Explorer';
    Color rankColor = const Color(0xFF94A3B8); // Silver
    if (unlocked >= 7) {
      rankTitle = 'Grand Master';
      rankColor = const Color(0xFF38BDF8); // Diamond
    } else if (unlocked >= 5) {
      rankTitle = 'Gold Champion';
      rankColor = const Color(0xFFEAB308); // Gold
    } else if (unlocked >= 3) {
      rankTitle = 'Bronze Warrior';
      rankColor = const Color(0xFFF97316); // Bronze
    }

    return Container(
      padding: const EdgeInsets.all(FitoraSpacing.lg),
      decoration: BoxDecoration(
        color: isDark
            ? FitoraColors.darkSurfaceVariant.withValues(alpha: 0.70)
            : FitoraColors.lightSurfaceVariant,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: rankColor.withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      rankColor.withValues(alpha: 0.4),
                      rankColor.withValues(alpha: 0.1),
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: rankColor.withValues(alpha: 0.6),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  Icons.emoji_events_rounded,
                  color: rankColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '3D WELLNESS SHELF',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                        color: rankColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      rankTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
              // Unlocked count pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: rankColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: rankColor.withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  '$unlocked / $total',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: rankColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Progress indicator
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation<Color>(rankColor),
            ),
          ),

          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${(pct * 100).toInt()}% of Milestones Completed',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark ? Colors.white60 : FitoraColors.lightTextSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _triggerCelebration,
                child: Text(
                  'Celebrate 🎉',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: rankColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds a row of up to 2 trophy cards placed on a 3D shelf pedestal
  Widget _buildShelfRow({
    required AchievementBadge firstBadge,
    AchievementBadge? secondBadge,
    required bool isDark,
  }) {
    return Column(
      children: [
        const SizedBox(height: 12),
        // Badges positioned side-by-side
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Center(
                child: Badge3DCard(
                  badge: firstBadge,
                  onCelebrate: _triggerCelebration,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: secondBadge != null
                  ? Center(
                      child: Badge3DCard(
                        badge: secondBadge,
                        onCelebrate: _triggerCelebration,
                      ),
                    )
                  : const SizedBox(),
            ),
          ],
        ),

        // 3D Shelf Pedestal Plinth with wood/glass metallic surface and bevel
        Container(
          margin: const EdgeInsets.only(top: 8, bottom: 16),
          height: 16,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? const [
                      Color(0xFF384347),
                      Color(0xFF22292B),
                      Color(0xFF131718),
                    ]
                  : const [
                      Color(0xFFE2E8E6),
                      Color(0xFFCBD5D1),
                      Color(0xFF9EABA7),
                    ],
            ),
            boxShadow: [
              // Shelf bottom drop shadow
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.15),
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
              // Top illuminated rim reflection
              BoxShadow(
                color: Colors.white.withValues(alpha: isDark ? 0.12 : 0.40),
                blurRadius: 2,
                offset: const Offset(0, -1),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? FitoraColors.mintGreen
              : (isDark
                  ? FitoraColors.darkSurfaceVariant.withValues(alpha: 0.6)
                  : FitoraColors.lightSurfaceVariant),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? FitoraColors.mintGreen
                : (isDark ? Colors.white10 : Colors.black12),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected
                ? Colors.black
                : (isDark ? Colors.white70 : Colors.black87),
          ),
        ),
      ),
    );
  }
}
