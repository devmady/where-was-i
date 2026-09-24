import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/database/app_database.dart' show Book;
import '../../../core/database/tables.dart' show BookStatus;
import '../../../core/date_labels.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_theme.dart' show AppTagColors;
import '../../../shared/state/image_storage.dart';
import '../../../shared/widgets/dashed_border.dart';
import '../../../shared/widgets/field_decoration.dart';
import '../../../shared/widgets/segmented_choice.dart';
import '../models/book_extensions.dart';
import '../state/book_repository.dart';

/// Opens the sheet for adding a book, or for editing one when editing is
/// given. Used from the Library header and from the Home long press.
Future<void> showAddBookSheet(BuildContext context, {Book? editing}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    constraints: const BoxConstraints(maxWidth: 560),
    builder: (sheetContext) => _AddBookSheet(editing: editing),
  );
}

class _AddBookSheet extends StatefulWidget {
  const _AddBookSheet({this.editing});

  final Book? editing;

  @override
  State<_AddBookSheet> createState() => _AddBookSheetState();
}

class _AddBookSheetState extends State<_AddBookSheet> {
  late final TextEditingController _title;
  late final TextEditingController _author;
  late final TextEditingController _total;
  late final TextEditingController _current;

  BookStatus _status = BookStatus.reading;
  bool _expanded = false;
  DateTime _finishedOn = DateTime.now();
  int? _tag;
  String? _coverPath;
  bool _pickingPhoto = false;

  String? _originalCoverPath;
  String? _titleError;
  String? _totalError;
  String? _currentError;

  bool get _editing => widget.editing != null;
  bool get _showsCurrent => !_editing && _status == BookStatus.reading;
  bool get _showsFinishedDate => !_editing && _status == BookStatus.finished;

  @override
  void initState() {
    super.initState();
    final book = widget.editing;
    _title = TextEditingController(text: book?.title ?? '');
    _author = TextEditingController(text: book?.author ?? '');
    _total = TextEditingController(text: book?.totalPages?.toString() ?? '');
    _current = TextEditingController();
    _tag = book?.tagColor;
    _coverPath = book?.coverPath;
    _originalCoverPath = book?.coverPath;
  }

  @override
  void dispose() {
    _title.dispose();
    _author.dispose();
    _total.dispose();
    _current.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    setState(() => _pickingPhoto = true);
    final path = await ImageStorage.pickAndSave(prefix: 'cover');
    if (!mounted) return;
    setState(() => _pickingPhoto = false);
    if (path == null) return;
    final previous = _coverPath;
    setState(() => _coverPath = path);
    if (previous != null && previous != path) {
      await ImageStorage.deleteIfExists(previous);
    }
  }

