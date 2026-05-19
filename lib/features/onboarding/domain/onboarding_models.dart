class OnboardingPageData {
  final String title;
  final String subtitle;

  const OnboardingPageData({
    required this.title,
    required this.subtitle,
  });
}

class OnboardingPages {
  static const List<OnboardingPageData> items = [
    OnboardingPageData(
      title: 'Fitness and wellness made simple.',
      subtitle: 'Track progress, build habits, and feel better every day.',
    ),
    OnboardingPageData(
      title: 'Everything you need in one place.',
      subtitle: 'Track workouts, hydration, sleep, and daily activity effortlessly.',
    ),
    OnboardingPageData(
      title: 'Personalized with AI.',
      subtitle: 'Receive beginner-friendly routines and wellness insights tailored to you.',
    ),
    OnboardingPageData(
      title: 'More than fitness.',
      subtitle: 'Support your wellness journey with reminders, recovery, and cycle tracking.',
    ),
    OnboardingPageData(
      title: 'Small steps create lasting habits.',
      subtitle: 'Start your journey toward a healthier lifestyle today.',
    ),
  ];
}
