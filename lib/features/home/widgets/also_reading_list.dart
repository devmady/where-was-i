import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart' show Book;
import '../../library/models/book_extensions.dart';
import '../../library/screens/book_detail_screen.dart';
import '../../library/widgets/book_cover.dart';
import '../../library/widgets/progress_bar.dart';
import '../../profile/widgets/settings_widgets.dart';

/// The other books being read right now, under the main continue-reading card.
class AlsoReadingList extends StatelessWidget {
  const AlsoReadingList({super.key, required this.books});

  final List<Book> books;

  @override
  Widget build(BuildContext context) {
    return SettingsSection(
      label: 'Also reading',
      child: SettingsGroup(
        dividerIndent: 76,
        children: [for (final book in books) _BookRow(book: book)],
      ),
    );
  }
}

class _BookRow extends StatelessWidget {
  const _BookRow({required this.book});

  final Book book;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final total = book.totalPages;
    final fraction = book.progressFraction;

    final progressText = book.currentPage == 0
        ? 'Not started'
        : (total == null
            ? 'page ${book.currentPage}'
            : 'page ${book.currentPage} of $total');

    return InkWell(
      onTap: () => Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => BookDetailScreen(bookId: book.id),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            SizedBox(width: 44, child: BookCover(book: book)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    progressText,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  if (fraction != null && book.currentPage > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: ProgressBar(value: fraction),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, size: 20, color: colors.outline),
          ],
        ),
      ),
    );
  }
}
