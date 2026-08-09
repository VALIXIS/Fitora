import 'package:flutter/material.dart';
import 'package:fitora/features/workouts/domain/exercise_models.dart';

class ExerciseMedia extends StatefulWidget {
  final String? gifPath;
  final TargetMuscle targetMuscle;
  final double height;

  const ExerciseMedia({
    super.key,
    this.gifPath,
    required this.targetMuscle,
    this.height = 160,
  });

  @override
  State<ExerciseMedia> createState() => _ExerciseMediaState();
}

class _ExerciseMediaState extends State<ExerciseMedia> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Future video architecture notes:
    // When video (MP4) support is added:
    // if (widget.gifPath != null && widget.gifPath!.endsWith('.mp4')) {
    //   return VideoPlayerWidget(url: widget.gifPath!);
    // }

    if (widget.gifPath != null && widget.gifPath!.isNotEmpty) {
      return Container(
        height: widget.height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: Image.asset(
            widget.gifPath!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              // Graceful fallback if gif is registered in code but not in local assets yet
              return _buildFallback(context, isError: true);
            },
          ),
        ),
      );
    }

    return _buildFallback(context);
  }

  Widget _buildFallback(BuildContext context, {bool isError = false}) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      height: widget.height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Center(
        child: ScaleTransition(
          scale: _pulseAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _iconFor(widget.targetMuscle),
                  size: 36,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.targetMuscle.label,
                style: textTheme.labelLarge?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isError) ...[
                const SizedBox(height: 2),
                Text(
                  'Preview loading...',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                    fontSize: 10,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconFor(TargetMuscle muscle) {
    switch (muscle) {
      case TargetMuscle.fullBody:
        return Icons.self_improvement_rounded;
      case TargetMuscle.upperBody:
        return Icons.fitness_center_rounded;
      case TargetMuscle.lowerBody:
        return Icons.accessibility_new_rounded;
      case TargetMuscle.core:
        return Icons.directions_run_rounded;
      case TargetMuscle.cardio:
        return Icons.favorite_rounded;
      case TargetMuscle.mobility:
        return Icons.align_vertical_bottom_rounded;
      case TargetMuscle.recovery:
        return Icons.spa_rounded;
    }
  }
}
