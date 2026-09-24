import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart' show Book;
import '../../../core/database/tables.dart' show BookStatus;
import '../../../core/date_labels.dart';
import '../models/book_extensions.dart';
import 'book_cover.dart';
import 'progress_bar.dart';

/// One book in the library grid: the cover, and a single line about where
/// the reader is with it.
class BookGridCard extends StatelessWidget {
  const BookGridCard({super.key, required this.book, required this.onTap});

  final Book book;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      onTap: onTap,
      label: '${book.title}. ${_statusText(book)}',
      child: ExcludeSemantics(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BookCover(book: book),
              const SizedBox(height: 8),
              _StatusLine(book: book),
            ],
          ),
        ),
      ),
    );
  }

  static String _statusText(Book book) {
    final fraction = book.progressFraction;
    return switch (book.status) {
      BookStatus.reading => fraction == null
          ? 'Reading, page ${book.currentPage}'
          : 'Reading, ${(fraction * 100).round()} percent',
      BookStatus.finished => 'Finished',
      BookStatus.wantToRead => 'Want to read',
    };
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.book});

  final Book book;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: colors.onSurfaceVariant,
        );

    switch (book.status) {
      case BookStatus.reading:
        final fraction = book.progressFraction;
        if (fraction == null) {
          return Text('page ${book.currentPage}', style: style);
        }
        return Row(
          children: [
            Expanded(child: ProgressBar(value: fraction)),
            const SizedBox(width: 6),
            Text('${(fraction * 100).round()}%', style: style),
          ],
        );
      case BookStatus.finished:
        final finishedAt = book.finishedAt;
        return Row(
          children: [
            Icon(Icons.check, size: 14, color: colors.primary),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                finishedAt == null ? 'Finished' : monthYearLabel(finishedAt),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: style,
              ),
            ),
          ],
        );
      case BookStatus.wantToRead:
        return Text('Want to read', style: style);
    }
  }
}
