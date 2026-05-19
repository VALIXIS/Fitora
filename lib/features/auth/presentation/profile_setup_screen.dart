import 'package:flutter/material.dart';
import 'package:fitora/shared/widgets/app_scaffold.dart';
import 'package:fitora/shared/widgets/empty_state_widget.dart';

class ProfileSetupScreen extends StatelessWidget {
  const ProfileSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      title: 'Set up your profile',
      body: EmptyStateWidget(
        icon: Icons.tune,
        title: 'Personalization is next',
        message: 'We will guide you through a quick setup after sign-in.',
      ),
    );
  }
}
