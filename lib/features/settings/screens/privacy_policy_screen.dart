import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fitora/core/constants/spacing.dart';
import 'package:fitora/shared/widgets/fitora_background.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
          title: Text(
            'Privacy Policy',
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
                'Fitora Privacy Policy',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: FitoraSpacing.md),
              Text(
                'Last Updated: August 2026\n\n'
                'VALIXIS ("VALIXIS", "we", "us", or "our") operates the Fitora mobile application ("Fitora" or the "App").\n'
                'This Privacy Policy explains what information Fitora may access or collect, how that information is used, how it is stored, and the choices available to you.\n'
                'By using Fitora, you acknowledge the practices described in this Privacy Policy.\n\n'
                '1. Information We May Process\n'
                'Depending on the features you use and the permissions you grant, Fitora may process the following categories of information:\n'
                '• Account information: Name, email address, and authentication credentials (e.g. via Google Sign-In).\n'
                '• Fitness and wellness information: Steps, distance, calories, active minutes, sleep logs, hydration logs, fitness goals, and user-entered metrics.\n'
                '• Device and technical information: Basic operating system information required for stability and security.\n'
                '• Notification information: Notification and reminder preferences.\n\n'
                '2. Health and Fitness Data\n'
                'Fitora is designed for personal fitness and wellness tracking.\n'
                'When a supported health platform or device integration is enabled and you grant permission, Fitora may access relevant fitness information available through that integration.\n'
                'Fitora only requests access to information needed for the corresponding functionality.\n'
                'Health and fitness information is used to provide features such as activity tracking, progress monitoring, goals, and wellness insights.\n'
                'Fitora does NOT use health or fitness information for advertising, credit decisions, insurance eligibility, employment decisions, or other unrelated purposes.\n'
                'You control whether Fitora receives information through device and health-platform permissions.\n\n'
                '3. How We Use Information\n'
                'We use information to provide and operate Fitora\'s features, display activity progress, calculate goals, store preferences, deliver reminders, authenticate accounts, and maintain App security.\n\n'
                '4. Data Storage\n'
                'Some Fitora information is stored locally on your device. Where third-party services (such as Firebase Authentication) are used, information is processed according to their applicable privacy security practices.\n\n'
                '5. Sharing of Information\n'
                'We do NOT sell your personal information. We do NOT sell or share your health data for advertising purposes.\n\n'
                '6. Notifications\n'
                'If you grant notification permission, Fitora may send hydration reminders and goal check-ins. You can disable notifications anytime in Settings.\n\n'
                '7. Your Choices and Permissions\n'
                'You may grant or revoke permissions, disable notifications, or request account data deletion at any time.\n\n'
                '8. Data Retention and Deletion\n'
                'We retain information only as long as necessary to provide service functionality or satisfy legal obligations. Local data can be cleared by uninstalling the App.\n\n'
                '9. Children\'s Privacy\n'
                'Fitora is not intended to knowingly collect personal information from children in violation of applicable laws.\n\n'
                '10. Third-Party Services\n'
                'Fitora relies on standard authentication and platform services that process data under their respective privacy policies.\n\n'
                '11. Contact Us\n'
                'VALIXIS\n'
                'For privacy inquiries or data requests, contact us at: official.valixis@gmail.com',
                style: textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
}
