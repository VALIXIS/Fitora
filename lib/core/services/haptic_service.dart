import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitora/features/settings/providers/settings_provider.dart';

final hapticServiceProvider = Provider<HapticService>((ref) => HapticService(ref));

/// Static convenience accessor for global micro-interaction haptics
class AppHaptics {
  static bool hapticsGlobalEnabled = true;

  static Future<void> light() async {
    if (!hapticsGlobalEnabled) return;
    try {
      await HapticFeedback.lightImpact();
    } catch (_) {}
  }

  static Future<void> medium() async {
    if (!hapticsGlobalEnabled) return;
    try {
      await HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  static Future<void> heavy() async {
    if (!hapticsGlobalEnabled) return;
    try {
      await HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  static Future<void> selection() async {
    if (!hapticsGlobalEnabled) return;
    try {
      await HapticFeedback.selectionClick();
    } catch (_) {}
  }

  static Future<void> buttonPress() => light();
  static Future<void> switchToggle() => selection();
  static Future<void> sliderChange() => selection();
  static Future<void> tabSwitch() => selection();
  static Future<void> cardTap() => light();
  static Future<void> goalCompleted() => medium();
}

class HapticService {
  final Ref? _ref;

  HapticService([this._ref]);

  bool get _isHapticsEnabled {
    if (_ref == null) return AppHaptics.hapticsGlobalEnabled;
    try {
      final enabled = _ref.read(settingsProvider).hapticsEnabled;
      AppHaptics.hapticsGlobalEnabled = enabled;
      return enabled;
    } catch (_) {
      return AppHaptics.hapticsGlobalEnabled;
    }
  }

  Future<void> lightImpact() async {
    if (!_isHapticsEnabled) return;
    try {
      await HapticFeedback.lightImpact();
    } catch (_) {}
  }

  Future<void> mediumImpact() async {
    if (!_isHapticsEnabled) return;
    try {
      await HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  Future<void> heavyImpact() async {
    if (!_isHapticsEnabled) return;
    try {
      await HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  Future<void> selectionClick() async {
    if (!_isHapticsEnabled) return;
    try {
      await HapticFeedback.selectionClick();
    } catch (_) {}
  }

  // Semantic interaction methods
  Future<void> tabSwitch() => selectionClick();
  Future<void> buttonPress() => lightImpact();
  Future<void> switchToggle() => selectionClick();
  Future<void> sliderChange() => selectionClick();
  Future<void> cardTap() => lightImpact();
  Future<void> goalCompleted() => mediumImpact();
}
