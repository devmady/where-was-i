import 'package:flutter/material.dart';

import '../models/book.dart';
import '../widgets/book_card.dart';
import '../widgets/library_filter_tabs.dart';

/// Library screen — left of the Home center, holds the book list.
/// Primary add-book entry point lives here (top bar "+"), sharing the
/// same trigger as the Home long-press shortcut per the locked nav
/// plan (see AppShell).
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key, this.onAddBook});

  /// Opens the shared add-book dialog/banner. Not built yet (see
  /// handoff doc §6) — currently wired to the same stub as the Home
  /// long-press shortcut.
  final VoidCallback? onAddBook;

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  LibraryFilter _filter = LibraryFilter.all;
  String _query = '';

  List<Book> get _filteredBooks {
    return mockBooks.where((book) {
      final matchesFilter = switch (_filter) {
        LibraryFilter.all => true,
        LibraryFilter.reading => book.status == BookStatus.reading,
        LibraryFilter.done => book.status == BookStatus.done,
        LibraryFilter.queued => book.status == BookStatus.queued,
      };
      final query = _query.trim().toLowerCase();
      final matchesQuery = query.isEmpty ||
          book.title.toLowerCase().contains(query) ||
          book.author.toLowerCase().contains(query);
      return matchesFilter && matchesQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final books = _filteredBooks;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Library',
                    style: textTheme.titleLarge?.copyWith(fontSize: 28),
                  ),
                  FilledButton.icon(
                    onPressed: widget.onAddBook,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add'),
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                onChanged: (value) => setState(() => _query = value),
                style: textTheme.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Search your library…',
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              LibraryFilterTabs(
                selected: _filter,
                onSelected: (filter) => setState(() => _filter = filter),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: books.isEmpty
                    ? Center(
                        child: Text(
                          'No books here yet.',
                          style: textTheme.bodySmall,
                        ),
                      )
                    : GridView.builder(
                        // Bottom padding clears the floating nav pill
                        // that AppShell overlays via Stack — tune once
                        // MainNavBar's real height is measured.
                        padding: const EdgeInsets.only(bottom: 110),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 20,
                          crossAxisSpacing: 15,
                          childAspectRatio: 0.58,
                        ),
                        itemCount: books.length,
                        itemBuilder: (context, index) => BookCard(book: books[index]),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
