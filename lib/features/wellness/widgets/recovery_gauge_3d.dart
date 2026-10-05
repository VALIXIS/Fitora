import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fitora/core/theme/fitora_colors.dart';
import 'package:fitora/core/theme/fitora_spacing.dart';

/// Enum representing the recovery tier based on the score percentage.
enum RecoveryTier {
  peak,
  moderate,
  restDay;

  static RecoveryTier fromScore(num score) {
    if (score >= 80) return RecoveryTier.peak;
    if (score >= 50) return RecoveryTier.moderate;
    return RecoveryTier.restDay;
  }

  String get label {
    switch (this) {
      case RecoveryTier.peak:
        return 'PEAK READINESS';
      case RecoveryTier.moderate:
        return 'MODERATE RECOVERY';
      case RecoveryTier.restDay:
        return 'REST DAY';
    }
  }

  String get shortLabel {
    switch (this) {
      case RecoveryTier.peak:
        return 'Peak';
      case RecoveryTier.moderate:
        return 'Moderate';
      case RecoveryTier.restDay:
        return 'Rest Day';
    }
  }

  String get advice {
    switch (this) {
      case RecoveryTier.peak:
        return 'High energy • Primed for heavy training & peak performance';
      case RecoveryTier.moderate:
        return 'Balanced baseline • Suitable for steady-state training';
      case RecoveryTier.restDay:
        return 'Active recovery needed • Prioritize deep sleep & gentle hydration';
    }
  }

  List<Color> get gradientColors {
    switch (this) {
      case RecoveryTier.peak:
        return const [
          Color(0xFF00F5A0), // Electric neon mint
          Color(0xFF10B981), // Emerald green
          Color(0xFF06B6D4), // Vibrant cyan
        ];
      case RecoveryTier.moderate:
        return const [
          Color(0xFFFBBF24), // Bright gold
          Color(0xFFF59E0B), // Radiant amber
          Color(0xFFFB923C), // Warm coral-orange
        ];
      case RecoveryTier.restDay:
        return const [
          Color(0xFF38BDF8), // Sky neon blue
          Color(0xFF3B82F6), // Electric cobalt blue
          Color(0xFF6366F1), // Royal indigo
        ];
    }
  }

  Color get primaryGlow {
    switch (this) {
      case RecoveryTier.peak:
        return const Color(0xFF10B981);
      case RecoveryTier.moderate:
        return const Color(0xFFF59E0B);
      case RecoveryTier.restDay:
        return const Color(0xFF3B82F6);
    }
  }

  Color get secondaryColor {
    switch (this) {
      case RecoveryTier.peak:
        return const Color(0xFF00F5A0);
      case RecoveryTier.moderate:
        return const Color(0xFFFBBF24);
      case RecoveryTier.restDay:
        return const Color(0xFF60A5FA);
    }
  }

  IconData get icon {
    switch (this) {
      case RecoveryTier.peak:
        return Icons.bolt_rounded;
      case RecoveryTier.moderate:
        return Icons.offline_bolt_rounded;
      case RecoveryTier.restDay:
        return Icons.bedtime_rounded;
    }
  }
}

/// A 3D interactive circular recovery score gauge widget featuring:
/// 1. Glowing neon blur sweep gradient arcs that dynamically shift between Green, Amber, and Blue.
/// 2. Interactive 3D tilt perspective responding to touches and gestures.
/// 3. Tap-to-inspect breakdown tooltip analyzing Sleep, Step, and Resting HR contributions.
class RecoveryGauge3D extends StatefulWidget {
  /// The recovery score between 0 and 100.
  final double score;

  /// Sleep contribution score/percentage (defaults to calculated 35% of total score).
  final double? sleepContribution;

  /// Daily step/activity contribution score/percentage (defaults to calculated 35% of total score).
  final double? stepContribution;

  /// Resting heart rate contribution score/percentage (defaults to calculated 30% of total score).
  final double? restingHrContribution;

  /// Sleep duration or label (e.g., '7h 45m' or '92% Quality').
  final String? sleepLabel;

