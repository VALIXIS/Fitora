import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitora/features/settings/providers/settings_provider.dart';

final hapticServiceProvider = Provider<HapticService>((ref) => HapticService(ref));

class HapticService {
  final Ref? _ref;

  HapticService([this._ref]);

  bool get _isHapticsEnabled {
    if (_ref == null) return true;
    try {
      return _ref.read(settingsProvider).hapticsEnabled;
    } catch (_) {
      return true;
    }
  }

  Future<void> lightImpact() async {
    if (!_isHapticsEnabled) return;
    await HapticFeedback.lightImpact();
  }

  Future<void> mediumImpact() async {
    if (!_isHapticsEnabled) return;
    await HapticFeedback.mediumImpact();
  }

  Future<void> heavyImpact() async {
    if (!_isHapticsEnabled) return;
    await HapticFeedback.heavyImpact();
  }

  Future<void> selectionClick() async {
    if (!_isHapticsEnabled) return;
    await HapticFeedback.selectionClick();
  }

  // Semantic interaction methods
  Future<void> tabSwitch() => selectionClick();
  Future<void> buttonPress() => lightImpact();
  Future<void> sliderChange() => selectionClick();
  Future<void> goalCompleted() => mediumImpact();
}
