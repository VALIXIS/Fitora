import 'package:flutter/material.dart';
import 'package:fitora/core/constants/spacing.dart';
import 'package:fitora/core/theme/fitora_colors.dart';
import 'package:fitora/features/progress/domain/shareable_milestone_models.dart';

/// Branded 9:16 aspect ratio milestone card widget optimized for Instagram Stories
/// and WhatsApp Status sharing.
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
          color: const Color(0xFF0A0E0D),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: data.accentColor.withValues(alpha: 0.15),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Background Gradient Glow Elements
              Positioned(
                top: -60,
                right: -60,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: FitoraColors.mintGreen.withValues(alpha: 0.12),
                  ),
                ),
              ),
              Positioned(
                bottom: -80,
                left: -60,
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: data.accentColor.withValues(alpha: 0.15),
                  ),
                ),
              ),

              // Main Card Content
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: FitoraSpacing.xl,
                  vertical: FitoraSpacing.xxl,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Header: Brand Title & Logo
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: FitoraColors.mintGreen.withValues(alpha: 0.15),
                            border: Border.all(
                              color: FitoraColors.mintGreen.withValues(alpha: 0.4),
                            ),
                          ),
                          child: const Icon(
                            Icons.bolt_rounded,
                            color: FitoraColors.mintGreen,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: FitoraSpacing.sm),
                        Text(
                          'FITORA',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 4.0,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: FitoraColors.mintGreen.withValues(alpha: 0.5),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Center Hero Section: Badge Icon & Highlight Ring
                    Column(
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            // Outer Glow Ring
                            Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: data.accentColor.withValues(alpha: 0.08),
                                border: Border.all(
                                  color: data.accentColor.withValues(alpha: 0.25),
                                  width: 2,
                                ),
                              ),
                            ),
                            // Inner Badge Container
                            Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    data.accentColor.withValues(alpha: 0.3),
                                    data.accentColor.withValues(alpha: 0.05),
                                  ],
                                ),
                                border: Border.all(
                                  color: data.accentColor,
                                  width: 2.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: data.accentColor.withValues(alpha: 0.4),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Icon(
                                data.icon,
                                color: data.accentColor,
                                size: 54,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: FitoraSpacing.xl),

                        // Milestone Title & Subtitle
                        Text(
                          data.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: FitoraSpacing.xs),
                        Text(
                          data.subtitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: FitoraSpacing.xl),

                        // Metric Box
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: FitoraSpacing.xl,
                            vertical: FitoraSpacing.md,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                data.metricValue,
                                style: TextStyle(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w900,
                                  color: data.accentColor,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                data.metricUnit,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                  color: Colors.white.withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Footer: Watermark & Date Stamp
                    Column(
                      children: [
                        if (data.userName != null && data.userName!.isNotEmpty) ...[
                          Text(
                            'ATHLETE: ${data.userName!.toUpperCase()}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                              color: FitoraColors.mintGreen.withValues(alpha: 0.9),
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],
                        Text(
                          'POWERED BY FITORA AI  •  ${_formatDate(data.date ?? DateTime.now())}',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                            color: Colors.white.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
