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
              color: theme.colorScheme.onSurface,
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
            ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isUnlocked
              ? FitoraColors.mintGreen.withValues(alpha: 0.3)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
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
                          : theme.colorScheme.onSurface.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      badge.iconData,
                      color: isUnlocked ? FitoraColors.mintGreen : theme.colorScheme.onSurfaceVariant,
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
                  color: isUnlocked 
                      ? theme.colorScheme.onSurface 
                      : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                badge.description,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: tt.bodySmall?.copyWith(
                  color: isUnlocked 
                      ? theme.colorScheme.onSurfaceVariant 
                      : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
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
            Positioned(
              top: 0,
              right: 0,
              child: Icon(
                Icons.lock_outline_rounded,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                size: 16,
              ),
            ),
        ],
      ),
    );
  }
}
