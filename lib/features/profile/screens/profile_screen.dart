import 'package:flutter/material.dart';
import 'package:fitora/shared/widgets/app_scaffold.dart';
import 'package:fitora/shared/widgets/empty_state_widget.dart';
import 'package:fitora/shared/widgets/fitora_button.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Profile',
      body: EmptyStateWidget(
        icon: Icons.person_outline,
        title: 'Your profile is waiting',
        message: 'Set goals and personalize your wellness journey.',
        action: FitoraButton(
          label: 'Set up profile',
          onPressed: () {},
        ),
      ),
    );
  }
}
