import 'package:flutter/material.dart';

import '../models/book.dart';

/// A single book's cover, title, author, and progress bar in the
/// Library grid. Cover is a placeholder monogram tile until real
/// cover art is decided on (separate open question, not part of
/// this pass).
class BookCard extends StatelessWidget {
  const BookCard({super.key, required this.book, this.onTap});

  final Book book;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  book.title.isNotEmpty ? book.title[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            // Fixed regardless of whether this title actually wraps
            // to 1 or 2 lines — otherwise a short title "gives back"
            // space to the Expanded cover above it, and covers end up
            // different heights across the same row (13 * 1.2 line
            // height * 2 lines = 31.2, rounded up).
            height: 32,
            child: Text(
              book.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                height: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            book.author,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodySmall,
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: book.progress,
              minHeight: 4,
              backgroundColor: colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }
}
