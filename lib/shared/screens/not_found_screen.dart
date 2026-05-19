import 'package:flutter/material.dart';
import 'package:fitora/shared/widgets/app_scaffold.dart';
import 'package:fitora/shared/widgets/empty_state_widget.dart';

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      title: 'Page not found',
      body: EmptyStateWidget(
        icon: Icons.search_off,
        title: 'We could not find that page',
        message: 'Try returning to Home from the bottom navigation.',
      ),
    );
  }
}
