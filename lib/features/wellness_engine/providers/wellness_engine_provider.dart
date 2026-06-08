import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitora/features/wellness/providers/wellness_provider.dart';
import 'package:fitora/features/progress/providers/progress_controller.dart';
import 'package:fitora/features/progress/domain/progress_models.dart';
import 'package:fitora/features/wellness_engine/domain/wellness_engine_models.dart';
import 'package:fitora/features/wellness_engine/services/wellness_engine_service.dart';

final wellnessEngineServiceProvider = Provider<WellnessEngineService>((ref) {
  return WellnessEngineService();
});

final wellnessEngineProvider = StateNotifierProvider<WellnessEngineNotifier, WellnessEngineState>((ref) {
  final service = ref.watch(wellnessEngineServiceProvider);
  return WellnessEngineNotifier(ref, service);
});

class WellnessEngineNotifier extends StateNotifier<WellnessEngineState> {
  final Ref _ref;
  final WellnessEngineService _service;

  WellnessEngineNotifier(this._ref, this._service) : super(WellnessEngineState.initial()) {
    // Listen to changes in wellness and progress to update calculations automatically
    _ref.listen(wellnessProvider, (previous, next) {
      _recalculate();
    });

    _ref.listen(progressControllerProvider, (previous, next) {
      if (!next.isLoading) {
        _recalculate();
      }
    });

    // Initial calculation
    _recalculate();
  }

  void _recalculate() {
    final wellnessState = _ref.read(wellnessProvider);
    final progressState = _ref.read(progressControllerProvider);

    final history = progressState.isLoading ? const <WorkoutHistoryEntry>[] : progressState.history;

    final updated = _service.process(
      wellness: wellnessState,
      history: history,
    );

    state = updated;
  }
}
