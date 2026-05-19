import 'package:flutter/material.dart';
import 'package:fitora/shared/widgets/app_scaffold.dart';
import 'package:fitora/shared/widgets/empty_state_widget.dart';

class AuthEmailScreen extends StatelessWidget {
  const AuthEmailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      title: 'Continue with Email',
      body: EmptyStateWidget(
        icon: Icons.mail_outline,
        title: 'Email sign-in is coming soon',
        message: 'We are preparing a secure email sign-in experience.',
      ),
    );
  }
}
