import 'package:flutter/material.dart';

/// Floating rounded-pill nav bar: Library / Home / Profile, icon-only.
/// The active icon is shown as a filled teal circle; inactive icons
/// are plain outline icons in muted secondary text color.
///
/// The highlight follows the live position of the page controller, so the
/// filled circle moves with the finger while swiping and with the slide
/// animation after a tap, instead of jumping once a page index changes.
///
/// Pressing and holding the Home icon opens the add-book sheet. The Library
/// icon only navigates; adding a book there is done with the plus button
/// in the Library header.
class MainNavBar extends StatelessWidget {
  const MainNavBar({
    super.key,
    required this.pageController,
    required this.onTap,
    required this.onAddBookLongPress,
  });

  final PageController pageController;
  final ValueChanged<int> onTap;
  final VoidCallback onAddBookLongPress;

  static const _icons = [
    Icons.menu_book_outlined, // Library
    Icons.home_outlined,      // Home
    Icons.person_outline,     // Profile
  ];

  /// Only Home opens the add-book sheet on a long press.
  static const _addBookIndexes = {1};

  /// The current page as a fraction, for example 0.4 while the strip is
  /// partway between Library and Home. Before the page view has measured
  /// itself, the starting page is used.
  double _currentPage() {
    if (!pageController.hasClients) {
      return pageController.initialPage.toDouble();
    }
    return pageController.page ?? pageController.initialPage.toDouble();
  }

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
          child: AnimatedBuilder(
            animation: pageController,
            builder: (context, _) {
              final page = _currentPage();
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(_icons.length, (index) {
                  final closeness =
                      (1 - (page - index).abs()).clamp(0.0, 1.0).toDouble();
                  return Padding(
                    padding: EdgeInsets.only(left: index == 0 ? 0 : 28),
                    child: _NavCircle(
                      icon: _icons[index],
                      closeness: closeness,
                      onTap: () => onTap(index),
                      onLongPress: _addBookIndexes.contains(index)
                          ? onAddBookLongPress
                          : null,
                    ),
                  );
                }),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _NavCircle extends StatelessWidget {
  const _NavCircle({
    required this.icon,
    required this.closeness,
    required this.onTap,
    this.onLongPress,
  });

  final IconData icon;

  /// 1 when this icon is fully the current page, 0 when the page is a whole
  /// step or more away. Values in between happen while the strip is moving.
  final double closeness;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final iconColor = Color.lerp(
      colorScheme.onSurface.withValues(alpha: 0.6),
      colorScheme.onPrimary,
      closeness,
    )!;

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      customBorder: const CircleBorder(),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colorScheme.primary.withValues(alpha: closeness),
        ),
        child: Icon(
          icon,
          size: 22 - 2 * closeness,
          color: iconColor,
        ),
      ),
    );
  }
}
