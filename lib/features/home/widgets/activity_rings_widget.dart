import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fitora/core/health/domain/health_models.dart';
import 'package:fitora/core/theme/fitora_colors.dart';

class ActivityRingsWidget extends StatelessWidget {
  final DailyActivitySummary summary;
  final double size;

  const ActivityRingsWidget({
    super.key,
    required this.summary,
    this.size = 240,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer Ring: Steps (Mint Green)
          _ConcentricRing(
            size: size,
            progress: summary.stepsProgress,
            color: FitoraColors.mintGreen,
            strokeWidth: size * 0.08,
            icon: Icons.directions_walk_rounded,
          ),
          // Middle Ring: Calories (Warning Orange)
          _ConcentricRing(
            size: size * 0.76,
            progress: summary.caloriesProgress,
            color: FitoraColors.warningOrange,
            strokeWidth: size * 0.08,
            icon: Icons.local_fire_department_rounded,
          ).animate().fadeIn(delay: 100.ms).scale(),
          // Inner Ring: Active Minutes (Calm Cyan)
          _ConcentricRing(
            size: size * 0.52,
            progress: summary.activeMinutesProgress,
            color: FitoraColors.calmCyan,
            strokeWidth: size * 0.08,
            icon: Icons.timer_rounded,
          ).animate().fadeIn(delay: 200.ms).scale(),
        ],
      ),
    );
  }
}

class _ConcentricRing extends StatelessWidget {
  final double size;
  final double progress;
  final Color color;
  final double strokeWidth;
  final IconData icon;

  const _ConcentricRing({
    required this.size,
    required this.progress,
    required this.color,
    required this.strokeWidth,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 15, spreadRadius: 2),
              ],
            ),
          ),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: progress),
            duration: const Duration(milliseconds: 1500),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return CustomPaint(
                size: Size(size, size),
                painter: _RingPainter(
                  progress: value,
                  color: color,
                  strokeWidth: strokeWidth,
                  backgroundColor: color.withValues(alpha: 0.15),
                ),
              );
            },
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: EdgeInsets.only(top: strokeWidth * 0.1),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0E1312),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(2),
                child: Icon(icon, size: strokeWidth * 0.6, color: color),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;
  final Color backgroundColor;

  _RingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, bgPaint);

    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2, // Start at top
      sweepAngle,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
