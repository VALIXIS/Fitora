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
                'Last updated: June 5, 2026\n\n'
                '1. Acceptance of Terms\n'
                'By using the Fitora app, you agree to these terms. If you do not agree to these terms, please do not use the app.\n\n'
                '2. Medical Disclaimer\n'
                'Fitora provides fitness and wellness tracking, not medical advice. Always consult a qualified healthcare professional before starting any new diet or exercise regimen.\n\n'
                '3. User Responsibilities\n'
                'You are responsible for your own safety during workouts. Stop immediately if you feel pain, dizziness, or severe discomfort.\n\n'
                '4. Intellectual Property\n'
                'All app design, text, graphics, and underlying code are the property of Fitora. You may not reproduce or distribute them without permission.\n\n'
                '5. Limitation of Liability\n'
                'Fitora is not liable for any injuries, damages, or losses resulting from your use of the app or its recommended workout routines.\n\n'
                'If you have any questions, contact us at legal@fitora.app.',
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
