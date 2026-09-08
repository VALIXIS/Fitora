import 'package:flutter/material.dart';
import 'package:fitora/app/navigation/nav_items.dart';
import 'package:fitora/shared/widgets/scale_on_press.dart';

class FitoraBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const FitoraBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      destinations: [
        for (final item in FitoraNavItems.items)
          NavigationDestination(
            icon: ScaleOnPress(
              scaleDownTo: 0.92,
              child: Icon(item.icon),
            ),
            selectedIcon: ScaleOnPress(
              scaleDownTo: 0.92,
              child: Icon(item.selectedIcon),
            ),
            label: item.label,
          ),
      ],
    );
  }
}
