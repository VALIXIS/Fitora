class OnboardingPageData {
  final String title;
  final String subtitle;
  final String imagePath;

  const OnboardingPageData({
    required this.title,
    required this.subtitle,
    required this.imagePath,
  });
}

class OnboardingPages {
  static const List<OnboardingPageData> items = [
    OnboardingPageData(
      title: 'Track Every Step',
      subtitle: 'Monitor your daily steps, active minutes, calories burned, and distance automatically.',
      imagePath: 'assets/onboarding_1.png',
    ),
    OnboardingPageData(
      title: 'Build Healthier Habits',
      subtitle: 'Log your daily water intake and mindfulness breathing to build lasting healthy habits.',
      imagePath: 'assets/onboarding_2.png',
    ),
    OnboardingPageData(
      title: 'See Your Progress',
      subtitle: 'Track your sleep duration and patterns to help optimize your recovery and recharge.',
      imagePath: 'assets/onboarding_3.png',
    ),
    OnboardingPageData(
      title: 'Your Data. Your Control.',
      subtitle: 'All your fitness progress and metrics are kept secure and private on your device.',
      imagePath: 'assets/onboarding_4.png',
    ),
  ];
}