  /// Step count or label (e.g., '8,450 steps').
  final String? stepLabel;

  /// Resting HR or label (e.g., '58 bpm' or 'Optimal HRV').
  final String? restingHrLabel;

  /// The dimension size of the circular gauge (width & height).
  final double size;

  /// Whether the gauge responds to touch gestures (tilt & tooltip toggle).
  final bool interactive;

  /// Optional callback when the gauge is tapped.
  final VoidCallback? onTap;

  /// Optional title override for the gauge card.
  final String? title;

  /// Whether to show the expandable breakdown panel below the gauge.
  final bool showBreakdownCard;

  /// Whether to run continuous breathing pulse animation (set to false for static screenshots or tests).
  final bool animatePulse;

  const RecoveryGauge3D({
    super.key,
    required this.score,
    this.sleepContribution,
    this.stepContribution,
    this.restingHrContribution,
    this.sleepLabel,
    this.stepLabel,
    this.restingHrLabel,
    this.size = 230.0,
    this.interactive = true,
    this.onTap,
    this.title,
    this.showBreakdownCard = true,
    this.animatePulse = true,
  });

  @override
  State<RecoveryGauge3D> createState() => _RecoveryGauge3DState();
}

class _RecoveryGauge3DState extends State<RecoveryGauge3D>
    with TickerProviderStateMixin {
  // 3D Tilt perspective controllers
  late AnimationController _tiltResetController;
  late Animation<double> _tiltXAnimation;
  late Animation<double> _tiltYAnimation;
  double _tiltX = 0.0; // [-1.0, 1.0]
  double _tiltY = 0.0; // [-1.0, 1.0]
  bool _isInteracting = false;

  // Pulse & glow ambient breathing animation
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Score arc sweep animation
  late AnimationController _scoreAnimationController;
  late Animation<double> _scoreAnimation;

  // Tooltip & breakdown expansion state
  bool _isBreakdownExpanded = false;

  @override
  void initState() {
    super.initState();

    // 1. Tilt spring-back controller
    _tiltResetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..addListener(() {
        setState(() {
          _tiltX = _tiltXAnimation.value;
          _tiltY = _tiltYAnimation.value;
        });
      });

    _tiltXAnimation = const AlwaysStoppedAnimation(0.0);
    _tiltYAnimation = const AlwaysStoppedAnimation(0.0);

    // 2. Ambient neon breathing pulse
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
      value: 1.0,
    );
    if (widget.animatePulse) {
      _pulseController.repeat(reverse: true);
    }

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine),
    );

    // 3. Score sweep animation
    _scoreAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    final clampedScore = widget.score.clamp(0.0, 100.0);
    _scoreAnimation = Tween<double>(begin: 0.0, end: clampedScore).animate(
      CurvedAnimation(
        parent: _scoreAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );
    _scoreAnimationController.forward();
  }

  @override
  void didUpdateWidget(covariant RecoveryGauge3D oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.score != widget.score) {
      final clampedScore = widget.score.clamp(0.0, 100.0);
      _scoreAnimation = Tween<double>(
        begin: _scoreAnimation.value,
        end: clampedScore,
      ).animate(
        CurvedAnimation(
          parent: _scoreAnimationController,
          curve: Curves.easeOutCubic,
        ),
      );
      _scoreAnimationController
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _tiltResetController.dispose();
    _pulseController.dispose();
    _scoreAnimationController.dispose();
    super.dispose();
  }

  void _handleTouchUpdate(Offset localPosition, Size widgetSize) {
    if (!widget.interactive) return;

    final centerX = widgetSize.width / 2;
    final centerY = widgetSize.height / 2;
    final dx = (localPosition.dx - centerX) / (widgetSize.width / 2);
    final dy = (localPosition.dy - centerY) / (widgetSize.height / 2);

    setState(() {
      _tiltX = dx.clamp(-1.0, 1.0);
      _tiltY = dy.clamp(-1.0, 1.0);
      _isInteracting = true;
    });
  }

  void _handleTouchStart(Offset localPosition, Size widgetSize) {
    if (!widget.interactive) return;
    _tiltResetController.stop();
    HapticFeedback.lightImpact();
    _handleTouchUpdate(localPosition, widgetSize);
  }

  void _handleTouchEnd() {
    if (!widget.interactive) return;
    _tiltXAnimation = Tween<double>(begin: _tiltX, end: 0.0).animate(
      CurvedAnimation(parent: _tiltResetController, curve: Curves.easeOutBack),
    );
    _tiltYAnimation = Tween<double>(begin: _tiltY, end: 0.0).animate(
      CurvedAnimation(parent: _tiltResetController, curve: Curves.easeOutBack),
    );
    _tiltResetController
      ..reset()
      ..forward();

    setState(() {
      _isInteracting = false;
    });
  }

  void _toggleBreakdown() {
    HapticFeedback.selectionClick();
    setState(() {
      _isBreakdownExpanded = !_isBreakdownExpanded;
    });
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tier = RecoveryTier.fromScore(widget.score);

    // Calculated breakdown factors
    final sleepPoints = widget.sleepContribution ??
        ((widget.score * 0.40).clamp(0.0, 40.0));
    final stepPoints = widget.stepContribution ??
        ((widget.score * 0.35).clamp(0.0, 35.0));
    final hrPoints = widget.restingHrContribution ??
        ((widget.score * 0.25).clamp(0.0, 25.0));

    // Dynamic 3D tilt transformation matrix
    const maxTiltAngle = 0.22; // ~12.5 degrees of perspective tilt
    final tiltMatrix = Matrix4.identity()
      ..setEntry(3, 2, 0.0016) // Perspective depth
      ..rotateX(-_tiltY * maxTiltAngle)
      ..rotateY(_tiltX * maxTiltAngle);
    final scaleVal = _isInteracting ? 0.97 : 1.0;
    tiltMatrix.scaleByDouble(scaleVal, scaleVal, 1.0, 1.0);

    return Semantics(
      label: 'Daily Recovery Score Gauge',
      value:
          '${widget.score.round()}% ${tier.label}. ${tier.advice}',
      hint: 'Tap to view or hide recovery breakdown tooltip',
      button: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Dial Container with 3D Tilt & Gesture Listener ────────────────
          GestureDetector(
            onTap: _toggleBreakdown,
            onPanDown: (details) =>
                _handleTouchStart(details.localPosition, Size(widget.size, widget.size)),
            onPanUpdate: (details) =>
                _handleTouchUpdate(details.localPosition, Size(widget.size, widget.size)),
            onPanEnd: (_) => _handleTouchEnd(),
            onPanCancel: () => _handleTouchEnd(),
            behavior: HitTestBehavior.opaque,
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _pulseAnimation,
                _scoreAnimation,
              ]),
              builder: (context, _) {
                final currentAnimatedScore = _scoreAnimation.value;
                final pulseScale = _pulseAnimation.value;

                return Transform(
                  alignment: Alignment.center,
                  transform: tiltMatrix,
                  child: Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        // Dynamic 3D ambient shadow shifted by tilt
                        BoxShadow(
                          color: tier.primaryGlow.withValues(
                            alpha: 0.20 * pulseScale,
                          ),
                          blurRadius: 36 * pulseScale,
                          spreadRadius: 2,
                          offset: Offset(_tiltX * 12, _tiltY * 12 + 6),
                        ),
                        // Dark depth drop shadow
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.60 : 0.12),
                          blurRadius: 20,
                          offset: Offset(_tiltX * 8, _tiltY * 8 + 10),
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Custom Painter for 3D Neon Bevel, Track, Arc & Ticks
                        CustomPaint(
                          size: Size(widget.size, widget.size),
                          painter: _RecoveryGaugePainter(
                            score: currentAnimatedScore,
                            tier: tier,
                            pulse: pulseScale,
                            tiltX: _tiltX,
                            tiltY: _tiltY,
                            isDark: isDark,
                          ),
                        ),

                        // Center Content (Score, Badges, Advice)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: 10),
                              // Glowing Status Badge Pill
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: tier.primaryGlow.withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: tier.primaryGlow.withValues(alpha: 0.45),
                                    width: 1.0,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      tier.icon,
                                      size: 13,
                                      color: tier.secondaryColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      tier.shortLabel.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.2,
                                        color: tier.secondaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 6),

                              // Big Score Percentage
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    currentAnimatedScore.round().toString(),
                                    style: TextStyle(
                                      fontSize: widget.size * 0.22,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -1.5,
                                      color: isDark ? Colors.white : FitoraColors.lightTextPrimary,
                                      shadows: [
                                        Shadow(
                                          color: tier.primaryGlow.withValues(alpha: 0.55),
                                          blurRadius: 16,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '%',
                                    style: TextStyle(
                                      fontSize: widget.size * 0.10,
                                      fontWeight: FontWeight.w700,
                                      color: tier.secondaryColor,
                                    ),
                                  ),
                                ],
                              ),

                              // Subtitle / Tooltip hint
                              Text(
                                _isBreakdownExpanded ? 'TAP TO HIDE' : 'RECOVERY SCORE',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.4,
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.55)
                                      : FitoraColors.lightTextSecondary,
                                ),
                              ),
                              const SizedBox(height: 14),
                            ],
                          ),
                        ),

                        // Interactive HUD touch indicator overlay
                        if (_isInteracting)
                          Positioned(
                            bottom: 16,
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 150),
                              opacity: _isInteracting ? 1.0 : 0.0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.75),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: tier.primaryGlow.withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Text(
                                  '3D TILT ACTIVE',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.0,
                                    color: tier.secondaryColor,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // ── Breakdown Tooltip Card (Expandable on Touch/Tap) ───────────────
          if (widget.showBreakdownCard)
            AnimatedSize(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              child: _isBreakdownExpanded
                  ? Padding(
                      padding: const EdgeInsets.only(top: FitoraSpacing.md),
                      child: _buildBreakdownCard(
                        context,
                        tier,
                        sleepPoints,
                        stepPoints,
                        hrPoints,
                        isDark,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
        ],
      ),
    );
  }

  /// Builds the breakdown tooltip card detailing Sleep, Step, and Resting HR metrics.
  Widget _buildBreakdownCard(
    BuildContext context,
    RecoveryTier tier,
    double sleepPoints,
    double stepPoints,
    double hrPoints,
    bool isDark,
  ) {
    final theme = Theme.of(context);
    final cardBg = isDark
        ? FitoraColors.darkSurfaceVariant.withValues(alpha: 0.85)
        : FitoraColors.lightSurfaceVariant.withValues(alpha: 0.95);

    final sleepLabel = widget.sleepLabel ?? '${sleepPoints.round()} pts (40% weight)';
    final stepLabel = widget.stepLabel ?? '${stepPoints.round()} pts (35% weight)';
    final hrLabel = widget.restingHrLabel ?? '${hrPoints.round()} pts (25% weight)';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(FitoraSpacing.md),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: tier.primaryGlow.withValues(alpha: 0.30),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: tier.primaryGlow.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: tier.primaryGlow.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.analytics_rounded,
                  size: 16,
                  color: tier.secondaryColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Readiness Factors Breakdown',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                tooltip: 'Close breakdown',
                onPressed: _toggleBreakdown,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            tier.advice,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.70)
                  : FitoraColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: FitoraSpacing.md),

          // Factor 1: Sleep
          _buildFactorRow(
            context: context,
            icon: Icons.nightlight_round,
            iconColor: const Color(0xFF818CF8),
            title: 'Sleep Duration & Quality',
            subtitle: sleepLabel,
            contributionRatio: (sleepPoints / 40.0).clamp(0.0, 1.0),
            pointsText: '+${sleepPoints.round()} pts',
            isDark: isDark,
          ),
          const SizedBox(height: FitoraSpacing.sm),

          // Factor 2: Steps & Movement
          _buildFactorRow(
            context: context,
            icon: Icons.directions_walk_rounded,
            iconColor: const Color(0xFF34D399),
            title: 'Movement & Step Target',
            subtitle: stepLabel,
            contributionRatio: (stepPoints / 35.0).clamp(0.0, 1.0),
            pointsText: '+${stepPoints.round()} pts',
            isDark: isDark,
          ),
          const SizedBox(height: FitoraSpacing.sm),

          // Factor 3: Hydration & Rest / Stress Recovery
          _buildFactorRow(
            context: context,
            icon: hrLabel.contains('Hydration') ? Icons.water_drop_rounded : Icons.favorite_rounded,
            iconColor: hrLabel.contains('Hydration') ? const Color(0xFF38BDF8) : const Color(0xFFF472B6),
            title: hrLabel.contains('Hydration') ? 'Hydration & Rest Recovery' : 'Resting HR & Stress Recovery',
            subtitle: hrLabel,
            contributionRatio: (hrPoints / 30.0).clamp(0.0, 1.0),
            pointsText: '+${hrPoints.round()} pts',
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildFactorRow({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required double contributionRatio,
    required String pointsText,
    required bool isDark,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withValues(alpha: 0.25)
            : Colors.white.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                pointsText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: iconColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Progress ratio bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: contributionRatio,
              minHeight: 4,
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation<Color>(iconColor),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 11,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.55)
                  : FitoraColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter rendering the 3D Dial:
/// - Inset metallic bevel ring with radial lighting
/// - Background open arc track
/// - Dynamic Glowing SweepGradient neon arc with dual blur passes
/// - Tip cap with glowing indicator bead
/// - Subtle tick graduation marks
class _RecoveryGaugePainter extends CustomPainter {
  final double score; // [0, 100]
  final RecoveryTier tier;
  final double pulse;
  final double tiltX;
  final double tiltY;
  final bool isDark;

  // Gauge angles: 260 degree arc with opening at the bottom
  static const double _startAngle = 140 * (math.pi / 180); // 140 deg
  static const double _sweepTotal = 260 * (math.pi / 180); // 260 deg

  _RecoveryGaugePainter({
    required this.score,
    required this.tier,
    required this.pulse,
    required this.tiltX,
    required this.tiltY,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 18.0;
    final strokeWidth = size.width * 0.075; // Responsive stroke width

    final rect = Rect.fromCircle(center: center, radius: radius);
    final progressFraction = (score / 100.0).clamp(0.0, 1.0);
    final currentSweep = _sweepTotal * progressFraction;

    // ── 1. Inset 3D Bevel Center Plate ─────────────────────────────────────────
    final platePaint = Paint()
      ..shader = RadialGradient(
        center: Alignment(tiltX * 0.35 - 0.2, tiltY * 0.35 - 0.2),
        radius: 0.85,
        colors: isDark
            ? [
                FitoraColors.darkSurfaceVariant,
                FitoraColors.darkBg,
                const Color(0xFF080D0B),
              ]
            : [
                Colors.white,
                FitoraColors.lightSurfaceVariant,
                const Color(0xFFE2E8E6),
              ],
        stops: const [0.0, 0.7, 1.0],
      ).createShader(rect);

    canvas.drawCircle(center, radius - strokeWidth * 0.65, platePaint);

    // Subtle 3D Inner Bevel Highlight Rim
    final bevelPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..shader = LinearGradient(
        begin: Alignment(tiltX - 0.7, tiltY - 0.7),
        end: Alignment(tiltX + 0.7, tiltY + 0.7),
        colors: isDark
            ? [
                Colors.white.withValues(alpha: 0.25),
                Colors.white.withValues(alpha: 0.02),
                Colors.black.withValues(alpha: 0.40),
              ]
            : [
                Colors.white.withValues(alpha: 0.80),
                Colors.white.withValues(alpha: 0.10),
                Colors.black.withValues(alpha: 0.15),
              ],
      ).createShader(rect);

    canvas.drawCircle(center, radius - strokeWidth * 0.65, bevelPaint);

    // ── 2. Background Track Arc ───────────────────────────────────────────────
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.07)
          : Colors.black.withValues(alpha: 0.06);

    canvas.drawArc(rect, _startAngle, _sweepTotal, false, trackPaint);

    // ── 3. Dial Tick Graduation Marks ─────────────────────────────────────────
    final tickCount = 26;
    for (int i = 0; i <= tickCount; i++) {
      final tickFraction = i / tickCount;
      final tickAngle = _startAngle + (_sweepTotal * tickFraction);
      final isTickActive = tickFraction <= progressFraction;

      final innerTickR = radius - strokeWidth * 0.95;
      final outerTickR = radius - strokeWidth * 0.70;

      final p1 = Offset(
        center.dx + innerTickR * math.cos(tickAngle),
        center.dy + innerTickR * math.sin(tickAngle),
      );
      final p2 = Offset(
        center.dx + outerTickR * math.cos(tickAngle),
        center.dy + outerTickR * math.sin(tickAngle),
      );

      final tickPaint = Paint()
        ..strokeWidth = (i % 5 == 0) ? 1.8 : 1.0
        ..strokeCap = StrokeCap.round
        ..color = isTickActive
            ? tier.secondaryColor.withValues(alpha: 0.75)
            : (isDark
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.15));

      canvas.drawLine(p1, p2, tickPaint);
    }

    if (currentSweep <= 0.001) return;

    // ── 4. Glowing Neon Shaders (Dynamic Color Shifts) ─────────────────────────
    final colors = tier.gradientColors;
    final sweepGradient = SweepGradient(
      startAngle: _startAngle,
      endAngle: _startAngle + _sweepTotal,
      colors: colors,
      transform: const GradientRotation(0.0),
    );

    // A. Deep Ambient Neon Halo Blur
    final deepGlowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 2.2
      ..strokeCap = StrokeCap.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 20.0 * pulse)
      ..color = tier.primaryGlow.withValues(alpha: 0.28 * pulse);

    canvas.drawArc(rect, _startAngle, currentSweep, false, deepGlowPaint);

    // B. Intense Inner Neon Core Blur
    final coreGlowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 1.4
      ..strokeCap = StrokeCap.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8.0 * pulse)
      ..color = tier.primaryGlow.withValues(alpha: 0.55 * pulse);

    canvas.drawArc(rect, _startAngle, currentSweep, false, coreGlowPaint);

    // C. Sharp Foreground Sweep Arc
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = sweepGradient.createShader(rect);

    canvas.drawArc(rect, _startAngle, currentSweep, false, arcPaint);

    // ── 5. Leading Tip Glowing Bead ───────────────────────────────────────────
    final tipAngle = _startAngle + currentSweep;
    final tipCenter = Offset(
      center.dx + radius * math.cos(tipAngle),
      center.dy + radius * math.sin(tipAngle),
    );

    // Bead outer glow
    final tipGlowPaint = Paint()
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 10.0 * pulse)
      ..color = tier.secondaryColor.withValues(alpha: 0.85);
    canvas.drawCircle(tipCenter, strokeWidth * 0.75, tipGlowPaint);

    // Bead color ring
    final tipRingPaint = Paint()..color = tier.secondaryColor;
    canvas.drawCircle(tipCenter, strokeWidth * 0.45, tipRingPaint);

    // Bead hot white center core
    final tipCorePaint = Paint()..color = Colors.white;
    canvas.drawCircle(tipCenter, strokeWidth * 0.22, tipCorePaint);
  }

  @override
  bool shouldRepaint(covariant _RecoveryGaugePainter oldDelegate) {
    return oldDelegate.score != score ||
        oldDelegate.tier != tier ||
        oldDelegate.pulse != pulse ||
        oldDelegate.tiltX != tiltX ||
        oldDelegate.tiltY != tiltY ||
        oldDelegate.isDark != isDark;
  }
}