  Future<void> _removePhoto() async {
    final previous = _coverPath;
    setState(() => _coverPath = null);
    await ImageStorage.deleteIfExists(previous);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _finishedOn,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) setState(() => _finishedOn = picked);
  }

  Future<void> _submit() async {
    final title = _title.text.trim();
    final total = int.tryParse(_total.text.trim());
    final current = int.tryParse(_current.text.trim()) ?? 0;
    final editing = widget.editing;

    String? titleError;
    String? totalError;
    String? currentError;

    if (title.isEmpty) titleError = 'Add a title.';
    if (total != null && total < 1) {
      totalError = 'Total pages must be at least 1.';
    } else if (total != null && editing != null && total < editing.currentPage) {
      totalError = 'Your current page is ${editing.currentPage}.';
    } else if (total != null && _showsCurrent && current > total) {
      currentError = 'Past the last page.';
    }

    if (titleError != null || totalError != null || currentError != null) {
      setState(() {
        _titleError = titleError;
        _totalError = totalError;
        _currentError = currentError;
      });
      return;
    }

    final navigator = Navigator.of(context);
    final repository = BookRepository.instance;

    if (editing != null) {
      await repository.updateDetails(
        editing.id,
        title: title,
        author: _author.text,
        totalPages: total,
        tagColor: _tag,
        coverPath: _coverPath,
      );
    } else {
      await repository.addBook(
        title: title,
        author: _author.text,
        totalPages: total,
        currentPage: _showsCurrent ? current : 0,
        status: _status,
        finishedAt: _status == BookStatus.finished ? _finishedOn : null,
        coverPath: _coverPath,
        tagColor: _tag,
      );
    }

    if (!mounted) return;
    if (_coverPath != _originalCoverPath) {
      await ImageStorage.deleteIfExists(_originalCoverPath);
    }
    navigator.pop();
  }

  Widget _numberField(
    TextEditingController controller,
    String label,
    String? error,
  ) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      maxLength: 6,
      textInputAction: TextInputAction.next,
      onChanged: (_) {
        if (_totalError != null || _currentError != null) {
          setState(() {
            _totalError = null;
            _currentError = null;
          });
        }
      },
      decoration: appFieldDecoration(context, label: label, error: error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

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
              _editing ? 'Edit book' : 'Add a book',
              style: AppFonts.serifStyle(
                size: 26,
                height: 1.25,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _title,
              autofocus: !_editing,
              maxLength: 200,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              onChanged: (_) {
                if (_titleError != null) setState(() => _titleError = null);
              },
              decoration: appFieldDecoration(
                context,
                label: 'Title',
                error: _titleError,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _author,
              maxLength: 120,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: appFieldDecoration(context, label: 'Author'),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _numberField(_total, 'Total pages', _totalError),
                ),
                if (_showsCurrent) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: _numberField(
                      _current,
                      'Current page',
                      _currentError,
                    ),
                  ),
                ],
              ],
            ),
            if (!_editing) ...[
              const SizedBox(height: 16),
              SegmentedChoice<BookStatus>(
                value: _status,
                onChanged: (status) => setState(() => _status = status),
                options: const <SegmentOption<BookStatus>>[
                  SegmentOption(value: BookStatus.reading, label: 'Reading'),
                  SegmentOption(
                    value: BookStatus.wantToRead,
                    label: 'Want to read',
                  ),
                  SegmentOption(value: BookStatus.finished, label: 'Finished'),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () => setState(() => _expanded = !_expanded),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_expanded ? 'Fewer details' : 'More details'),
                    const SizedBox(width: 6),
                    Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              alignment: Alignment.topCenter,
              child: _expanded
                  ? _buildMoreDetails(context)
                  : const SizedBox(width: double.infinity),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _submit,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: const StadiumBorder(),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: Text(_editing ? 'Save changes' : 'Add book'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoreDetails(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final path = _coverPath;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        if (_showsFinishedDate) ...[
          InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(14),
            child: InputDecorator(
              decoration: appFieldDecoration(
                context,
                label: 'Finished on',
                suffixIcon: const Icon(Icons.calendar_today_outlined, size: 20),
              ),
              child: Text(monthDayYearLabel(_finishedOn)),
            ),
          ),
          const SizedBox(height: 20),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DashedBorder(
              color: colors.outline,
              radius: 8,
              child: SizedBox(
                width: 72,
                height: 108,
                child: path == null
                    ? Icon(Icons.add, color: colors.onSurfaceVariant)
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(path),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.broken_image_outlined,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cover photo',
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pick an image from this device. Without one, a colored '
                    'cover is made from the title.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _pickingPhoto ? null : _pickPhoto,
                        icon: _pickingPhoto
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.image_outlined, size: 18),
                        label: Text(
                          _pickingPhoto ? 'Choosing...' : 'Choose photo',
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colors.onSurface,
                          side: BorderSide(color: colors.outline),
                          shape: const StadiumBorder(),
                        ),
                      ),
                      if (path != null)
                        TextButton(
                          onPressed: _removePhoto,
                          child: const Text('Remove'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          'Color tag',
          style: textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Also colors the cover when there is no photo.',
          style: textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _Swatch(
              label: 'No color',
              color: null,
              selected: _tag == null,
              onTap: () => setState(() => _tag = null),
            ),
            for (var i = 0; i < AppTagColors.all.length; i++)
              _Swatch(
                label: kTagColorNames[i],
                color: AppTagColors.all[i],
                selected: _tag == i,
                onTap: () => setState(() => _tag = i),
              ),
          ],
        ),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color? color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: ExcludeSemantics(
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: 48,
            height: 48,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? colors.onSurface : Colors.transparent,
                width: 2,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                border: color == null
                    ? Border.all(color: colors.outline)
                    : null,
              ),
              child: Center(
                child: color == null
                    ? Icon(Icons.block, size: 20, color: colors.onSurfaceVariant)
                    : (selected
                        ? const Icon(Icons.check, size: 18, color: Colors.white)
                        : null),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
