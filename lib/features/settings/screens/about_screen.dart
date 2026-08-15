import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fitora/core/constants/spacing.dart';
import 'package:fitora/core/theme/fitora_colors.dart';
import 'package:fitora/shared/widgets/glow_container.dart';
import 'package:fitora/shared/widgets/fitora_background.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return FitoraBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.colorScheme.onSurface, size: 20),
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
                    _buildLogo(context),
                    const SizedBox(height: FitoraSpacing.xl),
                    Text(
                      'FITORA',
                      style: textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.onSurface,
                        letterSpacing: 8,
                      ),
                    ),
                    const SizedBox(height: FitoraSpacing.xs),
                    Text(
                      'Track Better. Live Healthier.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: FitoraColors.mintGreen,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: FitoraSpacing.sm),
                    Text(
                      'Version 1.0.0',
                      style: textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: FitoraSpacing.xl),
                    _buildSectionTitle(context, 'OUR MISSION'),
                    _buildInfoCard(
                      context,
                      textTheme,
                      'Fitora is built to give you full control over your fitness journey. We believe health tracking should be intuitive, beautiful, and private. By leveraging on-device sensors and health connections, Fitora provides premium-quality analytics without compromises.',
                    ),
                    const SizedBox(height: FitoraSpacing.xl),
                    _buildSectionTitle(context, 'PRIVACY & SECURITY'),
                    _buildInfoCard(
                      context,
                      textTheme,
                      'Your privacy is our priority. All biometric and health data is processed and stored securely on your device.',
                    ),
                    const SizedBox(height: FitoraSpacing.xl),
                    _buildSectionTitle(context, 'SUPPORT & CONTACT'),
                    _buildLinkCard(context, textTheme, Icons.email_rounded, 'support@fitora.app'),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 100,
      height: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Image.asset('assets/icon_foreground.png', fit: BoxFit.contain),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, TextTheme tt, String content) {
    final theme = Theme.of(context);
    return GlowContainer(
      glowColor: FitoraColors.calmCyan.withValues(alpha: 0.03),
      borderRadius: BorderRadius.circular(20),
      padding: EdgeInsets.zero,
      child: Container(
        padding: const EdgeInsets.all(FitoraSpacing.lg),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: Text(
          content,
          style: tt.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.6,
          ),
        ),
      ),
    );
  }

  Widget _buildLinkCard(BuildContext context, TextTheme tt, IconData icon, String text) {
    final theme = Theme.of(context);
    return GlowContainer(
      glowColor: FitoraColors.mintGreen.withValues(alpha: 0.03),
      borderRadius: BorderRadius.circular(20),
      padding: EdgeInsets.zero,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: FitoraSpacing.lg, vertical: 16),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Icon(icon, color: FitoraColors.mintGreen, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                text,
                style: tt.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: theme.colorScheme.onSurface.withValues(alpha: 0.3), size: 14),
          ],
        ),
      ),
    );
  }
}
