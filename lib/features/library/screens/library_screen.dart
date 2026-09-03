import 'package:flutter/material.dart';

/// Library screen — left of the Home center, holds the book list.
/// Currently a plain placeholder. The primary add-book entry point
/// lives here (app bar + or FAB) per the locked nav plan.
class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: Text(
            'Library',
            style: textTheme.titleLarge,
          ),
        ),
      ),
    );
  }
}
