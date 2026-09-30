import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitora/core/ads/ad_service.dart';
import 'package:fitora/features/sleep/domain/soundscape_model.dart';
import 'package:fitora/features/sleep/providers/soundscape_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    AdService.resetSoundscapeUnlocks();
  });

  group('AdService Rewarded Ad & Session Unlock Tokens', () {
    test('rewardedAdUnitId returns valid non-empty string', () {
      expect(AdService.rewardedAdUnitId.isNotEmpty, isTrue);
      expect(AdService.testRewardedAdUnitIdAndroid, equals('ca-app-pub-3940256099942544/5224354917'));
    });

    test('isSoundscapeUnlocked initially returns false for locked tracks', () {
      expect(AdService.isSoundscapeUnlocked('theta_binaural'), isFalse);
      expect(AdService.isSoundscapeUnlocked('celestial_drift'), isFalse);
    });

    test('unlockSoundscape grants session token and allows access', () {
      AdService.unlockSoundscape('theta_binaural');
      expect(AdService.isSoundscapeUnlocked('theta_binaural'), isTrue);
      expect(AdService.isSoundscapeUnlocked('celestial_drift'), isFalse);
    });

    test('resetSoundscapeUnlocks revokes all active session tokens', () {
      AdService.unlockSoundscape('theta_binaural');
      AdService.unlockSoundscape('celestial_drift');
      expect(AdService.isSoundscapeUnlocked('theta_binaural'), isTrue);

      AdService.resetSoundscapeUnlocks();
      expect(AdService.isSoundscapeUnlocked('theta_binaural'), isFalse);
      expect(AdService.isSoundscapeUnlocked('celestial_drift'), isFalse);
    });
  });

  group('SoundscapeTrack Domain Model', () {
    test('defaultTracks contains both free and premium tracks', () {
      final tracks = SoundscapeTrack.defaultTracks;
      expect(tracks.isNotEmpty, isTrue);

      final freeTracks = tracks.where((t) => !t.isPremium).toList();
      final premiumTracks = tracks.where((t) => t.isPremium).toList();

      expect(freeTracks.length, greaterThanOrEqualTo(2));
      expect(premiumTracks.length, greaterThanOrEqualTo(3));
    });
  });

  group('SoundscapeNotifier & Provider', () {
    test('free tracks are unlocked by default, premium tracks require token', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(soundscapeProvider.notifier);
      final rainTrack = SoundscapeTrack.defaultTracks.firstWhere((t) => !t.isPremium);
      final thetaTrack = SoundscapeTrack.defaultTracks.firstWhere((t) => t.isPremium);

      expect(notifier.isTrackUnlocked(rainTrack), isTrue);
      expect(notifier.isTrackUnlocked(thetaTrack), isFalse);

      notifier.markTrackUnlocked(thetaTrack.id);
      expect(notifier.isTrackUnlocked(thetaTrack), isTrue);
    });

    test('setVolume clamps between 0.0 and 1.0', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(soundscapeProvider.notifier);
      await notifier.setVolume(0.5);
      expect(container.read(soundscapeProvider).volume, equals(0.5));

      await notifier.setVolume(1.5);
      expect(container.read(soundscapeProvider).volume, equals(1.0));

      await notifier.setVolume(-0.5);
      expect(container.read(soundscapeProvider).volume, equals(0.0));
    });
  });
}
