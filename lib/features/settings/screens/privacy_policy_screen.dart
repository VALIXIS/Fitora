import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fitora/core/constants/spacing.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
        title: Text('Privacy Policy', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: Colors.white)),
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
                style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: FitoraSpacing.md),
              Text(
                'Last updated: June 5, 2026\n\n'
                'Your privacy is critically important to us. At Fitora, we have a few fundamental principles:\n\n'
                '1. Data Locality\n'
                'Your wellness data (workouts, weight, goals) is stored locally on your device by default. We only sync data if you explicitly connect a third-party service like Google Fit or Apple Health.\n\n'
                '2. Information We Collect\n'
                'We collect the basic physical profile you provide (age, weight, height, gender) solely to compute accurate metrics like BMI and caloric burn. We do not sell this data.\n\n'
                '3. Third-Party Integrations\n'
                'If you connect Strava or Health Connect, we only request the permissions strictly necessary to display your activities in Fitora.\n\n'
                '4. Analytics\n'
                'We collect anonymous crash reports to improve stability. No personal identifiers are attached to these reports.\n\n'
                'If you have any questions about this Privacy Policy, please contact us at support@fitora.app.',
                style: textTheme.bodyMedium?.copyWith(color: Colors.white70, height: 1.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
