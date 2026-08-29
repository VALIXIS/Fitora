import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitora/core/theme/fitora_colors.dart';
import 'package:fitora/features/gamification/providers/gamification_provider.dart';
import 'package:fitora/features/gamification/domain/gamification_models.dart';

class AchievementsGrid extends ConsumerWidget {
  const AchievementsGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gamification = ref.watch(gamificationProvider);
    final badges = gamification.badges;
    final theme = Theme.of(context);
    final tt = theme.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
          child: Text(
            'Achievements',
            style: tt.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.1,
          ),
          itemCount: badges.length,
          itemBuilder: (context, index) {
            final badge = badges[index];
            return _BadgeItem(badge: badge);
          },
        ),
      ],
    );
  }
}

class _BadgeItem extends StatelessWidget {
  final AchievementBadge badge;

  const _BadgeItem({required this.badge});

  String _formatMonthDay(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return "${months[date.month - 1]} ${date.day}";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tt = theme.textTheme;
    final isUnlocked = badge.isUnlocked;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isUnlocked
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.white.withValues(alpha: 0.01),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isUnlocked
              ? FitoraColors.mintGreen.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.05),
          width: 1.5,
        ),
      ),
      child: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Opacity(
                  opacity: isUnlocked ? 1.0 : 0.25,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isUnlocked
                          ? FitoraColors.mintGreen.withValues(alpha: 0.15)
                          : Colors.white10,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      badge.iconData,
                      color: isUnlocked ? FitoraColors.mintGreen : Colors.white24,
                      size: 26,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                badge.title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: tt.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isUnlocked ? Colors.white : Colors.white38,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                badge.description,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: tt.bodySmall?.copyWith(
                  color: isUnlocked ? Colors.white60 : Colors.white24,
                  fontSize: 10,
                ),
              ),
              if (isUnlocked && badge.unlockedAt != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Unlocked ${_formatMonthDay(badge.unlockedAt!)}',
                  textAlign: TextAlign.center,
                  style: tt.bodySmall?.copyWith(
                    color: FitoraColors.mintGreen.withValues(alpha: 0.7),
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
          if (!isUnlocked)
            const Positioned(
              top: 0,
              right: 0,
              child: Icon(
                Icons.lock_outline_rounded,
                color: Colors.white24,
                size: 16,
              ),
            ),
        ],
      ),
    );
  }
}
