import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fitora/app/navigation/nav_items.dart';
import 'package:fitora/shared/widgets/scale_on_press.dart';
import 'package:fitora/core/theme/fitora_colors.dart';

class FitoraBottomNavBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const FitoraBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<FitoraBottomNavBar> createState() => _FitoraBottomNavBarState();
}

class _FitoraBottomNavBarState extends State<FitoraBottomNavBar> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: FitoraColors.mintGreen.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            height: 72,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
              borderRadius: BorderRadius.circular(28),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = constraints.maxWidth / FitoraNavItems.items.length;
                return Stack(
                  children: [
                    // Animated Indicator
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCirc,
                      top: 12,
                      bottom: 12,
                      left: itemWidth * widget.currentIndex + 4,
                      width: itemWidth - 8,
                      child: Container(
                        decoration: BoxDecoration(
                          color: FitoraColors.mintGreen.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                    // Icons
                    Row(
                      children: List.generate(
                        FitoraNavItems.items.length,
                        (index) {
                          final item = FitoraNavItems.items[index];
                          final isSelected = widget.currentIndex == index;

                          return Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => widget.onTap(index),
                              child: ScaleOnPress(
                                scaleDownTo: 0.9,
                                child: AnimatedScale(
                                  scale: isSelected ? 1.0 : 0.8,
                                  duration: const Duration(milliseconds: 400),
                                  curve: Curves.elasticOut,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        isSelected ? item.selectedIcon : item.icon,
                                        color: isSelected
                                            ? FitoraColors.mintGreen
                                            : Colors.white54,
                                        size: 26,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item.label,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: isSelected
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                          color: isSelected
                                              ? FitoraColors.mintGreen
                                              : Colors.white54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
