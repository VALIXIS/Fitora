class HomeDashboardData {
  final String greeting;
  final String subtitle;
  final HomeStepProgress steps;
  final List<HomeMetricTileData> metrics;

  const HomeDashboardData({
    required this.greeting,
    required this.subtitle,
    required this.steps,
    required this.metrics,
  });

  HomeMetricTileData metric(HomeMetricType type) {
    return metrics.firstWhere((metric) => metric.type == type);
  }

  static HomeDashboardData sample() {
    return HomeDashboardData(
      greeting: 'Good evening',
      subtitle: 'Ready to stay consistent today?',
      steps: const HomeStepProgress(current: 6340, goal: 8500),
      metrics: const [
        HomeMetricTileData(
          type: HomeMetricType.calories,
          label: 'Calories',
          value: '460',
          caption: 'kcal burned',
        ),
        HomeMetricTileData(
          type: HomeMetricType.activeMinutes,
          label: 'Active minutes',
          value: '32',
          caption: 'minutes today',
        ),
        HomeMetricTileData(
          type: HomeMetricType.water,
          label: 'Water',
          value: '1.6L',
          caption: 'of 2.5L goal',
        ),
        HomeMetricTileData(
          type: HomeMetricType.sleep,
          label: 'Sleep',
          value: '7h 20m',
          caption: 'last night',
        ),
        HomeMetricTileData(
          type: HomeMetricType.streak,
          label: 'Streak',
          value: '6 days',
          caption: 'personal best',
        ),
      ],
    );
  }
}

class HomeStepProgress {
  final int current;
  final int goal;

  const HomeStepProgress({
    required this.current,
    required this.goal,
  });

  double get progress => goal == 0 ? 0 : current / goal;
}

enum HomeMetricType {
  calories,
  activeMinutes,
  water,
  sleep,
  streak,
}

class HomeMetricTileData {
  final HomeMetricType type;
  final String label;
  final String value;
  final String caption;

  const HomeMetricTileData({
    required this.type,
    required this.label,
    required this.value,
    required this.caption,
  });
}
