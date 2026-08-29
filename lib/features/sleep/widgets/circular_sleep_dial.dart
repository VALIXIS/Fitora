import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fitora/core/theme/fitora_colors.dart';
import 'package:fitora/core/health/domain/sleep_calculations.dart';

class CircularSleepDial extends StatefulWidget {
  final int initialBedHour;
  final int initialBedMinute;
  final int initialWakeHour;
  final int initialWakeMinute;
  final void Function(int bedHour, int bedMinute, int wakeHour, int wakeMinute) onChanged;

  const CircularSleepDial({
    super.key,
    required this.initialBedHour,
    required this.initialBedMinute,
    required this.initialWakeHour,
    required this.initialWakeMinute,
    required this.onChanged,
  });

  @override
  State<CircularSleepDial> createState() => _CircularSleepDialState();
}

class _CircularSleepDialState extends State<CircularSleepDial> {
  late int _bedHour;
  late int _bedMinute;
  late int _wakeHour;
  late int _wakeMinute;

  bool _draggingBedtime = false;
  bool _draggingWakeTime = false;

  @override
  void initState() {
    super.initState();
    _bedHour = widget.initialBedHour;
    _bedMinute = widget.initialBedMinute;
    _wakeHour = widget.initialWakeHour;
    _wakeMinute = widget.initialWakeMinute;
  }

  // Convert hour/minute to canvas angle in radians where Midnight is at the top (-pi/2)
  double _timeToAngle(int hour, int minute) {
    final minutes = hour * 60 + minute;
    return (minutes / 1440.0) * 2 * pi - pi / 2;
  }

  // Convert canvas angle in radians to snapped minutes of the day (0-1440)
  int _angleToMinutes(double angle) {
    // Normalize angle to [0, 2*pi] with midnight (top, -pi/2) as 0
    double normalized = (angle + pi / 2) % (2 * pi);
    if (normalized < 0) {
      normalized += 2 * pi;
    }
    final rawMinutes = (normalized / (2 * pi)) * 1440.0;
    // Snap to nearest 10 minutes
    return ((rawMinutes / 10).round() * 10) % 1440;
  }

  void _handlePanStart(DragStartDetails details, Size size, double radius) {
    final center = Offset(size.width / 2, size.height / 2);
    final touchOffset = details.localPosition - center;

    final bedAngle = _timeToAngle(_bedHour, _bedMinute);
    final wakeAngle = _timeToAngle(_wakeHour, _wakeMinute);

    // Bedtime handle position
    final bedOffset = Offset(cos(bedAngle) * radius, sin(bedAngle) * radius);
    // Wake handle position
    final wakeOffset = Offset(cos(wakeAngle) * radius, sin(wakeAngle) * radius);

    final distToBed = (touchOffset - bedOffset).distance;
    final distToWake = (touchOffset - wakeOffset).distance;

    // Detect if we touched near either handle (40px threshold)
    if (distToBed < 40 || distToWake < 40) {
      if (distToBed < distToWake) {
        _draggingBedtime = true;
        _draggingWakeTime = false;
      } else {
        _draggingBedtime = false;
        _draggingWakeTime = true;
      }
    }
  }

  void _handlePanUpdate(DragUpdateDetails details, Size size, double radius) {
    if (!_draggingBedtime && !_draggingWakeTime) return;

    final center = Offset(size.width / 2, size.height / 2);
    final touchOffset = details.localPosition - center;
    final touchAngle = atan2(touchOffset.dy, touchOffset.dx);

    final snappedMinutes = _angleToMinutes(touchAngle);
    final newHour = snappedMinutes ~/ 60;
    final newMin = snappedMinutes % 60;

    setState(() {
      if (_draggingBedtime) {
        _bedHour = newHour;
        _bedMinute = newMin;
      } else if (_draggingWakeTime) {
        _wakeHour = newHour;
        _wakeMinute = newMin;
      }
    });

    widget.onChanged(_bedHour, _bedMinute, _wakeHour, _wakeMinute);
  }

