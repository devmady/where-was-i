import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart' show Book;
import '../../../core/database/tables.dart' show BookStatus;
import '../../../core/theme/app_fonts.dart';
import '../../../shared/widgets/content_column.dart';
import '../../../shared/widgets/field_decoration.dart';
import '../state/book_repository.dart';
import '../widgets/add_book_sheet.dart';
import '../widgets/book_grid_card.dart';
import '../widgets/empty_shelf_card.dart';
import 'book_detail_screen.dart';

enum _LibraryFilter { all, reading, wantToRead, finished }

/// Library screen, left of the Home center. Every book as a cover grid, with
/// filters by status, a simple search, and the add button in the header.
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  static const double _navClearance = 112;

  static const Map<_LibraryFilter, String> _labels = {
    _LibraryFilter.all: 'All',
    _LibraryFilter.reading: 'Reading',
    _LibraryFilter.wantToRead: 'Want to read',
    _LibraryFilter.finished: 'Finished',
  };

  final Stream<List<Book>> _books = BookRepository.instance.watchAll();
  final TextEditingController _query = TextEditingController();

  _LibraryFilter _filter = _LibraryFilter.all;
  bool _searching = false;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
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
          onPressed: () => setState(() => _searching = true),
          icon: const Icon(Icons.search, size: 20),
          style: IconButton.styleFrom(
            fixedSize: const Size(40, 40),
            side: BorderSide(color: colors.outline),
            foregroundColor: colors.onSurface,
          ),
        ),
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
            autofocus: true,
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
          onPressed: () => setState(() {
            _query.clear();
            _searching = false;
          }),
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
