enum PersonalizationStep {
  welcome,
  goal,
  wellness,
  body,
  complete,
}

extension PersonalizationStepX on PersonalizationStep {
  String get title {
    switch (this) {
      case PersonalizationStep.welcome:
        return "Let's build your wellness blueprint";
      case PersonalizationStep.goal:
        return 'Choose your primary goal';
      case PersonalizationStep.wellness:
        return 'Add wellness focus';
      case PersonalizationStep.body:
        return 'Body information';
      case PersonalizationStep.complete:
        return 'Setup complete';
    }
  }

  String get subtitle {
    switch (this) {
      case PersonalizationStep.welcome:
        return 'Set up your profile to customize your tracking goals.';
      case PersonalizationStep.goal:
        return 'Tell us what you want to focus on first.';
      case PersonalizationStep.wellness:
        return 'Select areas you want to prioritize.';
      case PersonalizationStep.body:
        return 'Helps us calculate accurate metrics.';
      case PersonalizationStep.complete:
        return 'Your profile is ready.';
    }
  }
}

enum PersonalizationGoal {
  loseWeight,
  gainMuscle,
  stayFit,
  improveWellness,
  buildHabits,
  reduceStress,
}

extension PersonalizationGoalX on PersonalizationGoal {
  String get label {
    switch (this) {
      case PersonalizationGoal.loseWeight:
        return 'Lose weight';
      case PersonalizationGoal.gainMuscle:
        return 'Gain muscle';
      case PersonalizationGoal.stayFit:
        return 'Stay fit';
      case PersonalizationGoal.improveWellness:
        return 'Improve wellness';
      case PersonalizationGoal.buildHabits:
        return 'Build habits';
      case PersonalizationGoal.reduceStress:
        return 'Reduce stress';
    }
  }

  String get description {
    switch (this) {
      case PersonalizationGoal.loseWeight:
        return 'Lean out steadily with supportive plans.';
      case PersonalizationGoal.gainMuscle:
        return 'Build strength and definition with ease.';
      case PersonalizationGoal.stayFit:
        return 'Maintain energy and consistency every week.';
      case PersonalizationGoal.improveWellness:
        return 'Balance your mind and body with care.';
      case PersonalizationGoal.buildHabits:
        return 'Create daily routines that stick.';
      case PersonalizationGoal.reduceStress:
        return 'Feel calmer through gentle guidance.';
    }
  }
}

enum WorkoutPreference {
  home,
  gym,
  mixed,
}

extension WorkoutPreferenceX on WorkoutPreference {
  String get label {
    switch (this) {
      case WorkoutPreference.home:
        return 'Home workouts';
      case WorkoutPreference.gym:
        return 'Gym workouts';
      case WorkoutPreference.mixed:
        return 'Mixed';
    }
  }

  String get description {
    switch (this) {
      case WorkoutPreference.home:
        return 'Minimal equipment with flexible sessions.';
      case WorkoutPreference.gym:
        return 'Access to machines and heavier lifts.';
      case WorkoutPreference.mixed:
        return 'A blend of home and gym days.';
    }
  }
}

enum ExperienceLevel {
  beginner,
  intermediate,
  advanced,
}

extension ExperienceLevelX on ExperienceLevel {
  String get label {
    switch (this) {
      case ExperienceLevel.beginner:
        return 'Beginner';
      case ExperienceLevel.intermediate:
        return 'Intermediate';
      case ExperienceLevel.advanced:
        return 'Advanced';
    }
  }

  String get description {
    switch (this) {
      case ExperienceLevel.beginner:
        return 'New to structured training or restarting.';
      case ExperienceLevel.intermediate:
        return 'Comfortable with routine workouts.';
      case ExperienceLevel.advanced:
        return 'Looking for higher intensity challenges.';
    }
  }
}

enum WellnessInterest {
  sleepTracking,
  hydrationReminders,
  cycleTracking,
  mindfulness,
  stepTracking,
}

extension WellnessInterestX on WellnessInterest {
  String get label {
    switch (this) {
      case WellnessInterest.sleepTracking:
        return 'Sleep tracking';
      case WellnessInterest.hydrationReminders:
        return 'Hydration reminders';
      case WellnessInterest.cycleTracking:
        return 'Cycle tracking';
      case WellnessInterest.mindfulness:
        return 'Mindfulness';
      case WellnessInterest.stepTracking:
        return 'Step tracking';
    }
  }
}

class PersonalizationProfile {
  final String? name;
  final PersonalizationGoal? goal;
  final WorkoutPreference? workoutPreference;
  final ExperienceLevel? experienceLevel;
  final Set<WellnessInterest> interests;
  final double? heightCm;
  final double? weightKg;
  final int? age;
  final String? gender;
  final bool isCompleted;

  const PersonalizationProfile({
    this.name,
    this.goal,
    this.workoutPreference,
    this.experienceLevel,
    this.interests = const {},
    this.heightCm,
    this.weightKg,
    this.age,
    this.gender,
    this.isCompleted = false,
  });

  factory PersonalizationProfile.empty() => const PersonalizationProfile();

  bool get hasMetrics => heightCm != null && weightKg != null && age != null;

  PersonalizationProfile copyWith({
    String? name,
    PersonalizationGoal? goal,
    WorkoutPreference? workoutPreference,
    ExperienceLevel? experienceLevel,
    Set<WellnessInterest>? interests,
    double? heightCm,
    double? weightKg,
    int? age,
    String? gender,
    bool? isCompleted,
  }) {
    return PersonalizationProfile(
      name: name ?? this.name,
      goal: goal ?? this.goal,
      workoutPreference: workoutPreference ?? this.workoutPreference,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      interests: interests ?? this.interests,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'goal': goal?.name,
      'workoutPreference': workoutPreference?.name,
      'experienceLevel': experienceLevel?.name,
      'interests': interests.map((e) => e.name).toList(),
      'heightCm': heightCm,
      'weightKg': weightKg,
      'age': age,
      'gender': gender,
      'isCompleted': isCompleted,
    };
  }

  factory PersonalizationProfile.fromJson(Map<String, dynamic> json) {
    return PersonalizationProfile(
      name: json['name'] as String?,
      goal: json['goal'] != null
          ? PersonalizationGoal.values.byName(json['goal'] as String)
          : null,
      workoutPreference: json['workoutPreference'] != null
          ? WorkoutPreference.values.byName(json['workoutPreference'] as String)
          : null,
      experienceLevel: json['experienceLevel'] != null
          ? ExperienceLevel.values.byName(json['experienceLevel'] as String)
          : null,
      interests: (json['interests'] as List<dynamic>?)
              ?.map((e) => WellnessInterest.values.byName(e as String))
              .toSet() ??
          const {},
      heightCm: (json['heightCm'] as num?)?.toDouble(),
      weightKg: (json['weightKg'] as num?)?.toDouble(),
      age: json['age'] as int?,
      gender: json['gender'] as String?,
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }
}
