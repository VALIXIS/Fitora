import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fitora/core/constants/spacing.dart';
import 'package:fitora/core/theme/fitora_colors.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFF0E1312),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: FitoraSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: FitoraSpacing.xxl),
                  _buildLogo(),
                  const SizedBox(height: FitoraSpacing.xl),
                  Text(
                    'FITORA',
                    style: textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 8,
                    ),
                  ),
                  const SizedBox(height: FitoraSpacing.sm),
                  Text(
                    'Version 1.0.0 (Build 42)',
                    style: textTheme.labelMedium?.copyWith(
                      color: Colors.white54,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: FitoraSpacing.xxl),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: FitoraSpacing.xl),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                [
                  _buildSectionTitle(textTheme, 'MISSION'),
                  _buildInfoCard(
                    textTheme,
                    'Fitora is designed to be your premium, AI-powered fitness operating system. We bridge the gap between intelligent tracking and elegant design, empowering you to achieve your highest potential.',
                  ),
                  const SizedBox(height: FitoraSpacing.xl),
                  _buildSectionTitle(textTheme, 'CREDITS'),
                  _buildInfoCard(
                    textTheme,
                    'Designed & Developed with precision.\\nPowered by Flutter & Firebase.',
                  ),
                  const SizedBox(height: FitoraSpacing.xl),
                  _buildSectionTitle(textTheme, 'CONTACT'),
                  _buildLinkCard(textTheme, Icons.email_rounded, 'support@fitora.app'),
                  const SizedBox(height: FitoraSpacing.md),
                  _buildLinkCard(textTheme, Icons.language_rounded, 'www.fitora.app'),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [FitoraColors.mintGreen, FitoraColors.calmCyan],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: FitoraColors.mintGreen.withValues(alpha: 0.2),
            blurRadius: 30,
            spreadRadius: 10,
          ),
        ],
      ),
      child: const Center(
        child: Icon(Icons.fitness_center_rounded, color: Colors.white, size: 48),
      ),
    );
  }

  Widget _buildSectionTitle(TextTheme textTheme, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
          color: Colors.white54,
        ),
      ),
    );
  }

  Widget _buildInfoCard(TextTheme tt, String content) {
    return Container(
      padding: const EdgeInsets.all(FitoraSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Text(
        content,
        style: tt.bodyMedium?.copyWith(
          color: Colors.white70,
          height: 1.6,
        ),
      ),
    );
  }

  Widget _buildLinkCard(TextTheme tt, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: FitoraSpacing.lg, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Icon(icon, color: FitoraColors.mintGreen, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: tt.bodyMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white30, size: 14),
        ],
      ),
    );
  }
}
