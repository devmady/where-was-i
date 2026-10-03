import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';

import '../../features/home/screens/home_screen.dart';
import '../../features/library/screens/library_screen.dart';
import '../../features/library/widgets/add_book_sheet.dart';
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
  StreamSubscription<Uri?>? _widgetTaps;
  int _currentIndex = _homeIndex;

  @override
  void initState() {
    super.initState();
    _listenForWidgetTaps();
  }

  @override
  void dispose() {
    _widgetTaps?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  /// Listens for taps on the home screen widget, both the tap that started
  /// the app and any taps while it is already open. Only Android has the
  /// widget so far.
  Future<void> _listenForWidgetTaps() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    try {
      _widgetTaps = HomeWidget.widgetClicked.listen(_handleWidgetTap);
      final launchedWith = await HomeWidget.initiallyLaunchedFromHomeWidget();
      _handleWidgetTap(launchedWith);
    } catch (error) {
      debugPrint('AppShell: could not listen for widget taps ($error)');
    }
  }

  /// The plus button on the widget opens the shared add-book sheet. Tapping
  /// the rest of the widget brings the reader to Home.
  void _handleWidgetTap(Uri? uri) {
    if (uri == null || !mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      switch (uri.host) {
        case 'add-book':
          _openAddBookSheet();
        case 'open':
          if (_currentIndex != _homeIndex) _onNavTap(_homeIndex);
      }
    });
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

  void _openAddBookSheet() {
    // Opens the shared add-book sheet. The plus button in the Library header,
    // the long press on the Library and Home icons, and the widget plus
    // button all open the very same sheet, so the entry points never drift
    // into different flows.
    showAddBookSheet(context);
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
            children: [
              const LibraryScreen(),
              const HomeScreen(),
              const ProfileScreen(),
            ],
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: MainNavBar(
              currentIndex: _currentIndex,
              onTap: _onNavTap,
              onAddBookLongPress: _openAddBookSheet,
            ),
          ),
        ],
      ),
    );
  }
}