  void _handlePanEnd(DragEndDetails details) {
    _draggingBedtime = false;
    _draggingWakeTime = false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tt = theme.textTheme;
    final duration = SleepCalculations.calculateTargetDuration(
      _bedHour,
      _bedMinute,
      _wakeHour,
      _wakeMinute,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final dialSize = min(size.width, size.height);
        final radius = (dialSize / 2) - 30;

        return GestureDetector(
          onPanStart: (details) => _handlePanStart(details, size, radius),
          onPanUpdate: (details) => _handlePanUpdate(details, size, radius),
          onPanEnd: _handlePanEnd,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(dialSize, dialSize),
                painter: _SleepDialPainter(
                  bedAngle: _timeToAngle(_bedHour, _bedMinute),
                  wakeAngle: _timeToAngle(_wakeHour, _wakeMinute),
                  radius: radius,
                  activeHandleColor: FitoraColors.calmCyan,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'SLEEP DURATION',
                    style: tt.labelSmall?.copyWith(
                      color: Colors.white30,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${duration.inHours}h ${duration.inMinutes.remainder(60)}m',
                    style: tt.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.bedtime_outlined, size: 14, color: FitoraColors.calmCyan),
                              const SizedBox(width: 4),
                              Text(
                                'Bedtime',
                                style: tt.labelSmall?.copyWith(color: Colors.white30),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            SleepCalculations.formatTimeOfDay(_bedHour, _bedMinute),
                            style: tt.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                      Container(
                        height: 24,
                        width: 1,
                        color: Colors.white10,
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      Column(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.alarm_outlined, size: 14, color: FitoraColors.mintGreen),
                              const SizedBox(width: 4),
                              Text(
                                'Wake up',
                                style: tt.labelSmall?.copyWith(color: Colors.white30),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            SleepCalculations.formatTimeOfDay(_wakeHour, _wakeMinute),
                            style: tt.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SleepDialPainter extends CustomPainter {
  final double bedAngle;
  final double wakeAngle;
  final double radius;
  final Color activeHandleColor;

  _SleepDialPainter({
    required this.bedAngle,
    required this.wakeAngle,
    required this.radius,
    required this.activeHandleColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // 1. Draw outer circle track
    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    // 2. Draw sleep arc
    double sweep = wakeAngle - bedAngle;
    if (sweep < 0) {
      sweep += 2 * pi;
    }
    final arcPaint = Paint()
      ..color = FitoraColors.calmCyan.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      bedAngle,
      sweep,
      false,
      arcPaint,
    );

    // 3. Draw clock ticks (optional visual guide for 12, 6, 18 hours)
    final tickPaint = Paint()
      ..color = Colors.white24
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (int i = 0; i < 24; i++) {
      final tickAngle = i * (2 * pi / 24) - pi / 2;
      final isMajor = i % 6 == 0;
      final len = isMajor ? 8.0 : 4.0;
      final p1 = Offset(
        center.dx + cos(tickAngle) * (radius - 20),
        center.dy + sin(tickAngle) * (radius - 20),
      );
      final p2 = Offset(
        center.dx + cos(tickAngle) * (radius - 20 - len),
        center.dy + sin(tickAngle) * (radius - 20 - len),
      );
      canvas.drawLine(p1, p2, tickPaint);
    }

    // 4. Draw Bedtime handle (bed icon or circular handle)
    final bedX = center.dx + cos(bedAngle) * radius;
    final bedY = center.dy + sin(bedAngle) * radius;
    final handlePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(bedX, bedY), 16, handlePaint);

    final borderPaint = Paint()
      ..color = FitoraColors.calmCyan
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(Offset(bedX, bedY), 16, borderPaint);

    // 5. Draw Wake-up handle
    final wakeX = center.dx + cos(wakeAngle) * radius;
    final wakeY = center.dy + sin(wakeAngle) * radius;
    canvas.drawCircle(Offset(wakeX, wakeY), 16, handlePaint);

    final wakeBorderPaint = Paint()
      ..color = FitoraColors.mintGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(Offset(wakeX, wakeY), 16, wakeBorderPaint);
  }

  @override
  bool shouldRepaint(covariant _SleepDialPainter oldDelegate) {
    return oldDelegate.bedAngle != bedAngle ||
        oldDelegate.wakeAngle != wakeAngle ||
        oldDelegate.radius != radius;
  }
}
