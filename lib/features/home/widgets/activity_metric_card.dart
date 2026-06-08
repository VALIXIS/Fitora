import 'package:flutter/material.dart';
import 'package:fitora/core/constants/spacing.dart';
import 'package:fitora/shared/widgets/glow_container.dart';

class ActivityMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;

  const ActivityMetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return GlowContainer(
      glowColor: color.withValues(alpha: 0.15),
      child: Container(
        padding: const EdgeInsets.all(FitoraSpacing.md),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.2), shape: BoxShape.circle),
                  child: Icon(icon, color: color, size: 16),
                ),
                const SizedBox(width: FitoraSpacing.sm),
                Expanded(
                  child: Text(
                    title.toUpperCase(),
                    style: tt.labelSmall?.copyWith(color: Colors.white70, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: FitoraSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    value,
                    style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w900, color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4, left: 4),
                  child: Text(
                    unit,
                    style: tt.labelSmall?.copyWith(color: Colors.white54),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
