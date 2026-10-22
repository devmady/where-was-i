import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';

import '../../../core/database/app_database.dart' show Book;
import '../../../core/database/tables.dart' show BookStatus;
import '../../../core/theme/app_fonts.dart';
import '../../../main.dart' show widgetThemeNotifier;
import '../../../shared/widgets/content_column.dart';
import '../../../shared/widgets/field_decoration.dart';
import '../state/book_repository.dart';
import '../widgets/add_book_sheet.dart';
import '../widgets/book_grid_card.dart';
import '../widgets/empty_shelf_card.dart';
import 'book_detail_screen.dart';

enum _LibraryFilter { all, reading, wantToRead, finished }

/// Library screen, left of the Home center. Every book as a cover grid, with
/// filters by status, a simple search, and the search, add widget and add
/// book buttons in the header.
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key, required this.searchOpen});

  /// Tells the app shell whether the search bar is open, so the back button
  /// can close the search first. The shell sets it to false to ask the
  /// Library to close its search.
  final ValueNotifier<bool> searchOpen;

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  static const double _navClearance = 112;

  // How long to wait after the search opens before the keyboard comes up, so
  // the keyboard never competes with the header change.
  static const Duration _keyboardDelay = Duration(milliseconds: 300);

  // How long the add widget button must be held to switch the widget theme.
  static const Duration _widgetThemeHold = Duration(seconds: 3);

  static const Map<_LibraryFilter, String> _labels = {
    _LibraryFilter.all: 'All',
    _LibraryFilter.reading: 'Reading',
    _LibraryFilter.wantToRead: 'Want to read',
    _LibraryFilter.finished: 'Finished',
  };

  final Stream<List<Book>> _books = BookRepository.instance.watchAll();
  final TextEditingController _query = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  _LibraryFilter _filter = _LibraryFilter.all;
  bool _searching = false;
  int _bookCount = 0;
  bool _canPinWidget = false;
  Timer? _widgetHoldTimer;
  Offset? _widgetHoldStart;

  @override
  void initState() {
    super.initState();
    // A new Library always starts with the search closed. This runs before
    // the listener is added, so nothing is notified.
    widget.searchOpen.value = false;
    widget.searchOpen.addListener(_onSearchFlagChanged);
    _checkWidgetPinSupport();
  }

  /// The shell sets the flag to false when the back button should close the
  /// search. When the search closes by its own button the state is already
  /// closed, so nothing happens here.
  void _onSearchFlagChanged() {
    if (widget.searchOpen.value || !_searching) return;
    setState(() {
      _query.clear();
      _searching = false;
    });
  }

  /// Only Android has the widget so far, and pinning needs Android 8 or newer
  /// plus a launcher that allows it. The button stays hidden otherwise.
  Future<void> _checkWidgetPinSupport() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    try {
      final supported = await HomeWidget.isRequestPinWidgetSupported();
      if (!mounted || supported != true) return;
      setState(() => _canPinWidget = true);
    } catch (error) {
      debugPrint('LibraryScreen: could not check widget pin support ($error)');
    }
  }

  /// Asks Android to add the Where Was I widget to the home screen. The
  /// system shows its own confirmation, so nothing more is needed here.
  Future<void> _requestWidgetPin() async {
    try {
      await HomeWidget.requestPinWidget(
        name: 'WhereWasIWidgetProvider',
        androidName: 'WhereWasIWidgetProvider',
        qualifiedAndroidName: 'com.mady.wherewasi.WhereWasIWidgetProvider',
      );
    } catch (error) {
      debugPrint('LibraryScreen: could not request widget pin ($error)');
    }
  }

  @override
  void dispose() {
    widget.searchOpen.removeListener(_onSearchFlagChanged);
    _widgetHoldTimer?.cancel();
    _query.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _startWidgetHold(PointerDownEvent event) {
    _widgetHoldStart = event.position;
    _widgetHoldTimer?.cancel();
    _widgetHoldTimer = Timer(_widgetThemeHold, _switchWidgetTheme);
  }

  /// Letting the finger wander off the button cancels the hold.
  void _moveWidgetHold(PointerMoveEvent event) {
    final start = _widgetHoldStart;
    if (start == null) return;
    if ((event.position - start).distance > 24) _cancelWidgetHold();
  }

  void _cancelWidgetHold() {
    _widgetHoldTimer?.cancel();
    _widgetHoldTimer = null;
    _widgetHoldStart = null;
  }

  /// Switches the widget between light and dark after the three second hold,
  /// and says which one it is now. When the widget follows the app, the look it
  /// has right now is the one that gets switched.
  void _switchWidgetTheme() {
    _widgetHoldTimer = null;
    _widgetHoldStart = null;
    if (!mounted) return;

    final current = switch (widgetThemeNotifier.value) {
      ThemeMode.light => Brightness.light,
      ThemeMode.dark => Brightness.dark,
      ThemeMode.system => Theme.of(context).brightness,
    };
    final next = current == Brightness.dark ? ThemeMode.light : ThemeMode.dark;
    widgetThemeNotifier.value = next;
    HapticFeedback.mediumImpact();

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          'Widget theme changed to ${next == ThemeMode.dark ? 'dark' : 'light'}',
        ),
      ),
    );
  }

  /// Opens the search bar. A reader who already has books gets the keyboard a
  /// moment later, once the bar is in place. A first time reader with an empty
  /// library does not get the keyboard until they tap the field.
  void _openSearch() {
    setState(() => _searching = true);
    widget.searchOpen.value = true;
    if (_bookCount == 0) return;
    Future<void>.delayed(_keyboardDelay, () {
      if (!mounted || !_searching) return;
      _searchFocus.requestFocus();
    });
  }

  List<Book> _apply(List<Book> all) {
    final query = _query.text.trim().toLowerCase();
    return all.where((book) {
      final matchesFilter = switch (_filter) {
        _LibraryFilter.all => true,
        _LibraryFilter.reading => book.status == BookStatus.reading,
        _LibraryFilter.wantToRead => book.status == BookStatus.wantToRead,
        _LibraryFilter.finished => book.status == BookStatus.finished,
      };
      if (!matchesFilter) return false;
      if (query.isEmpty) return true;
      return book.title.toLowerCase().contains(query) ||
          (book.author ?? '').toLowerCase().contains(query);
    }).toList();
  }

  String _emptyMessage() {
    if (_query.text.trim().isNotEmpty) return 'No books match that search.';
    return switch (_filter) {
      _LibraryFilter.all => 'No books yet.',
      _LibraryFilter.reading => 'Books you are reading show up here.',
      _LibraryFilter.wantToRead => 'Books you want to read show up here.',
      _LibraryFilter.finished => 'Books you finish show up here.',
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: ContentColumn(
          maxWidth: 900,
          child: StreamBuilder<List<Book>>(
            stream: _books,
            builder: (context, snapshot) {
              final all = snapshot.data ?? const <Book>[];
              _bookCount = all.length;
              final visible = _apply(all);

              return CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: _searching
                          ? _buildSearch(context)
                          : _buildHeader(context, visible.length),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    sliver: SliverToBoxAdapter(child: _buildFilters()),
                  ),
                  ..._buildBody(context, snapshot, all, visible),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int count) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(
                  'Library',
                  style: AppFonts.serifStyle(
                    size: 30,
                    height: 1.25,
                    color: colors.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$count ${count == 1 ? 'book' : 'books'}',
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        IconButton.outlined(
          tooltip: 'Search',
          onPressed: _openSearch,
          icon: const Icon(Icons.search, size: 20),
          style: IconButton.styleFrom(
            fixedSize: const Size(40, 40),
            side: BorderSide(color: colors.outline),
            foregroundColor: colors.onSurface,
          ),
        ),
        if (_canPinWidget) ...[
          const SizedBox(width: 10),
          Listener(
            onPointerDown: _startWidgetHold,
            onPointerMove: _moveWidgetHold,
            onPointerUp: (_) => _cancelWidgetHold(),
            onPointerCancel: (_) => _cancelWidgetHold(),
            child: IconButton.outlined(
              tooltip:
                  'Add widget to home screen. Hold for 3 seconds to switch the widget theme.',
              onPressed: _requestWidgetPin,
              icon: const Icon(Icons.widgets_outlined, size: 20),
              style: IconButton.styleFrom(
                fixedSize: const Size(40, 40),
                side: BorderSide(color: colors.outline),
                foregroundColor: colors.onSurface,
              ),
            ),
          ),
        ],
        const SizedBox(width: 10),
        IconButton.filled(
          tooltip: 'Add a book',
          onPressed: () => showAddBookSheet(context),
          icon: const Icon(Icons.add, size: 22),
          style: IconButton.styleFrom(fixedSize: const Size(40, 40)),
        ),
      ],
    );
  }

  Widget _buildSearch(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _query,
            focusNode: _searchFocus,
            textInputAction: TextInputAction.search,
            onChanged: (_) => setState(() {}),
            decoration: appFieldDecoration(
              context,
              label: 'Search title or author',
            ),
          ),
        ),
        const SizedBox(width: 10),
        IconButton.outlined(
          tooltip: 'Close search',
          onPressed: () {
            setState(() {
              _query.clear();
              _searching = false;
            });
            widget.searchOpen.value = false;
          },
          icon: const Icon(Icons.close, size: 20),
          style: IconButton.styleFrom(
            fixedSize: const Size(40, 40),
            side: BorderSide(color: colors.outline),
            foregroundColor: colors.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final filter in _LibraryFilter.values)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: _FilterChip(
                label: _labels[filter] ?? '',
                selected: _filter == filter,
                onTap: () => setState(() => _filter = filter),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildBody(
    BuildContext context,
    AsyncSnapshot<List<Book>> snapshot,
    List<Book> all,
    List<Book> visible,
  ) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (snapshot.hasError) {
      return const <Widget>[
        SliverPadding(
          padding: EdgeInsets.all(20),
          sliver: SliverToBoxAdapter(
            child: Text('Could not load your library.'),
          ),
        ),
      ];
    }
    if (!snapshot.hasData) return const <Widget>[];

    if (all.isEmpty) {
      return <Widget>[
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, _navClearance),
          sliver: SliverToBoxAdapter(
            child: EmptyShelfCard(onAdd: () => showAddBookSheet(context)),
          ),
        ),
      ];
    }

    if (visible.isEmpty) {
      return <Widget>[
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, _navClearance),
          sliver: SliverToBoxAdapter(
            child: Text(
              _emptyMessage(),
              textAlign: TextAlign.center,
              style: textTheme.bodyLarge?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ];
    }

    return <Widget>[
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, _navClearance),
        sliver: SliverLayoutBuilder(
          builder: (context, constraints) {
            const gap = 12.0;
            final extent = constraints.crossAxisExtent;
            final columns = math.max(3, (extent / 150).floor());
            final itemWidth = (extent - gap * (columns - 1)) / columns;
            final statusHeight = 10 + MediaQuery.textScalerOf(context).scale(16);

            return SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisSpacing: 20,
                crossAxisSpacing: gap,
                mainAxisExtent: itemWidth * 1.5 + statusHeight,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final book = visible[index];
                  return BookGridCard(
                    book: book,
                    onTap: () => Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => BookDetailScreen(bookId: book.id),
                      ),
                    ),
                  );
                },
                childCount: visible.length,
              ),
            );
          },
        ),
      ),
    ];
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      onTap: onTap,
      child: ExcludeSemantics(
        child: Material(
          color: selected ? colors.primaryContainer : Colors.transparent,
          shape: StadiumBorder(
            side: selected
                ? BorderSide.none
                : BorderSide(color: colors.outline),
          ),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                label,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected
                      ? colors.onPrimaryContainer
                      : colors.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
