import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fitora/core/theme/fitora_colors.dart';
import 'package:fitora/features/gamification/domain/gamification_models.dart';
import 'package:fitora/core/services/shareable_image_service.dart';
import 'package:fitora/features/progress/domain/shareable_milestone_models.dart';

/// Interactive 3D Trophy Badge Card featuring:
/// 1. Dynamic 3D metallic shine shaders (Gold, Silver, Bronze, Emerald, Diamond, Obsidian).
/// 2. Interactive touch/pan 3D tilt perspective.
/// 3. Tap-to-flip/expand modal revealing achievement stats, progress bar, and unlock date.
class Badge3DCard extends StatefulWidget {
  final AchievementBadge badge;
  final VoidCallback? onCelebrate;
  final double width;
  final double height;
  final bool animateShine;

  const Badge3DCard({
    super.key,
    required this.badge,
    this.onCelebrate,
    this.width = 170.0,
    this.height = 210.0,
    this.animateShine = true,
  });

  @override
  State<Badge3DCard> createState() => _Badge3DCardState();
}

class _Badge3DCardState extends State<Badge3DCard>
    with TickerProviderStateMixin {
  // 3D Tilt perspective controllers
  late AnimationController _tiltResetController;
  late Animation<double> _tiltXAnimation;
  late Animation<double> _tiltYAnimation;
  double _tiltX = 0.0;
  double _tiltY = 0.0;
  bool _isInteracting = false;

  // Specular metallic shine sweep animation
  late AnimationController _shineController;
  late Animation<double> _shineAnimation;

  // Flip/Detail expansion state
  bool _isFlipped = false;
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;

  @override
  void initState() {
    super.initState();

    // 1. Tilt spring-back physics
    _tiltResetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    )..addListener(() {
        setState(() {
          _tiltX = _tiltXAnimation.value;
          _tiltY = _tiltYAnimation.value;
        });
      });
    _tiltXAnimation = const AlwaysStoppedAnimation(0.0);
    _tiltYAnimation = const AlwaysStoppedAnimation(0.0);

    // 2. Continuous metallic specular sweep
    _shineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );
    _shineAnimation = Tween<double>(begin: -1.2, end: 2.2).animate(
      CurvedAnimation(parent: _shineController, curve: Curves.easeInOutSine),
    );
    if (widget.animateShine && widget.badge.isUnlocked) {
      _shineController.repeat(period: const Duration(milliseconds: 3600));
    }

    // 3. Card flip animation
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _flipAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeOutBack),
    );
  }

  @override
  void didUpdateWidget(covariant Badge3DCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.badge.isUnlocked && !_shineController.isAnimating && widget.animateShine) {
      _shineController.repeat(period: const Duration(milliseconds: 3600));
    }
  }

  @override
  void dispose() {
    _tiltResetController.dispose();
    _shineController.dispose();
    _flipController.dispose();
    super.dispose();
  }

  void _handleTouchUpdate(Offset localPosition, Size cardSize) {
    final centerX = cardSize.width / 2;
    final centerY = cardSize.height / 2;
    final dx = (localPosition.dx - centerX) / (cardSize.width / 2);
    final dy = (localPosition.dy - centerY) / (cardSize.height / 2);

    setState(() {
      _tiltX = dx.clamp(-1.0, 1.0);
      _tiltY = dy.clamp(-1.0, 1.0);
      _isInteracting = true;
    });
  }

  void _handleTouchStart(Offset localPosition, Size cardSize) {
    _tiltResetController.stop();
    HapticFeedback.lightImpact();
    _handleTouchUpdate(localPosition, cardSize);
  }

  void _handleTouchEnd() {
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

  void _toggleFlip() {
    HapticFeedback.mediumImpact();
    if (_isFlipped) {
      _flipController.reverse();
    } else {
      _flipController.forward();
      if (widget.badge.isUnlocked) {
        widget.onCelebrate?.call();
      }
    }
    setState(() {
      _isFlipped = !_isFlipped;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final badge = widget.badge;
    final isUnlocked = badge.isUnlocked;

    // Perspective transformation matrix
    const maxTilt = 0.20;
    final tiltMatrix = Matrix4.identity()
      ..setEntry(3, 2, 0.0016)
      ..rotateX(-_tiltY * maxTilt)
      ..rotateY(_tiltX * maxTilt);
    final scaleVal = _isInteracting ? 0.96 : 1.0;
    tiltMatrix.scaleByDouble(scaleVal, scaleVal, 1.0, 1.0);

    return Semantics(
      button: true,
      label: '${badge.title} Badge',
      value: isUnlocked
          ? 'Unlocked on ${badge.formattedUnlockDate}. ${badge.description}'
          : 'Locked. Progress: ${badge.currentProgress ?? "In progress"}',
      hint: 'Tap to inspect achievement stats and unlock date',
      child: GestureDetector(
        onTap: _toggleFlip,
        onPanDown: (details) => _handleTouchStart(
          details.localPosition,
          Size(widget.width, widget.height),
        ),
        onPanUpdate: (details) => _handleTouchUpdate(
          details.localPosition,
          Size(widget.width, widget.height),
        ),
        onPanEnd: (_) => _handleTouchEnd(),
        onPanCancel: () => _handleTouchEnd(),
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _shineAnimation,
            _flipAnimation,
          ]),
          builder: (context, _) {
            final flipVal = _flipAnimation.value;
            final isFront = flipVal < 0.5;

            return Transform(
              alignment: Alignment.center,
              transform: tiltMatrix,
              child: Container(
                width: widget.width,
                height: widget.height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    // Dynamic ambient glow shifted by 3D tilt
                    BoxShadow(
                      color: isUnlocked
                          ? badge.glowColor.withValues(alpha: 0.35)
                          : Colors.black.withValues(alpha: 0.20),
                      blurRadius: isUnlocked ? 22 : 10,
                      spreadRadius: isUnlocked ? 1 : 0,
                      offset: Offset(_tiltX * 10, _tiltY * 10 + 6),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.55 : 0.12),
                      blurRadius: 14,
                      offset: Offset(_tiltX * 6, _tiltY * 6 + 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Stack(
                    children: [
                      // ── Card Base with Metallic Bevel ─────────────────────
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _MetallicBevelPainter(
                            metallicColors: badge.metallicGradient,
                            isUnlocked: isUnlocked,
                            tiltX: _tiltX,
                            tiltY: _tiltY,
                            isDark: isDark,
                          ),
                        ),
                      ),

                      // ── 3D Specular Light Sweep Shine ─────────────────────
                      if (isUnlocked && widget.animateShine)
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _MetallicShineSweepPainter(
                              shineProgress: _shineAnimation.value,
                              glowColor: badge.glowColor,
                            ),
                          ),
                        ),

                      // ── Content: Front Face or Stats Back Face ───────────
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: isFront
                              ? _buildFrontFace(context, badge, isUnlocked, isDark)
                              : _buildBackFace(context, badge, isUnlocked, isDark),
                        ),
                      ),

                      // ── Locked Padlock Corner Badge ──────────────────────
                      if (!isUnlocked)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                                width: 1,
                              ),
                            ),
                            child: const Icon(
                              Icons.lock_rounded,
                              size: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ),

                      // ── Unlocked Ribbon Badge ────────────────────────────
                      if (isUnlocked)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: badge.glowColor.withValues(alpha: 0.25),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: badge.glowColor.withValues(alpha: 0.70),
                                width: 1.2,
                              ),
                            ),
                            child: Icon(
                              Icons.check_rounded,
                              size: 13,
                              color: badge.glowColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Front face displaying the 3D embossed medallion, title, and tier badge
  Widget _buildFrontFace(
    BuildContext context,
    AchievementBadge badge,
    bool isUnlocked,
    bool isDark,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 6),
        // 3D Embossed Medallion
        Center(
          child: Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: Alignment(_tiltX * 0.4 - 0.2, _tiltY * 0.4 - 0.2),
                radius: 0.85,
                colors: badge.metallicGradient,
              ),
              boxShadow: [
                BoxShadow(
                  color: isUnlocked
                      ? badge.glowColor.withValues(alpha: 0.45)
                      : Colors.black.withValues(alpha: 0.4),
                  blurRadius: 14,
                  spreadRadius: 1,
                ),
              ],
              border: Border.all(
                color: isUnlocked
                    ? Colors.white.withValues(alpha: 0.75)
                    : Colors.white.withValues(alpha: 0.15),
                width: 2.0,
              ),
            ),
            child: Icon(
              badge.iconData,
              size: 38,
              color: isUnlocked
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.40),
              shadows: isUnlocked
                  ? [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.45),
                        blurRadius: 6,
                        offset: const Offset(1, 2),
                      ),
                    ]
                  : null,
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Badge Title
        Text(
          badge.title,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: isUnlocked
                ? (isDark ? Colors.white : FitoraColors.lightTextPrimary)
                : (isDark ? Colors.white60 : Colors.black54),
            letterSpacing: 0.2,
          ),
        ),

        const SizedBox(height: 4),

        // Tier / Milestone pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
          decoration: BoxDecoration(
            color: isUnlocked
                ? badge.glowColor.withValues(alpha: 0.18)
                : Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isUnlocked
                  ? badge.glowColor.withValues(alpha: 0.40)
                  : Colors.white.withValues(alpha: 0.12),
              width: 0.8,
            ),
          ),
          child: Text(
            isUnlocked
                ? badge.tier.toUpperCase()
                : (badge.statRequirement ?? 'LOCKED'),
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
              color: isUnlocked ? badge.glowColor : Colors.white60,
            ),
          ),
        ),

        const Spacer(),

        // Tap hint microcopy
        Text(
          'TAP FOR STATS',
          style: TextStyle(
            fontSize: 8.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: isDark ? Colors.white38 : Colors.black38,
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  /// Back face revealing unlock date, achievement stats, and milestone details
  Widget _buildBackFace(
    BuildContext context,
    AchievementBadge badge,
    bool isUnlocked,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header with close indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isUnlocked
                    ? badge.glowColor.withValues(alpha: 0.2)
                    : Colors.white10,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                isUnlocked ? 'UNLOCKED' : 'IN PROGRESS',
                style: TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: isUnlocked ? badge.glowColor : Colors.white70,
                ),
              ),
            ),
            const Icon(Icons.flip_rounded, size: 14, color: Colors.white54),
          ],
        ),

        const SizedBox(height: 6),

        // Description
        Text(
          badge.description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: Colors.white70,
            height: 1.2,
          ),
        ),

        const Spacer(),

        // Stats Section
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isUnlocked
                  ? badge.glowColor.withValues(alpha: 0.3)
                  : Colors.white10,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Flexible(
                    child: Text(
                      'Milestone Stat',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 9, color: Colors.white54),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    badge.currentProgress ?? (isUnlocked ? '100%' : '0%'),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isUnlocked ? badge.glowColor : Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: badge.progressRatio,
                  minHeight: 4,
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isUnlocked ? badge.glowColor : FitoraColors.mintGreen,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 6),

        // Unlock date
        Text(
          isUnlocked
              ? 'Unlocked: ${badge.formattedUnlockDate}'
              : 'Target: ${badge.statRequirement ?? "Keep going!"}',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: isUnlocked
                ? Colors.white70
                : FitoraColors.warningOrange.withValues(alpha: 0.9),
          ),
        ),

        if (isUnlocked) ...[
          const SizedBox(height: 4),
          InkWell(
            onTap: () {
              final milestone = ShareableMilestoneData.achievement(
                title: badge.title,
                description: badge.description,
                icon: badge.iconData,
                accentColor: badge.glowColor,
              );
              ShareableImageService.showMilestoneShareModal(context, milestone);
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: badge.glowColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.share_rounded, size: 10, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    'Share Trophy',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 2),
      ],
    );
  }
}

