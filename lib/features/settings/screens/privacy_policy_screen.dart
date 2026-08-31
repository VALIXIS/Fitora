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
                  'Last Updated: August 31, 2026\n\n'
                  'VALIXIS ("VALIXIS", "we", "us", or "our") operates the Fitora mobile application ("Fitora" or the "App").\n'
                  'This Privacy Policy explains what information Fitora may access or collect, how that information is used, how long it is stored, and how users can request deletion.\n'
                  'By using Fitora, you acknowledge the practices described in this Privacy Policy.\n\n'
                  '1. Information We May Process\n'
                  'Depending on the features you use and the permissions you grant, Fitora may process the following categories of information:\n'
                  '• Account information: Name, email address, and authentication credentials (e.g. via Google Sign-In or Anonymous Guest mode).\n'
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
                  '4. Data Storage and Security\n'
                  'Fitora information is stored securely on your device and via Google Firebase services using encrypted industry-standard protocols.\n\n'
                  '5. Data Retention Policy\n'
                  'We retain personal data and fitness records for as long as your user account remains active or as needed to provide you with Fitora services.\n'
                  'Account profile data and fitness logs are retained in secure cloud storage while your account is active. Inactive account data (inactive for 24 months) or accounts marked for deletion are permanently purged.\n\n'
                  '6. Data Deletion & Account Deletion Request Process\n'
                  'You have full control over your personal data. You can request complete account and data deletion at any time.\n'
                  '• How to request deletion: Email us at nagasubhash55@gmail.com or official.valixis@gmail.com with subject "Fitora Account & Data Deletion Request".\n'
                  '• Processing Time: All personal credentials, workout logs, sleep metrics, and profile data will be permanently deleted from our servers within 30 days.\n'
                  '• Local Storage: Uninstalling Fitora removes all locally cached data from your device.\n\n'
                  '7. Sharing of Information\n'
                  'We do NOT sell your personal information. We do NOT sell or share your health data for advertising purposes.\n\n'
                  '8. Notifications\n'
                  'If you grant notification permission, Fitora may send hydration reminders and goal check-ins. You can disable notifications anytime in Settings.\n\n'
                  '9. Contact Us\n'
                  'VALIXIS\n'
                  'For privacy inquiries or data deletion requests, contact us at:\n'
                  'nagasubhash55@gmail.com / official.valixis@gmail.com',
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
