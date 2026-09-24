import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart' show Book;
import '../../../core/date_labels.dart';
import '../../../core/theme/app_fonts.dart';
import '../../library/models/book_extensions.dart';
import '../../library/screens/book_detail_screen.dart';
import '../../library/widgets/add_book_sheet.dart';
import '../../library/widgets/book_cover.dart';
import '../../library/widgets/progress_bar.dart';
import '../../library/widgets/update_page_sheet.dart';

/// The answer to where was I: the book being read, the page the reader left
/// off on, and one action to update it.
class ContinueReadingCard extends StatelessWidget {
  const ContinueReadingCard({super.key, required this.book});

  final Book book;

  String _lastReadText(DateTime when) {
    final label = friendlyDayLabel(when);
    if (label == 'Today' || label == 'Yesterday') {
      return 'Last read ${label.toLowerCase()}';
    }
    return 'Last read on $label';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final total = book.totalPages;
    final fraction = book.progressFraction;
    final author = book.author;
    final started = book.currentPage > 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (_) => BookDetailScreen(bookId: book.id),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 104, child: BookCover(book: book)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.serifStyle(
                          size: 22,
                          height: 1.27,
                          color: colors.onSurface,
                        ),
                      ),
                      if (author != null && author.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            author,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodyMedium?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      const SizedBox(height: 14),
                      if (started) ...[
                        Text(
                          'You left off at page',
                          style: textTheme.bodySmall?.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '${book.currentPage}',
                              style: AppFonts.serifStyle(
                                size: 40,
                                height: 1.15,
                                color: colors.onSurface,
                              ),
                            ),
                            if (total != null) ...[
                              const SizedBox(width: 6),
                              Text(
                                'of $total',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          _lastReadText(book.updatedAt),
                          style: textTheme.bodySmall?.copyWith(
                            fontSize: 13,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ] else
                        Text(
                          'You have not started yet.',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (fraction != null && started) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: ProgressBar(value: fraction, height: 8)),
                const SizedBox(width: 12),
                Text(
                  '${(fraction * 100).round()}%',
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => showUpdatePageSheet(context, book),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: const StadiumBorder(),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: const Text('Update page'),
          ),
        ],
      ),
    );
  }
}

/// Shown when the library has books but none is being read right now.
class NothingInProgressCard extends StatelessWidget {
  const NothingInProgressCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Nothing in progress',
            style: AppFonts.serifStyle(
              size: 24,
              height: 1.25,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pick a book from your list, or add a new one.',
            style: textTheme.bodyLarge?.copyWith(
              fontSize: 15,
              height: 1.45,
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => showAddBookSheet(context),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add a book'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: const StadiumBorder(),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