/// Custom painter for the 3D metallic plate bevel with directional specular lighting
class _MetallicBevelPainter extends CustomPainter {
  final List<Color> metallicColors;
  final bool isUnlocked;
  final double tiltX;
  final double tiltY;
  final bool isDark;

  _MetallicBevelPainter({
    required this.metallicColors,
    required this.isUnlocked,
    required this.tiltX,
    required this.tiltY,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(22));

    // Base background plate
    final basePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment(tiltX * 0.5 - 0.7, tiltY * 0.5 - 0.7),
        end: Alignment(tiltX * 0.5 + 0.7, tiltY * 0.5 + 0.7),
        colors: isUnlocked
            ? [
                isDark ? const Color(0xFF1E2423) : const Color(0xFFFFFFFF),
                isDark ? const Color(0xFF121716) : const Color(0xFFF1F5F4),
                isDark ? const Color(0xFF0C100F) : const Color(0xFFE2E8E6),
              ]
            : [
                const Color(0xFF181D1C),
                const Color(0xFF101413),
                const Color(0xFF0A0D0C),
              ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(rect);

    canvas.drawRRect(rrect, basePaint);

    // 3D Metallic Rim Bevel
    final bevelPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..shader = LinearGradient(
        begin: Alignment(tiltX - 0.8, tiltY - 0.8),
        end: Alignment(tiltX + 0.8, tiltY + 0.8),
        colors: isUnlocked
            ? [
                Colors.white.withValues(alpha: 0.90),
                metallicColors.first.withValues(alpha: 0.85),
                metallicColors.last.withValues(alpha: 0.75),
                Colors.black.withValues(alpha: 0.40),
              ]
            : [
                Colors.white.withValues(alpha: 0.25),
                Colors.white.withValues(alpha: 0.05),
                Colors.black.withValues(alpha: 0.60),
              ],
        stops: isUnlocked ? const [0.0, 0.35, 0.75, 1.0] : const [0.0, 0.45, 1.0],
      ).createShader(rect);

    canvas.drawRRect(rrect, bevelPaint);
  }

  @override
  bool shouldRepaint(covariant _MetallicBevelPainter oldDelegate) {
    return oldDelegate.isUnlocked != isUnlocked ||
        oldDelegate.tiltX != tiltX ||
        oldDelegate.tiltY != tiltY ||
        oldDelegate.isDark != isDark;
  }
}

/// Custom painter rendering a sweeping specular gleam across the metallic card
class _MetallicShineSweepPainter extends CustomPainter {
  final double shineProgress;
  final Color glowColor;

  _MetallicShineSweepPainter({
    required this.shineProgress,
    required this.glowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (shineProgress < -1.0 || shineProgress > 2.0) return;

    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(22));

    final shinePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment(shineProgress - 0.3, -1.0),
        end: Alignment(shineProgress + 0.3, 1.0),
        colors: [
          Colors.transparent,
          Colors.white.withValues(alpha: 0.05),
          Colors.white.withValues(alpha: 0.45),
          glowColor.withValues(alpha: 0.35),
          Colors.white.withValues(alpha: 0.05),
          Colors.transparent,
        ],
        stops: const [0.0, 0.3, 0.5, 0.55, 0.7, 1.0],
      ).createShader(rect);

    canvas.drawRRect(rrect, shinePaint);
  }

  @override
  bool shouldRepaint(covariant _MetallicShineSweepPainter oldDelegate) {
    return oldDelegate.shineProgress != shineProgress ||
        oldDelegate.glowColor != glowColor;
  }
}
