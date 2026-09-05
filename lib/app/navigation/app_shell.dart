import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fitora/app/navigation/fitora_bottom_nav_bar.dart';
import 'package:fitora/core/services/haptic_service.dart';

class AppShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({
    super.key,
    required this.navigationShell,
  });

  void _onTap(WidgetRef ref, int index) {
    if (index != navigationShell.currentIndex) {
      ref.read(hapticServiceProvider).tabSwitch();
    }
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: FitoraBottomNavBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => _onTap(ref, index),
      ),
    );
  }
}
