import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fitora/core/constants/spacing.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.colorScheme.onSurface, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Terms of Service',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(FitoraSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Fitora Terms of Service',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: FitoraSpacing.md),
              Text(
                'Last Updated: August 2026\n\n'
                'These Terms of Service ("Terms") govern your use of the Fitora mobile application operated by VALIXIS. By using Fitora, you agree to these Terms.\n\n'
                '1. About Fitora\n'
                'Fitora is a fitness and wellness application designed to help users track activity, manage goals, monitor wellness information, and build healthier routines. Fitora is provided for general fitness and wellness purposes only.\n\n'
                '2. Not Medical Advice\n'
                'Fitora is not a medical device and does not provide medical diagnosis, treatment, prevention, or professional medical advice. Information displayed by Fitora should not be used as a substitute for advice from a qualified healthcare professional.\n\n'
                '3. Your Account\n'
                'If Fitora requires an account, you are responsible for maintaining credentials security and for activity under your account.\n\n'
                '4. Acceptable Use\n'
                'You agree not to use Fitora for unlawful purposes, compromise app security, reverse engineer software, or access unauthorized accounts.\n\n'
                '5. Fitness Data\n'
                'Fitness information displayed by Fitora depends on input from your device sensors, operating system, or user entries. Measurements may not always be completely accurate. Do not rely on Fitora for clinical or emergency decisions.\n\n'
                '6. Notifications and Reminders\n'
                'Notification delivery may be affected by device permissions, battery optimization, or OS settings outside our control.\n\n'
                '7. Intellectual Property\n'
                'Fitora, including branding, visual design, text, and code, is owned by or licensed to VALIXIS and protected by applicable intellectual property laws.\n\n'
                '8. Disclaimer & Limitation of Liability\n'
                'Fitora is provided on an "as is" basis without warranties of uninterrupted service. To the maximum extent permitted by law, VALIXIS will not be liable for indirect or consequential damages.\n\n'
                '9. Contact\n'
                'VALIXIS\n'
                'For questions regarding these Terms, contact us at: official.valixis@gmail.com',
                style: textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
