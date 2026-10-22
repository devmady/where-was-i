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
///
/// The nav bar reads the page controller directly, so swiping never has to
/// rebuild this shell.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const _libraryIndex = 0;
  static const _homeIndex = 1;

  final PageController _pageController = PageController(initialPage: _homeIndex);
  StreamSubscription<Uri?>? _widgetTaps;

  /// True while the Library search bar is open. The Library sets it when the
  /// search opens or closes. Setting it to false from here asks the Library
  /// to close its search, which is what the back button does first.
  final ValueNotifier<bool> _librarySearchOpen = ValueNotifier<bool>(false);

  /// The page the strip is on or closest to right now.
  int get _currentIndex {
    if (!_pageController.hasClients) return _homeIndex;
    return _pageController.page?.round() ?? _homeIndex;
  }

  @override
  void initState() {
    super.initState();
    _listenForWidgetTaps();
  }

  @override
  void dispose() {
    _widgetTaps?.cancel();
    _pageController.dispose();
    _librarySearchOpen.dispose();
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
    if (!_pageController.hasClients) return;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  /// The back button while nothing is open on top of the three screens. On
  /// Home the system closes the app, so this is only reached on Library or
  /// Profile. An open Library search closes first, then back goes to Home.
  /// Sheets, dialogs and pushed screens close on their own before this runs.
  void _handleBack() {
    if (_currentIndex == _libraryIndex && _librarySearchOpen.value) {
      _librarySearchOpen.value = false;
      return;
    }
    if (_currentIndex != _homeIndex) _onNavTap(_homeIndex);
  }

  void _openAddBookSheet() {
    // Opens the shared add-book sheet. The plus button in the Library header,
    // the long press on the Home icon, and the widget plus button all open
    // the very same sheet, so the entry points never drift into different
    // flows.
    showAddBookSheet(context);
  }

  @override
  Widget build(BuildContext context) {
    // Only the back handling rebuilds while the strip moves. The screens and
    // the nav bar are built once and passed through as the child.
    return AnimatedBuilder(
      animation: _pageController,
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            PageView(
              controller: _pageController,
              children: [
                LibraryScreen(searchOpen: _librarySearchOpen),
                const HomeScreen(),
                const ProfileScreen(),
              ],
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: MainNavBar(
                pageController: _pageController,
                onTap: _onNavTap,
                onAddBookLongPress: _openAddBookSheet,
              ),
            ),
          ],
        ),
      ),
      builder: (context, scaffold) {
        return PopScope(
          canPop: _currentIndex == _homeIndex,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            _handleBack();
          },
          child: scaffold!,
        );
      },
    );
  }
}
