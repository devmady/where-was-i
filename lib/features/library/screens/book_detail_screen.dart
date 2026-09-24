import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart' show Book, ProgressEntry;
import '../../../core/database/tables.dart' show BookStatus;
import '../../../core/date_labels.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_theme.dart' show AppTagColors;
import '../../../shared/widgets/content_column.dart';
import '../../profile/widgets/settings_widgets.dart';
import '../models/book_extensions.dart';
import '../state/book_repository.dart';
import '../widgets/add_book_sheet.dart';
import '../widgets/book_cover.dart';
import '../widgets/progress_bar.dart';
import '../widgets/update_page_sheet.dart';

enum _BookAction { edit, delete }

/// One book: its cover, where the reader is, recent page updates, and the
/// actions to update, edit, finish or delete it.
class BookDetailScreen extends StatefulWidget {
  const BookDetailScreen({super.key, required this.bookId});

  final int bookId;

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  late final Stream<Book?> _book =
      BookRepository.instance.watchById(widget.bookId);
  late final Stream<List<ProgressEntry>> _entries =
      BookRepository.instance.watchEntries(widget.bookId, limit: 5);

  Future<void> _confirmDelete(Book book) async {
    final navigator = Navigator.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this book?'),
        content: Text(
          '${book.title} and its reading history are deleted from this '
          'device. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await BookRepository.instance.deleteBook(book.id);
    if (!mounted) return;
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: ContentColumn(
          child: StreamBuilder<Book?>(
            stream: _book,
            builder: (context, snapshot) {
              final book = snapshot.data;
              if (book == null) {
                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _backButton(context),
                    ),
                  ],
                );
              }

              final author = book.author;
              final tag = book.tagColor;
              final Color? tagColor =
                  (tag != null && tag >= 0 && tag < AppTagColors.all.length)
                      ? AppTagColors.all[tag]
                      : null;

              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                children: [
                  Row(
                    children: [
                      _backButton(context),
                      const Spacer(),
                      _MoreMenu(
                        onSelected: (action) {
                          switch (action) {
                            case _BookAction.edit:
                              showAddBookSheet(context, editing: book);
                            case _BookAction.delete:
                              _confirmDelete(book);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: SizedBox(width: 140, child: BookCover(book: book)),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    book.title,
                    textAlign: TextAlign.center,
                    style: AppFonts.serifStyle(
                      size: 28,
                      height: 1.2,
                      color: colors.onSurface,
                    ),
                  ),
                  if (author != null && author.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      author,
                      textAlign: TextAlign.center,
                      style: textTheme.bodyLarge?.copyWith(
                        fontSize: 15,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Center(child: _StatusPill(status: book.status)),
                  const SizedBox(height: 24),
                  _ProgressCard(book: book),
                  StreamBuilder<List<ProgressEntry>>(
                    stream: _entries,
                    builder: (context, entriesSnapshot) {
                      final entries =
                          entriesSnapshot.data ?? const <ProgressEntry>[];
                      if (entries.isEmpty) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 24),
                        child: SettingsSection(
                          label: 'Recent updates',
                          child: SettingsGroup(
                            children: [
                              for (final entry in entries)
                                _UpdateRow(entry: entry),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  SettingsGroup(
                    children: [
                      _DetailRow(
                        label: 'Added',
                        value: monthDayYearLabel(book.addedAt),
                      ),
                      if (book.startedAt != null)
                        _DetailRow(
                          label: 'Started',
                          value: monthDayYearLabel(book.startedAt!),
                        ),
                      if (book.finishedAt != null)
                        _DetailRow(
                          label: 'Finished',
                          value: monthDayYearLabel(book.finishedAt!),
                        ),
                      if (tagColor != null)
                        _DetailRow(
                          label: 'Tag color',
                          value: kTagColorNames[tag!],
                          dot: tagColor,
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SettingsGroup(
                    children: [
                      SettingsRow(
                        icon: Icons.delete_outline,
                        title: 'Delete book',
                        destructive: true,
                        trailing: SettingsTrailing.none,
                        onTap: () => _confirmDelete(book),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _backButton(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return IconButton.outlined(
      tooltip: 'Back',
      onPressed: () => Navigator.of(context).maybePop(),
      icon: const Icon(Icons.arrow_back, size: 20),
      style: IconButton.styleFrom(
        fixedSize: const Size(40, 40),
        side: BorderSide(color: colors.outline),
        foregroundColor: colors.onSurface,
      ),
    );
  }
}

class _MoreMenu extends StatelessWidget {
  const _MoreMenu({required this.onSelected});

  final ValueChanged<_BookAction> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SizedBox(
      width: 40,
      height: 40,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: colors.outline),
        ),
        child: PopupMenuButton<_BookAction>(
          tooltip: 'More',
          padding: EdgeInsets.zero,
          icon: Icon(Icons.more_vert, size: 20, color: colors.onSurface),
          onSelected: onSelected,
          itemBuilder: (context) => [
            const PopupMenuItem(value: _BookAction.edit, child: Text('Edit')),
            PopupMenuItem(
              value: _BookAction.delete,
              child: Text('Delete', style: TextStyle(color: colors.error)),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final BookStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final label = switch (status) {
      BookStatus.reading => 'Reading',
      BookStatus.wantToRead => 'Want to read',
      BookStatus.finished => 'Finished',
    };
    final dot = switch (status) {
      BookStatus.reading => colors.secondary,
      BookStatus.wantToRead => colors.outline,
      BookStatus.finished => colors.primary,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: dot),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: colors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.book});

  final Book book;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final total = book.totalPages;
    final fraction = book.progressFraction;

    final buttonStyle = FilledButton.styleFrom(
      minimumSize: const Size.fromHeight(52),
      shape: const StadiumBorder(),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    );

    final Widget content;
    switch (book.status) {
      case BookStatus.reading:
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  'page ${book.currentPage}',
                  style: AppFonts.serifStyle(
                    size: 30,
                    height: 1.2,
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
            if (fraction != null) ...[
              const SizedBox(height: 16),
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
              style: buttonStyle,
              child: const Text('Update page'),
            ),
            const SizedBox(height: 4),
            TextButton.icon(
              onPressed: () => confirmAndMarkFinished(context, book),
              icon: const Icon(Icons.check, size: 18),
              label: const Text('I finished this book'),
              style: TextButton.styleFrom(
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      case BookStatus.wantToRead:
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Not started yet',
              style: AppFonts.serifStyle(
                size: 24,
                height: 1.25,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => showUpdatePageSheet(context, book),
              style: buttonStyle,
              child: const Text('Start reading'),
            ),
          ],
        );
      case BookStatus.finished:
        final finishedAt = book.finishedAt;
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check, color: colors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    finishedAt == null
                        ? 'Finished'
                        : 'Finished ${monthDayYearLabel(finishedAt)}',
                    style: AppFonts.serifStyle(
                      size: 24,
                      height: 1.25,
                      color: colors.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            if (total != null) ...[
              const SizedBox(height: 4),
              Text(
                '$total pages',
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ],
        );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: content,
    );
  }
}

class _UpdateRow extends StatelessWidget {
  const _UpdateRow({required this.entry});

  final ProgressEntry entry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final added = entry.pagesAdded;
    final amount = added > 0 ? '+$added' : '$added';
    final pages = added.abs() == 1 ? 'page' : 'pages';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friendlyDayLabel(entry.loggedAt),
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Now on page ${entry.page}',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$amount $pages',
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: added > 0 ? colors.secondary : colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value, this.dot});

  final String label;
  final String value;
  final Color? dot;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
                color: colors.onSurface,
              ),
            ),
          ),
          if (dot != null) ...[
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(shape: BoxShape.circle, color: dot),
            ),
            const SizedBox(width: 8),
          ],
          Text(
            value,
            style: textTheme.bodyLarge?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
