import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final audioServiceProvider = Provider<AudioService>((ref) => AudioService());

class AudioService {
  final AudioPlayer _player = AudioPlayer();

  Future<void> playNotificationSound() async {
    try {
      await _player.play(AssetSource('sounds/bloop.wav'));
    } catch (e) {
      // Ignore errors if sound cannot be played
    }
  }
}
