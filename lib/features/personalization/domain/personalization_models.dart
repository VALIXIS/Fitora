enum PersonalizationStep {
  welcome,
  goal,
  activity,
  workout,
  wellness,
  body,
  lifestyle,
  aiPreview,
  complete,
}

extension PersonalizationStepX on PersonalizationStep {
  String get title {
    return switch (this) {
      PersonalizationStep.welcome => "Let's build your wellness blueprint",
      PersonalizationStep.goal => 'Choose your primary goal',
      PersonalizationStep.activity => 'Set your activity level',
      PersonalizationStep.workout => 'Pick your workout style',
      PersonalizationStep.wellness => 'Add wellness focus',
      PersonalizationStep.body => 'Body information',
      PersonalizationStep.lifestyle => 'Lifestyle assessment',
      PersonalizationStep.aiPreview => 'Analyzing profile...',
      PersonalizationStep.complete => 'Setup complete',
    };
  }

  String get subtitle {
    return switch (this) {
      PersonalizationStep.welcome => 'Your AI coach will create a plan tailored specifically for you.',
      PersonalizationStep.goal => 'Tell us what you want to focus on first.',
      PersonalizationStep.activity => 'Choose the level that fits your current routine.',
      PersonalizationStep.workout => 'We will tailor sessions to your environment.',
      PersonalizationStep.wellness => 'Select areas you want to prioritize.',
      PersonalizationStep.body => 'Helps us calculate accurate metrics.',
      PersonalizationStep.lifestyle => 'Helps the AI adapt your daily recovery.',
      PersonalizationStep.aiPreview => 'Generating your wellness blueprint.',
      PersonalizationStep.complete => 'Your blueprint is ready.',
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
