import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fitora/core/ads/ad_service.dart';
import 'package:fitora/core/constants/spacing.dart';
import 'package:fitora/core/theme/fitora_colors.dart';
import 'package:fitora/features/sleep/domain/soundscape_model.dart';
import 'package:fitora/features/sleep/providers/soundscape_provider.dart';
import 'package:fitora/shared/widgets/glow_container.dart';
import 'package:fitora/shared/widgets/scale_on_press.dart';

class SoundscapesScreen extends ConsumerWidget {
  const SoundscapesScreen({super.key});

  void _handleTrackTap(
    BuildContext context,
    WidgetRef ref,
    SoundscapeTrack track,
    bool isUnlocked,
  ) {
    final notifier = ref.read(soundscapeProvider.notifier);

    if (isUnlocked) {
      notifier.playTrack(track);
    } else {
      // Prompt user with clean confirmation to watch a rewarded video ad
      _showUnlockDialog(context, ref, track);
    }
  }

  void _showUnlockDialog(
    BuildContext context,
    WidgetRef ref,
    SoundscapeTrack track,
  ) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        final theme = Theme.of(dialogCtx);
        return AlertDialog(
          backgroundColor: const Color(0xFF141A18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: track.themeColor.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: track.themeColor.withValues(alpha: 0.15),
                  border: Border.all(
                    color: track.themeColor.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: Icon(
                  track.icon,
                  size: 36,
                  color: track.themeColor,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Unlock ${track.title}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Watch a quick video ad to unlock this premium restorative soundscape for your current session.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(dialogCtx),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white60,
                        side: const BorderSide(color: Colors.white24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(dialogCtx);
                        _watchAdToUnlock(context, ref, track);
                      },
                      icon: const Icon(Icons.play_circle_fill_rounded, size: 18),
                      label: const Text('Watch Ad'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: track.themeColor,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        textStyle: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _watchAdToUnlock(
    BuildContext context,
    WidgetRef ref,
    SoundscapeTrack track,
  ) {
    AdService.showRewardedAdForSoundscape(
      context: context,
      soundscapeId: track.id,
      onRewardEarned: () {
        final notifier = ref.read(soundscapeProvider.notifier);
        notifier.markTrackUnlocked(track.id);
        notifier.playTrack(track);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF141A18),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: track.themeColor.withValues(alpha: 0.4)),
              ),
              content: Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: track.themeColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${track.title} unlocked! Enjoy your sleep.',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }

  void _showTimerPicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF121715),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        final notifier = ref.read(soundscapeProvider.notifier);
        final currentTimer = ref.watch(soundscapeProvider).sleepTimerMinutes;

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Sleep Timer',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Audio will automatically fade and stop when the timer expires.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white54,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [15, 30, 45, 60, 90, 0].map((mins) {
                  final isSelected = mins == 0
                      ? (currentTimer == null)
                      : (currentTimer == mins);
                  return ChoiceChip(
                    label: Text(mins == 0 ? 'Turn Off' : '$mins min'),
                    selected: isSelected,
                    selectedColor: FitoraColors.calmCyan,
                    backgroundColor: Colors.white.withValues(alpha: 0.05),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.black : Colors.white70,
                      fontWeight: FontWeight.bold,
                    ),
                    onSelected: (_) {
                      notifier.setSleepTimer(mins);
                      Navigator.pop(sheetCtx);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;
    final soundState = ref.watch(soundscapeProvider);
    final notifier = ref.read(soundscapeProvider.notifier);
    final tracks = SoundscapeTrack.defaultTracks;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Sleep Soundscapes',
          style: tt.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (soundState.activeTrack != null)
            IconButton(
              icon: Icon(
                soundState.sleepTimerMinutes != null
                    ? Icons.timer_rounded
                    : Icons.timer_outlined,
                color: soundState.sleepTimerMinutes != null
                    ? FitoraColors.calmCyan
                    : Colors.white70,
              ),
              tooltip: 'Sleep Timer',
              onPressed: () => _showTimerPicker(context, ref),
            ),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.fromLTRB(
              FitoraSpacing.xl,
              FitoraSpacing.md,
              FitoraSpacing.xl,
              soundState.activeTrack != null ? 140 : FitoraSpacing.xxl,
            ),
            children: [
              // Header description banner
              Container(
                padding: const EdgeInsets.all(FitoraSpacing.lg),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      FitoraColors.calmCyan.withValues(alpha: 0.12),
                      FitoraColors.calmCyan.withValues(alpha: 0.03),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: FitoraColors.calmCyan.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: FitoraColors.calmCyan.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.headphones_rounded,
                        color: FitoraColors.calmCyan,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DEEP RESTORATIVE AUDIO',
                            style: tt.labelSmall?.copyWith(
                              color: FitoraColors.calmCyan,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Calm your nervous system before bed with soothing acoustics and delta waves.',
                            style: tt.bodySmall?.copyWith(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: FitoraSpacing.xl),

              // Section Header
              Text(
                'SOUNDSCAPE TRACKS',
                style: tt.labelSmall?.copyWith(
                  color: Colors.white54,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: FitoraSpacing.md),

              // Tracks List
              ...tracks.map((track) {
                final isUnlocked = notifier.isTrackUnlocked(track);
                final isCurrent = soundState.activeTrack?.id == track.id;
                final isPlaying = isCurrent && soundState.isPlaying;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: ScaleOnPress(
                    onTap: () => _handleTrackTap(context, ref, track, isUnlocked),
                    child: GlowContainer(
                      glowColor: isCurrent
                          ? track.themeColor.withValues(alpha: 0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      padding: EdgeInsets.zero,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? const Color(0xFF161E1B)
                              : Colors.white.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isCurrent
                                ? track.themeColor.withValues(alpha: 0.5)
                                : Colors.white.withValues(alpha: 0.08),
                            width: isCurrent ? 1.5 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Icon Box
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: track.themeColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: track.themeColor.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Icon(
                                track.icon,
                                color: track.themeColor,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 14),

                            // Track Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          track.title,
                                          style: tt.bodyLarge?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (track.isPremium && !isUnlocked)
                                        Container(
                                          margin: const EdgeInsets.only(left: 6),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFFB74D)
                                                .withValues(alpha: 0.15),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                              color: const Color(0xFFFFB74D)
                                                  .withValues(alpha: 0.4),
                                            ),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.lock_rounded,
                                                size: 11,
                                                color: Color(0xFFFFB74D),
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                'WATCH AD',
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w900,
                                                  color: Color(0xFFFFB74D),
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      else if (track.isPremium && isUnlocked)
                                        Container(
                                          margin: const EdgeInsets.only(left: 6),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: FitoraColors.mintGreen
                                                .withValues(alpha: 0.15),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                              color: FitoraColors.mintGreen
                                                  .withValues(alpha: 0.4),
                                            ),
                                          ),
                                          child: const Text(
                                            'UNLOCKED',
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w900,
                                              color: FitoraColors.mintGreen,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    track.category,
                                    style: tt.labelSmall?.copyWith(
                                      color: track.themeColor.withValues(alpha: 0.8),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    track.description,
                                    style: tt.bodySmall?.copyWith(
                                      color: Colors.white54,
                                      fontSize: 11,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Action button
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isUnlocked
                                    ? (isPlaying
                                        ? track.themeColor
                                        : track.themeColor.withValues(alpha: 0.15))
                                    : Colors.white.withValues(alpha: 0.05),
                              ),
                              child: Icon(
                                isUnlocked
                                    ? (isPlaying
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded)
                                    : Icons.lock_outline_rounded,
                                color: isUnlocked
                                    ? (isPlaying ? Colors.black : track.themeColor)
                                    : Colors.white38,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),

          // Bottom Mini Player Bar
          if (soundState.activeTrack != null)
            Positioned(
              left: FitoraSpacing.lg,
              right: FitoraSpacing.lg,
              bottom: FitoraSpacing.lg,
              child: GlowContainer(
                glowColor: soundState.activeTrack!.themeColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(24),
                padding: EdgeInsets.zero,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161E1B),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: soundState.activeTrack!.themeColor.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.6),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Icon(
                            soundState.activeTrack!.icon,
                            color: soundState.activeTrack!.themeColor,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  soundState.activeTrack!.title,
                                  style: tt.bodyMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (soundState.remainingSeconds != null)
                                  Text(
                                    'Timer: ${soundState.remainingSeconds! ~/ 60}m ${soundState.remainingSeconds! % 60}s remaining',
                                    style: tt.labelSmall?.copyWith(
                                      color: FitoraColors.calmCyan,
                                      fontSize: 10,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              soundState.isPlaying
                                  ? Icons.pause_circle_filled_rounded
                                  : Icons.play_circle_filled_rounded,
                              color: soundState.activeTrack!.themeColor,
                              size: 34,
                            ),
                            onPressed: () => notifier.togglePlayPause(),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close_rounded,
                              color: Colors.white54,
                              size: 20,
                            ),
                            onPressed: () => notifier.stop(),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.volume_down_rounded, color: Colors.white38, size: 16),
                          Expanded(
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 3,
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                activeTrackColor: soundState.activeTrack!.themeColor,
                                inactiveTrackColor: Colors.white12,
                                thumbColor: soundState.activeTrack!.themeColor,
                              ),
                              child: Slider(
                                value: soundState.volume,
                                onChanged: (val) => notifier.setVolume(val),
                              ),
                            ),
                          ),
                          const Icon(Icons.volume_up_rounded, color: Colors.white70, size: 16),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
