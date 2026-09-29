import 'package:flutter/material.dart';

class SoundscapeTrack {
  final String id;
  final String title;
  final String category;
  final String description;
  final IconData icon;
  final Color themeColor;
  final bool isPremium;
  final String audioAsset;

  const SoundscapeTrack({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.icon,
    required this.themeColor,
    required this.isPremium,
    required this.audioAsset,
  });

  static const List<SoundscapeTrack> defaultTracks = [
    SoundscapeTrack(
      id: 'rain_midnight',
      title: 'Midnight Rain',
      category: 'Nature & Storm',
      description: 'Gentle raindrops falling on a glass window to slow heart rate and soothe the mind.',
      icon: Icons.water_drop_rounded,
      themeColor: Color(0xFF4FC3F7),
      isPremium: false,
      audioAsset: 'sounds/bloop.wav',
    ),
    SoundscapeTrack(
      id: 'white_noise_fan',
      title: 'Deep Fan & White Noise',
      category: 'Acoustic Masking',
      description: 'Constant ambient low-frequency hum blocking background disturbances.',
      icon: Icons.air_rounded,
      themeColor: Color(0xFF81C784),
      isPremium: false,
      audioAsset: 'sounds/bloop.wav',
    ),
    SoundscapeTrack(
      id: 'theta_binaural',
      title: 'Theta Wave Deep Delta',
      category: 'Binaural Frequencies',
      description: '4Hz - 7Hz neurological entrainment promoting rapid entry into REM and deep sleep.',
      icon: Icons.graphic_eq_rounded,
      themeColor: Color(0xFFBA68C8),
      isPremium: true,
      audioAsset: 'sounds/bloop.wav',
    ),
    SoundscapeTrack(
      id: 'celestial_drift',
      title: 'Celestial Cosmic Drift',
      category: 'Space & Synthesizer',
      description: 'Warm atmospheric pads drifting through ambient space chords for anxiety relief.',
      icon: Icons.nightlight_round,
      themeColor: Color(0xFFFFD54F),
      isPremium: true,
      audioAsset: 'sounds/bloop.wav',
    ),
    SoundscapeTrack(
      id: 'ocean_dusk',
      title: 'Ocean Waves at Dusk',
      category: 'Nature & Coastal',
      description: 'Rhythmic tide ebb and flow synchronized with restorative diaphragmatic breathing.',
      icon: Icons.waves_rounded,
      themeColor: Color(0xFF26C6DA),
      isPremium: true,
      audioAsset: 'sounds/bloop.wav',
    ),
    SoundscapeTrack(
      id: 'tibetan_bowls',
      title: 'Tibetan Singing Bowls',
      category: 'Zen & Meditation',
      description: 'Resonant harmonic acoustic vibrations for somatic relaxation and recovery.',
      icon: Icons.spa_rounded,
      themeColor: Color(0xFFFF8A65),
      isPremium: true,
      audioAsset: 'sounds/bloop.wav',
    ),
  ];
}
