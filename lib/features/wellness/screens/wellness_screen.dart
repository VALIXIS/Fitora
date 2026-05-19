import 'package:flutter/material.dart';
import 'package:fitora/shared/widgets/app_scaffold.dart';
import 'package:fitora/shared/widgets/empty_state_widget.dart';
import 'package:fitora/shared/widgets/fitora_button.dart';

class WellnessScreen extends StatelessWidget {
  const WellnessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Wellness',
      body: EmptyStateWidget(
        icon: Icons.spa_outlined,
        title: 'Wellness space is ready',
        message: 'Save breathing, sleep, and recovery sessions here.',
        action: FitoraButton(
          label: 'Start a breathing session',
          onPressed: () {},
        ),
      ),
    );
  }
}
