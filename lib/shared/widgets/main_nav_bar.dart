import 'package:flutter/material.dart';

/// Floating rounded-pill nav bar: Library / Home / Profile, icon-only.
/// The active icon is shown as a filled teal circle; inactive icons
/// are plain outline icons in muted secondary text color.
class MainNavBar extends StatelessWidget {
  const MainNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onHomeLongPress,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onHomeLongPress;

  static const _icons = [
    Icons.menu_book_outlined, // Library
    Icons.home_outlined,      // Home
    Icons.person_outline,     // Profile
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16, left: 24, right: 24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: colorScheme.onSurface.withValues(alpha: 0.08),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(_icons.length, (index) {
              final selected = currentIndex == index;
              return Padding(
                padding: EdgeInsets.only(left: index == 0 ? 0 : 28),
                child: _NavCircle(
                  icon: _icons[index],
                  selected: selected,
                  onTap: () => onTap(index),
                  onLongPress: index == 1 ? onHomeLongPress : null,
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavCircle extends StatelessWidget {
  const _NavCircle({
    required this.icon,
    required this.selected,
    required this.onTap,
    this.onLongPress,
  });

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      customBorder: const CircleBorder(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected ? colorScheme.primary : Colors.transparent,
        ),
        child: Icon(
          icon,
          size: selected ? 20 : 22,
          color: selected
              ? colorScheme.onPrimary
              : colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}
