import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart' show Book;
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_theme.dart' show AppTagColors;

/// A book cover at a 2 to 3 ratio. Shows the photo picked from this device,
/// or a colored cover made from the title. Very small covers show only the
/// first letter of the title. The color comes from the tag; with
/// no tag the cover uses the neutral inverse surface.
///
/// Tag colors are the same in light and dark mode, so the text on them is
/// always white.
class BookCover extends StatelessWidget {
  const BookCover({super.key, required this.book});

  final Book book;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: 'Cover of ${book.title}',
      child: ExcludeSemantics(
        child: AspectRatio(
          aspectRatio: 2 / 3,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final radius = BorderRadius.circular(width * 0.075);
              final placeholder = _Placeholder(book: book, width: width);
              final path = book.coverPath;

              return DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: radius,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.16),
                      blurRadius: width * 0.09,
                      offset: Offset(0, width * 0.04),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: radius,
                  child: path == null
                      ? placeholder
                      : Image.file(
                          File(path),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              placeholder,
                        ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.book, required this.width});

  final Book book;
  final double width;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tag = book.tagColor;
    final Color? tagColor =
        (tag != null && tag >= 0 && tag < AppTagColors.all.length)
            ? AppTagColors.all[tag]
            : null;
    final background = tagColor ?? colors.inverseSurface;
    final foreground = tagColor != null ? Colors.white : colors.onInverseSurface;
    final titleSize = (width * 0.115).clamp(10.0, 22.0).toDouble();

    if (width < 60) {
      final title = book.title.trim();
      final initial = title.isEmpty
          ? ''
          : String.fromCharCode(title.runes.first).toUpperCase();
      return Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: background),
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: width * 0.07,
            child: ColoredBox(color: Colors.black.withValues(alpha: 0.14)),
          ),
          Center(
            child: Text(
              initial,
              style: AppFonts.serifStyle(
                size: width * 0.45,
                color: foreground,
              ),
            ),
          ),
        ],
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: background),
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: width * 0.055,
          child: ColoredBox(color: Colors.black.withValues(alpha: 0.14)),
        ),
        Positioned.fill(
          child: Padding(
            padding: EdgeInsets.all(width * 0.083),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(width * 0.03),
                border: Border.all(color: foreground.withValues(alpha: 0.35)),
              ),
            ),
          ),
        ),
        Positioned(
          left: width * 0.16,
          right: width * 0.14,
          top: width * 0.19,
          child: Text(
            book.title,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: AppFonts.serifStyle(
              size: titleSize,
              height: 1.3,
              color: foreground,
            ),
          ),
        ),
      ],
    );
  }
}
