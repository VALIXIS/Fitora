import 'package:flutter/material.dart';
import 'package:fitora/core/constants/spacing.dart';
import 'package:fitora/core/theme/fitora_colors.dart';
import 'package:fitora/features/progress/domain/shareable_milestone_models.dart';

/// Branded 9:16 aspect ratio milestone card widget optimized for Instagram Stories
/// and WhatsApp Status sharing with high-end luxury athletic aesthetics.
class ShareableMilestoneCardWidget extends StatelessWidget {
  final ShareableMilestoneData data;
  final double width;

  const ShareableMilestoneCardWidget({
    super.key,
    required this.data,
    this.width = 360.0,
  });

  @override
  Widget build(BuildContext context) {
    // 9:16 aspect ratio height calculation
    final height = width * (16.0 / 9.0);

    return SizedBox(
      width: width,
      height: height,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF070B0A),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.15),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: data.accentColor.withValues(alpha: 0.25),
              blurRadius: 40,
              spreadRadius: 8,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.8),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            children: [
              // Ambient Glowing Mesh Background
              Positioned(
                top: -80,
                right: -60,
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        FitoraColors.mintGreen.withValues(alpha: 0.25),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -100,
                left: -60,
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        data.accentColor.withValues(alpha: 0.30),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: height * 0.35,
                left: -40,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF38BDF8).withValues(alpha: 0.12),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Subtle Grid / Accent Lines
              Positioned.fill(
                child: CustomPaint(
                  painter: _MilestoneGridPainter(
                    accentColor: data.accentColor.withValues(alpha: 0.05),
                  ),
                ),
              ),

              // Main Card Content
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: SizedBox(
                      width: 360.0,
                      height: 640.0,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // ── Header: Brand Title & Athletic Club Badge ───────────────
                          Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(7),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: const LinearGradient(
                                        colors: [
                                          FitoraColors.mintGreen,
                                          Color(0xFF059669),
                                        ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: FitoraColors.mintGreen.withValues(alpha: 0.5),
                                          blurRadius: 12,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.bolt_rounded,
                                      color: Colors.black,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: FitoraSpacing.sm),
                                  Text(
                                    'FITORA',
                                    style: TextStyle(
                                      fontFamily: 'Roboto',
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 4.5,
                                      color: Colors.white,
                                      shadows: [
                                        Shadow(
                                          color: FitoraColors.mintGreen.withValues(alpha: 0.6),
                                          blurRadius: 14,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.12),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.verified_rounded,
                                      size: 12,
                                      color: FitoraColors.mintGreen,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'OFFICIAL ATHLETE MILESTONE',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.2,
                                        color: Colors.white.withValues(alpha: 0.85),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          // ── Center Hero Section: Holographic 3D Badge ───────────────
                          Column(
                            children: [
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Ambient outer pulsing bloom
                                  Container(
                                    width: 120,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: data.accentColor.withValues(alpha: 0.35),
                                          blurRadius: 32,
                                          spreadRadius: 4,
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Outer metallic glow ring
                                  Container(
                                    width: 110,
                                    height: 110,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: SweepGradient(
                                        colors: [
                                          data.accentColor,
                                          FitoraColors.mintGreen,
                                          data.accentColor.withValues(alpha: 0.3),
                                          data.accentColor,
                                        ],
                                      ),
                                    ),
                                  ),
                                  // Inner mask
                                  Container(
                                    width: 102,
                                    height: 102,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFF0D1311),
                                    ),
                                  ),
                                  // Badge Core with Radial Shine
                                  Container(
                                    width: 90,
                                    height: 90,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        colors: [
                                          data.accentColor.withValues(alpha: 0.40),
                                          data.accentColor.withValues(alpha: 0.10),
                                          const Color(0xFF090E0C),
                                        ],
                                        stops: const [0.0, 0.65, 1.0],
                                      ),
                                      border: Border.all(
                                        color: data.accentColor,
                                        width: 2.2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: data.accentColor.withValues(alpha: 0.5),
                                          blurRadius: 20,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      data.icon,
                                      color: data.accentColor,
                                      size: 46,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),

                              // Milestone Title & Subtitle
                              Text(
                                data.title,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black,
                                      blurRadius: 10,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: Text(
                                  data.subtitle,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: Colors.white.withValues(alpha: 0.75),
                                    fontWeight: FontWeight.w500,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),

                              // Metric Callout Card
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: FitoraSpacing.xl,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: data.accentColor.withValues(alpha: 0.25),
                                    width: 1.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: data.accentColor.withValues(alpha: 0.10),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      data.metricValue,
                                      style: TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.w900,
                                        color: data.accentColor,
                                        letterSpacing: 1.2,
                                        shadows: [
                                          Shadow(
                                            color: data.accentColor.withValues(alpha: 0.6),
                                            blurRadius: 14,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      data.metricUnit,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.6,
                                        color: Colors.white.withValues(alpha: 0.65),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),

                              // Performance Tags
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildPill('TARGET CRUSHED', Icons.check_circle_rounded, FitoraColors.mintGreen),
                                  const SizedBox(width: 8),
                                  _buildPill('TOP 5% TIER', Icons.workspace_premium_rounded, Colors.amberAccent),
                                ],
                              ),
                            ],
                          ),

                        // ── Footer: Watermark & Athlete Stamp ───────────────────────
                        Column(
                          children: [
                            if (data.userName != null && data.userName!.isNotEmpty) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: FitoraColors.mintGreen.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: FitoraColors.mintGreen.withValues(alpha: 0.25),
                                  ),
                                ),
                                child: Text(
                                  'ATHLETE: ${data.userName!.toUpperCase()}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.5,
                                    color: FitoraColors.mintGreen,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                            ],
                            Text(
                              'POWERED BY FITORA AI  •  ${_formatDate(data.date ?? DateTime.now())}',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.5,
                                color: Colors.white.withValues(alpha: 0.45),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildPill(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _MilestoneGridPainter extends CustomPainter {
  final Color accentColor;

  const _MilestoneGridPainter({required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = accentColor
      ..strokeWidth = 0.5;

    const spacing = 36.0;
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MilestoneGridPainter oldDelegate) => false;
}
