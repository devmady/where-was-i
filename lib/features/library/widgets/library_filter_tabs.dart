import 'package:flutter/material.dart';

enum LibraryFilter { all, reading, done, queued }

extension LibraryFilterLabel on LibraryFilter {
  String get label => switch (this) {
        LibraryFilter.all => 'All',
        LibraryFilter.reading => 'Reading',
        LibraryFilter.done => 'Done',
        LibraryFilter.queued => 'Queued',
      };
}

/// Status lives only here — book cards themselves stay clean with no
/// per-item status badge (locked decision from the design discussion).
class LibraryFilterTabs extends StatelessWidget {
  const LibraryFilterTabs({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final LibraryFilter selected;
  final ValueChanged<LibraryFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: LibraryFilter.values.map((filter) {
          final isActive = filter == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(filter.label),
              selected: isActive,
              onSelected: (_) => onSelected(filter),
              showCheckmark: false,
              selectedColor: colorScheme.primary,
              backgroundColor: colorScheme.surfaceContainerHighest,
              side: BorderSide.none,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              labelStyle: TextStyle(
                color: isActive ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
