import 'package:flutter/material.dart';
import 'package:fitora/app/router/app_routes.dart';

class FitoraNavItem {
  final String label;
  final String route;
  final IconData icon;
  final IconData selectedIcon;

  const FitoraNavItem({
    required this.label,
    required this.route,
    required this.icon,
    required this.selectedIcon,
  });
}

class FitoraNavItems {
  static const List<FitoraNavItem> items = [
    FitoraNavItem(
      label: 'Home',
      route: AppRoutes.home,
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
    ),
    FitoraNavItem(
      label: 'Workouts',
      route: AppRoutes.workouts,
      icon: Icons.fitness_center_outlined,
      selectedIcon: Icons.fitness_center,
    ),
    FitoraNavItem(
      label: 'Progress',
      route: AppRoutes.progress,
      icon: Icons.show_chart_outlined,
      selectedIcon: Icons.show_chart,
    ),
    FitoraNavItem(
      label: 'Wellness',
      route: AppRoutes.wellness,
      icon: Icons.spa_outlined,
      selectedIcon: Icons.spa,
    ),
    FitoraNavItem(
      label: 'Profile',
      route: AppRoutes.profile,
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
    ),
  ];
}
