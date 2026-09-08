import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitora/features/personalization/data/personalization_local_data_source.dart';
import 'package:fitora/features/personalization/domain/personalization_models.dart';
import 'package:fitora/features/cycle/providers/cycle_provider.dart';

final personalizationControllerProvider =
    StateNotifierProvider<PersonalizationController, PersonalizationViewState>(
  (ref) {
    final dataSource = ref.read(personalizationLocalDataSourceProvider);
    return PersonalizationController(ref, dataSource);
  },
);

class PersonalizationViewState {
  final int stepIndex;
  final bool isLoading;
  final bool isCompleted;
  final PersonalizationProfile profile;

  const PersonalizationViewState({
    required this.stepIndex,
    required this.isLoading,
    required this.isCompleted,
    required this.profile,
  });

  factory PersonalizationViewState.initial() {
    return PersonalizationViewState(
      stepIndex: 0,
      isLoading: true,
      isCompleted: false,
      profile: PersonalizationProfile.empty(),
    );
  }

  PersonalizationViewState copyWith({
    int? stepIndex,
    bool? isLoading,
    bool? isCompleted,
    PersonalizationProfile? profile,
  }) {
    return PersonalizationViewState(
      stepIndex: stepIndex ?? this.stepIndex,
      isLoading: isLoading ?? this.isLoading,
      isCompleted: isCompleted ?? this.isCompleted,
      profile: profile ?? this.profile,
    );
  }

  int get totalSteps => PersonalizationStep.values.length;

  PersonalizationStep get currentStep =>
      PersonalizationStep.values[stepIndex];

  bool get isLastStep => stepIndex >= totalSteps - 1;

  bool get canGoBack => stepIndex > 0;

  bool get canProceed {
    switch (currentStep) {
      case PersonalizationStep.welcome:
        return true;
      case PersonalizationStep.goal:
        return profile.goal != null;
      case PersonalizationStep.wellness:
        return profile.interests.isNotEmpty;
      case PersonalizationStep.body:
        return profile.hasMetrics;
      case PersonalizationStep.complete:
        return true;
    }
  }

  double get progress => (stepIndex + 1) / totalSteps;
}

class PersonalizationController extends StateNotifier<PersonalizationViewState> {
  final Ref _ref;
  final PersonalizationLocalDataSource _dataSource;
  late final Future<void> _loadFuture;
  Future<void> _saveQueue = Future<void>.value();

  PersonalizationController(this._ref, this._dataSource)
      : super(PersonalizationViewState.initial()) {
    _loadFuture = _load();
  }

  Future<void> _load() async {
    final completed = await _dataSource.isCompleted();
    final profile = await _dataSource.fetchProfile();
    state = state.copyWith(
      isCompleted: completed,
      isLoading: false,
      profile: profile ?? state.profile,
    );
  }

  Future<void> reloadProfile() => _load();

  Future<void> ensureLoaded() => _loadFuture;

  void setStep(int index) {
    final nextIndex = index.clamp(0, state.totalSteps - 1).toInt();
    if (nextIndex == state.stepIndex) {
      return;
    }
    state = state.copyWith(stepIndex: nextIndex);
  }

  void nextStep() {
    if (state.isLastStep) {
      return;
    }
    setStep(state.stepIndex + 1);
  }

  void previousStep() {
    if (!state.canGoBack) {
      return;
    }
    setStep(state.stepIndex - 1);
  }

  void setGoal(PersonalizationGoal goal) {
    updateProfile(state.profile.copyWith(goal: goal));
  }

  void setWorkoutPreference(WorkoutPreference preference) {
    updateProfile(state.profile.copyWith(workoutPreference: preference));
  }

  void setExperienceLevel(ExperienceLevel level) {
    updateProfile(state.profile.copyWith(experienceLevel: level));
  }

  void setAge(int? age) {
    updateProfile(state.profile.copyWith(age: age));
  }

  void setHeight(double? heightCm) {
    updateProfile(state.profile.copyWith(heightCm: heightCm));
  }

  void setWeight(double? weightKg) {
    updateProfile(state.profile.copyWith(weightKg: weightKg));
  }

  void setDailyStress(double? stress) {
    updateProfile(state.profile.copyWith(dailyStress: stress));
  }

  void setSleepQuality(double? quality) {
    updateProfile(state.profile.copyWith(sleepQuality: quality));
  }

  void setEnergyLevel(double? energy) {
    updateProfile(state.profile.copyWith(energyLevel: energy));
  }

  void toggleInterest(WellnessInterest interest) {
    final updated = {...state.profile.interests};
    if (updated.contains(interest)) {
      updated.remove(interest);
    } else {
      updated.add(interest);
    }
    updateProfile(state.profile.copyWith(interests: updated));
  }

  Future<void> completePersonalization() async {
    await _persistProfile(state.profile);
    await _dataSource.setCompleted(true);
    state = state.copyWith(isCompleted: true);

    final hasCycleFocus = state.profile.interests.contains(WellnessInterest.cycleTracking);
    final cycleNotifier = _ref.read(cycleProvider.notifier);
    await cycleNotifier.toggleCycleTracking(hasCycleFocus);
    await cycleNotifier.toggleReminders(hasCycleFocus);
  }

  void updateProfile(PersonalizationProfile profile) {
    state = state.copyWith(profile: profile);
    unawaited(_persistProfile(profile));
  }

  Future<void> _persistProfile(PersonalizationProfile profile) {
    _saveQueue = _saveQueue.then((_) => _dataSource.saveProfile(profile));
    return _saveQueue;
  }

  Future<void> reset() async {
    await _dataSource.clearProfile();
    await _dataSource.setCompleted(false);
    state = PersonalizationViewState.initial();
  }
}
