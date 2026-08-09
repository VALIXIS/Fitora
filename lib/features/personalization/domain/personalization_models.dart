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
  final int? age;
  final double? heightCm;
  final double? weightKg;
  final Set<WellnessInterest> interests;
  final double? dailyStress;
  final double? sleepQuality;
  final double? energyLevel;

  PersonalizationProfile({
    this.name,
    this.goal,
    this.workoutPreference,
    this.experienceLevel,
    this.age,
    this.heightCm,
    this.weightKg,
    Set<WellnessInterest>? interests,
    this.dailyStress,
    this.sleepQuality,
    this.energyLevel,
  }) : interests = Set.unmodifiable(interests ?? const {});

  factory PersonalizationProfile.empty() => PersonalizationProfile();

  PersonalizationProfile copyWith({
    String? name,
    PersonalizationGoal? goal,
    WorkoutPreference? workoutPreference,
    ExperienceLevel? experienceLevel,
    int? age,
    double? heightCm,
    double? weightKg,
    Set<WellnessInterest>? interests,
    double? dailyStress,
    double? sleepQuality,
    double? energyLevel,
  }) {
    return PersonalizationProfile(
      name: name ?? this.name,
      goal: goal ?? this.goal,
      workoutPreference: workoutPreference ?? this.workoutPreference,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      age: age ?? this.age,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      interests: interests ?? this.interests,
      dailyStress: dailyStress ?? this.dailyStress,
      sleepQuality: sleepQuality ?? this.sleepQuality,
      energyLevel: energyLevel ?? this.energyLevel,
    );
  }

  bool get hasMetrics => age != null && heightCm != null && weightKg != null;
  bool get hasLifestyle => dailyStress != null && sleepQuality != null && energyLevel != null;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'goal': goal?.name,
      'workoutPreference': workoutPreference?.name,
      'experienceLevel': experienceLevel?.name,
      'age': age,
      'heightCm': heightCm,
      'weightKg': weightKg,
      'interests': interests.map((e) => e.name).toList(),
      'dailyStress': dailyStress,
      'sleepQuality': sleepQuality,
      'energyLevel': energyLevel,
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
      age: json['age'] as int?,
      heightCm: (json['heightCm'] as num?)?.toDouble(),
      weightKg: (json['weightKg'] as num?)?.toDouble(),
      interests: (json['interests'] as List<dynamic>?)
              ?.map((e) => WellnessInterest.values.byName(e as String))
              .toSet() ??
          {},
      dailyStress: (json['dailyStress'] as num?)?.toDouble(),
      sleepQuality: (json['sleepQuality'] as num?)?.toDouble(),
      energyLevel: (json['energyLevel'] as num?)?.toDouble(),
    );
  }
}
