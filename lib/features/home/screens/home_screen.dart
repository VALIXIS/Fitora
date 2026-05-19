import 'package:flutter/material.dart';
import 'package:fitora/core/constants/spacing.dart';
import 'package:fitora/core/responsive/responsive_builder.dart';
import 'package:fitora/shared/widgets/app_scaffold.dart';
import 'package:fitora/shared/widgets/fitora_button.dart';
import 'package:fitora/shared/widgets/fitora_card.dart';
import 'package:fitora/shared/widgets/glow_container.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Home',
      applyPadding: false,
      body: ResponsiveBuilder(
        mobile: (context) => const _HomeLayout(columns: 1),
        tablet: (context) => const _HomeLayout(columns: 2),
        desktop: (context) => const _HomeLayout(columns: 3),
      ),
    );
  }
}

class _HomeLayout extends StatelessWidget {
  final int columns;

  const _HomeLayout({required this.columns});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final width = MediaQuery.of(context).size.width;
    final availableWidth = width - FitoraSpacing.pagePadding.horizontal;
    final itemWidth = columns == 1
        ? availableWidth
        : (availableWidth - (columns - 1) * FitoraSpacing.md) / columns;

    return SingleChildScrollView(
      padding: FitoraSpacing.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _HeroCard(),
          const SizedBox(height: FitoraSpacing.lg),
          Text('Quick stats', style: textTheme.titleMedium),
          const SizedBox(height: FitoraSpacing.sm),
          Wrap(
            spacing: FitoraSpacing.md,
            runSpacing: FitoraSpacing.md,
            children: [
              for (final stat in _StatItem.samples)
                SizedBox(
                  width: itemWidth,
                  child: _StatCard(item: stat),
                ),
            ],
          ),
          const SizedBox(height: FitoraSpacing.lg),
          const _RecommendationCard(),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GlowContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Good morning', style: textTheme.titleMedium),
          const SizedBox(height: FitoraSpacing.sm),
          Text('Ready for a gentle start?', style: textTheme.headlineSmall),
          const SizedBox(height: FitoraSpacing.md),
          Text(
            'Try a short mobility flow designed for beginners.',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: FitoraSpacing.lg),
          FitoraButton(
            label: 'Start a 10 min flow',
            leading: const Icon(Icons.play_arrow),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return FitoraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Today\'s focus', style: textTheme.titleMedium),
          const SizedBox(height: FitoraSpacing.sm),
          Text(
            'Build consistency with a calm 15 minute session.',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: FitoraSpacing.md),
          FitoraButton(
            label: 'View plan',
            variant: FitoraButtonVariant.secondary,
            onPressed: () {},
            isFullWidth: false,
          ),
        ],
      ),
    );
  }
}

class _StatItem {
  final String label;
  final String value;
  final String caption;

  const _StatItem({
    required this.label,
    required this.value,
    required this.caption,
  });

  static const List<_StatItem> samples = [
    _StatItem(label: 'Steps', value: '2,340', caption: 'Today'),
    _StatItem(label: 'Minutes', value: '18', caption: 'Active time'),
    _StatItem(label: 'Mood', value: 'Calm', caption: 'Check-in'),
  ];
}

class _StatCard extends StatelessWidget {
  final _StatItem item;

  const _StatCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return FitoraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.label, style: textTheme.labelLarge),
          const SizedBox(height: FitoraSpacing.sm),
          Text(item.value, style: textTheme.headlineSmall),
          const SizedBox(height: FitoraSpacing.xs),
          Text(item.caption, style: textTheme.bodySmall),
        ],
      ),
    );
  }
}
