import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/database/app_database.dart' show Book;
import '../../../core/database/tables.dart' show BookStatus;
import '../../../core/theme/app_fonts.dart';
import '../state/book_repository.dart';

/// Opens the Where are you now? sheet for a book. Used from Home and from
/// the book detail screen.
Future<void> showUpdatePageSheet(BuildContext context, Book book) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    constraints: const BoxConstraints(maxWidth: 560),
    builder: (sheetContext) => _UpdatePageSheet(book: book, hostContext: context),
  );
}

/// Asks first, then marks the book as finished. Returns true when it did.
Future<bool> confirmAndMarkFinished(BuildContext context, Book book) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Mark as finished?'),
      content: Text(
        '${book.title} moves to Finished and its last page is logged.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Not yet'),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Mark as finished'),
        ),
      ],
    ),
  );
  if (confirmed != true) return false;
  await BookRepository.instance.markFinished(book.id);
  return true;
}

class _UpdatePageSheet extends StatefulWidget {
  const _UpdatePageSheet({required this.book, required this.hostContext});

  final Book book;
  final BuildContext hostContext;

  @override
  State<_UpdatePageSheet> createState() => _UpdatePageSheetState();
}

class _UpdatePageSheetState extends State<_UpdatePageSheet> {
  late final TextEditingController _controller;
  late int _page;

  int get _max => widget.book.totalPages ?? 99999;

  @override
  void initState() {
    super.initState();
    _page = widget.book.currentPage;
    _controller = TextEditingController(text: '$_page');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setPage(int value) {
    final next = value.clamp(0, _max).toInt();
    setState(() => _page = next);
    _controller.value = TextEditingValue(
      text: '$next',
      selection: TextSelection.collapsed(offset: '$next'.length),
    );
  }

  Future<void> _save() async {
    final navigator = Navigator.of(context);
    final host = widget.hostContext;
    final book = widget.book;
    final total = book.totalPages;
    final reachedEnd =
        total != null && _page >= total && book.status != BookStatus.finished;

    await BookRepository.instance.updatePage(book.id, _page);
    if (!mounted) return;
    navigator.pop();

    if (reachedEnd && host.mounted) {
      final finish = await showDialog<bool>(
        context: host,
        builder: (dialogContext) => AlertDialog(
          title: const Text('You reached the last page'),
          content: Text('Mark ${book.title} as finished?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Not yet'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Mark as finished'),
            ),
          ],
        ),
      );
      if (finish == true) {
        await BookRepository.instance.markFinished(book.id);
      }
    }
  }

  Future<void> _finish() async {
    final navigator = Navigator.of(context);
    final done = await confirmAndMarkFinished(context, widget.book);
    if (done && mounted) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final book = widget.book;
    final total = book.totalPages;
    final delta = _page - book.currentPage;

    final String deltaText;
    if (delta == 0) {
      deltaText = 'Same page as your last update';
    } else if (delta > 0) {
      deltaText =
          '+$delta ${delta == 1 ? 'page' : 'pages'} since your last update';
    } else {
      deltaText =
          '${-delta} ${delta == -1 ? 'page' : 'pages'} back from your last update';
    }

    final stepStyle = IconButton.styleFrom(
      fixedSize: const Size(52, 52),
      side: BorderSide(color: colors.outline),
    );

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          4,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Where are you now?',
              style: AppFonts.serifStyle(
                size: 26,
                height: 1.25,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${book.title}. Last logged: page ${book.currentPage}.',
              style: textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton.outlined(
                  tooltip: 'Previous page',
                  onPressed: _page > 0 ? () => _setPage(_page - 1) : null,
                  icon: const Icon(Icons.remove),
                  style: stepStyle,
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 140,
                  child: Semantics(
                    label: 'Current page',
                    child: TextField(
                      controller: _controller,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      textAlign: TextAlign.center,
                      maxLength: 6,
                      style: AppFonts.serifStyle(
                        size: 56,
                        height: 1.15,
                        color: colors.onSurface,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        counterText: '',
                        border: UnderlineInputBorder(
                          borderSide: BorderSide(color: colors.outline),
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: colors.outline),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: colors.primary,
                            width: 2,
                          ),
                        ),
                      ),
                      onChanged: (text) {
                        final parsed = int.tryParse(text);
                        if (parsed != null) {
                          setState(() => _page = parsed.clamp(0, _max).toInt());
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                IconButton.outlined(
                  tooltip: 'Next page',
                  onPressed: _page < _max ? () => _setPage(_page + 1) : null,
                  icon: const Icon(Icons.add),
                  style: stepStyle,
                ),
              ],
            ),
            if (total != null) ...[
              const SizedBox(height: 6),
              Text(
                'of $total pages',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 20),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              children: [
                for (final step in const [5, 10, 25])
                  ActionChip(
                    label: Text('+$step'),
                    onPressed: () => _setPage(_page + step),
                    backgroundColor: Colors.transparent,
                    shape: const StadiumBorder(),
                    side: BorderSide(color: colors.outline),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              deltaText,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: delta > 0 ? colors.secondary : colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: delta == 0 ? null : _save,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: const StadiumBorder(),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('Save'),
            ),
            const SizedBox(height: 4),
            TextButton.icon(
              onPressed: _finish,
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
        ),
      ),
    );
  }
}
