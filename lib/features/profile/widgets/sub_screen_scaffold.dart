import 'package:flutter/material.dart';

import '../../../core/theme/app_fonts.dart';
import '../../../shared/widgets/content_column.dart';

/// Shared frame for screens pushed from Profile: an outlined back button, a
/// serif title, scrolling content, and an optional pinned bottom action.
///
/// These screens are pushed on the root navigator, so they cover the floating
/// nav pill — matching the design.
class SubScreenScaffold extends StatelessWidget {
  const SubScreenScaffold({
    super.key,
    required this.title,
    required this.children,
    this.bottom,
  });

  final String title;
  final List<Widget> children;

  /// Pinned under the scrolling content (e.g. a Save changes button).
  final Widget? bottom;

  static const double _gap = 28;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: ContentColumn(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    IconButton.outlined(
                      tooltip: 'Back',
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back, size: 20),
                      style: IconButton.styleFrom(
                        fixedSize: const Size(40, 40),
                        side: BorderSide(color: colors.outline),
                        foregroundColor: colors.onSurface,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppFonts.serifStyle(
                            size: 24,
                            height: 1.25,
                            color: colors.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, _gap, 20, 32),
                  children: [
                    for (var i = 0; i < children.length; i++) ...[
                      if (i > 0) const SizedBox(height: _gap),
                      children[i],
                    ],
                  ],
                ),
              ),
              if (bottom != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: bottom,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
