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
      title: 'Adaptive Fitness',
      subtitle: 'AI adapts every workout to your body, your energy, and your goals.',
      imagePath: 'assets/onboarding_1.png',
    ),
    OnboardingPageData(
      title: 'Wellness Tracking',
      subtitle: 'All your health metrics. Unified. Beautiful. Intelligent.',
      imagePath: 'assets/onboarding_2.png',
    ),
    OnboardingPageData(
      title: 'Smart Recovery',
      subtitle: 'AI-powered recovery insights to help you recharge, repair, and come back stronger.',
      imagePath: 'assets/onboarding_3.png',
    ),
    OnboardingPageData(
      title: 'Breathing & Mindfulness',
      subtitle: 'Breathe better. Reduce stress. Reset your mind and body.',
      imagePath: 'assets/onboarding_4.png',
    ),
    OnboardingPageData(
      title: 'Personalized AI Guidance',
      subtitle: 'Your AI coach learns you. Guides you. Evolves with you.',
      imagePath: 'assets/onboarding_5.png',
    ),
  ];
}
