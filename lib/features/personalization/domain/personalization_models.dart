enum PersonalizationStep {
  goal,
  workout,
  experience,
  metrics,
  wellness,
}

extension PersonalizationStepX on PersonalizationStep {
  String get title {
    return switch (this) {
      PersonalizationStep.goal => 'Choose your primary goal',
      PersonalizationStep.workout => 'Pick your workout style',
      PersonalizationStep.experience => 'Set your experience level',
      PersonalizationStep.metrics => 'Share basic metrics',
      PersonalizationStep.wellness => 'Add wellness interests',
    };
  }

  String get subtitle {
    return switch (this) {
      PersonalizationStep.goal =>
        'Tell us what you want to focus on first so we can guide you better.',
      PersonalizationStep.workout =>
        'We will tailor sessions to fit your space and schedule.',
      PersonalizationStep.experience =>
        'Choose the level that feels comfortable for you right now.',
      PersonalizationStep.metrics =>
        'A few details help us personalize pacing and insights.',
      PersonalizationStep.wellness =>
        'Optional: pick the habits you want gentle reminders for.',
    };
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
    return switch (this) {
      PersonalizationGoal.loseWeight => 'Lose weight',
      PersonalizationGoal.gainMuscle => 'Gain muscle',
      PersonalizationGoal.stayFit => 'Stay fit',
      PersonalizationGoal.improveWellness => 'Improve wellness',
      PersonalizationGoal.buildHabits => 'Build habits',
      PersonalizationGoal.reduceStress => 'Reduce stress',
    };
  }

  String get description {
    return switch (this) {
      PersonalizationGoal.loseWeight => 'Lean out steadily with supportive plans.',
      PersonalizationGoal.gainMuscle => 'Build strength and definition with ease.',
      PersonalizationGoal.stayFit => 'Maintain energy and consistency every week.',
      PersonalizationGoal.improveWellness => 'Balance your mind and body with care.',
      PersonalizationGoal.buildHabits => 'Create daily routines that stick.',
      PersonalizationGoal.reduceStress => 'Feel calmer through gentle guidance.',
    };
  }
}

enum WorkoutPreference {
  home,
  gym,
  mixed,
}

extension WorkoutPreferenceX on WorkoutPreference {
  String get label {
    return switch (this) {
      WorkoutPreference.home => 'Home workouts',
      WorkoutPreference.gym => 'Gym workouts',
      WorkoutPreference.mixed => 'Mixed',
    };
  }

  String get description {
    return switch (this) {
      WorkoutPreference.home => 'Minimal equipment with flexible sessions.',
      WorkoutPreference.gym => 'Access to machines and heavier lifts.',
      WorkoutPreference.mixed => 'A blend of home and gym days.',
    };
  }
}

enum ExperienceLevel {
  beginner,
  intermediate,
  advanced,
}

extension ExperienceLevelX on ExperienceLevel {
  String get label {
    return switch (this) {
      ExperienceLevel.beginner => 'Beginner',
      ExperienceLevel.intermediate => 'Intermediate',
      ExperienceLevel.advanced => 'Advanced',
    };
  }

  String get description {
    return switch (this) {
      ExperienceLevel.beginner => 'New to structured training or restarting.',
      ExperienceLevel.intermediate => 'Comfortable with routine workouts.',
      ExperienceLevel.advanced => 'Looking for higher intensity challenges.',
    };
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
    return switch (this) {
      WellnessInterest.sleepTracking => 'Sleep tracking',
      WellnessInterest.hydrationReminders => 'Hydration reminders',
      WellnessInterest.cycleTracking => 'Cycle tracking',
      WellnessInterest.mindfulness => 'Mindfulness',
      WellnessInterest.stepTracking => 'Step tracking',
    };
  }
}

class PersonalizationProfile {
  final PersonalizationGoal? goal;
  final WorkoutPreference? workoutPreference;
  final ExperienceLevel? experienceLevel;
  final int? age;
  final double? heightCm;
  final double? weightKg;
  final Set<WellnessInterest> interests;

  PersonalizationProfile({
    this.goal,
    this.workoutPreference,
    this.experienceLevel,
    this.age,
    this.heightCm,
    this.weightKg,
    Set<WellnessInterest>? interests,
  }) : interests = Set.unmodifiable(interests ?? const {});

  factory PersonalizationProfile.empty() => PersonalizationProfile();

  PersonalizationProfile copyWith({
    PersonalizationGoal? goal,
    WorkoutPreference? workoutPreference,
    ExperienceLevel? experienceLevel,
    int? age,
    double? heightCm,
    double? weightKg,
    Set<WellnessInterest>? interests,
  }) {
    return PersonalizationProfile(
      goal: goal ?? this.goal,
      workoutPreference: workoutPreference ?? this.workoutPreference,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      age: age ?? this.age,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      interests: interests ?? this.interests,
    );
  }

  bool get hasMetrics => age != null && heightCm != null && weightKg != null;

  Map<String, dynamic> toJson() {
    return {
      'goal': goal?.name,
      'workoutPreference': workoutPreference?.name,
      'experienceLevel': experienceLevel?.name,
      'age': age,
      'heightCm': heightCm,
      'weightKg': weightKg,
      'interests': interests.map((interest) => interest.name).toList(),
    };
  }

  factory PersonalizationProfile.fromJson(Map<String, dynamic> json) {
    final interests = (json['interests'] as List?)
            ?.map((value) => value?.toString())
            .whereType<String>()
            .map((value) => _parseEnum(WellnessInterest.values, value))
            .whereType<WellnessInterest>()
            .toSet() ??
        <WellnessInterest>{};

    return PersonalizationProfile(
      goal: _parseEnum(PersonalizationGoal.values, json['goal']?.toString()),
      workoutPreference: _parseEnum(
        WorkoutPreference.values,
        json['workoutPreference']?.toString(),
      ),
      experienceLevel: _parseEnum(
        ExperienceLevel.values,
        json['experienceLevel']?.toString(),
      ),
      age: (json['age'] as num?)?.toInt(),
      heightCm: (json['heightCm'] as num?)?.toDouble(),
      weightKg: (json['weightKg'] as num?)?.toDouble(),
      interests: interests,
    );
  }
}

T? _parseEnum<T extends Enum>(List<T> values, String? name) {
  if (name == null) {
    return null;
  }
  for (final value in values) {
    if (value.name == name) {
      return value;
    }
  }
  return null;
}
