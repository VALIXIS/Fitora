import 'package:flutter/material.dart';
import 'package:fitora/core/constants/spacing.dart';
import 'package:fitora/features/home/domain/home_dashboard_models.dart';
import 'package:fitora/shared/widgets/fitora_card.dart';

class HomeMetricTile extends StatelessWidget {
  final HomeMetricTileData data;
  final IconData icon;
  final Color accentColor;

  const HomeMetricTile({
    super.key,
    required this.data,
    required this.icon,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return FitoraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(FitoraSpacing.xs),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: accentColor),
          ),
          const SizedBox(height: FitoraSpacing.xs),
          Text(data.label, style: textTheme.labelLarge),
          const SizedBox(height: FitoraSpacing.xs),
          Text(data.value, style: textTheme.headlineSmall),
          const SizedBox(height: FitoraSpacing.xs),
          Text(
            data.caption,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
