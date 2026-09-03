import 'package:flutter/material.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/library/screens/library_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import 'main_nav_bar.dart';

/// App shell wiring the Library (0) — Home (1) — Profile (2) strip.
/// Uses a Stack so the floating pill nav bar overlaps page content
/// at the bottom, rather than pushing it up like a standard
/// BottomAppBar would.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const _homeIndex = 1;

  final PageController _pageController = PageController(initialPage: _homeIndex);
  int _currentIndex = _homeIndex;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
  }

  void _onHomeLongPress() {
    // trigger the add-book popup/banner once it exists.
    // Secondary shortcut — LibraryScreen's own + button is the
    // primary entry point per the locked nav plan.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            children: const [
              LibraryScreen(),
              HomeScreen(),
              ProfileScreen(),
            ],
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: MainNavBar(
              currentIndex: _currentIndex,
              onTap: _onNavTap,
              onHomeLongPress: _onHomeLongPress,
            ),
          ),
        ],
      ),
    );
  }
}
