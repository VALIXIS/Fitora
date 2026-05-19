import 'package:flutter/material.dart';
import 'package:fitora/shared/widgets/app_scaffold.dart';
import 'package:fitora/shared/widgets/empty_state_widget.dart';
import 'package:fitora/shared/widgets/fitora_button.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Progress',
      body: EmptyStateWidget(
        icon: Icons.show_chart_outlined,
        title: 'No trends yet',
        message: 'Complete a few sessions to unlock your progress insights.',
        action: FitoraButton(
          label: 'Log a session',
          onPressed: () {},
        ),
      ),
    );
  }
}
