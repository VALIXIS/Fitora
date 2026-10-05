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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final containerBg = isDark
        ? const Color(0xFF141918).withValues(alpha: 0.88)
        : Colors.white.withValues(alpha: 0.95);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : const Color(0xFFE2E8F0);
    final shadowColor = isDark
        ? FitoraColors.mintGreen.withValues(alpha: 0.15)
        : Colors.black.withValues(alpha: 0.08);

    final activeColor = isDark ? FitoraColors.mintGreen : const Color(0xFF047857);
    final inactiveColor = isDark ? Colors.white54 : const Color(0xFF64748B);
    final indicatorColor = isDark
        ? FitoraColors.mintGreen.withValues(alpha: 0.20)
        : const Color(0xFFDCFCE7);

    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
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
              color: containerBg,
              border: Border.all(color: borderColor),
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
                          color: indicatorColor,
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
                                            ? activeColor
                                            : inactiveColor,
                                        size: 26,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item.label,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: isSelected
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color: isSelected
                                              ? activeColor
                                              : inactiveColor,
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
