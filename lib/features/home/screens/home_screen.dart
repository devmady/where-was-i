import 'package:flutter/material.dart';

/// Home screen — center of the Library / Home / Profile strip.
///
/// Currently a plain placeholder with a static greeting. Will later
/// hold unique content (continue-reading card, stats) not duplicated
/// elsewhere in the app — see nav structure notes.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: Text(
            'Afternoon',
            style: textTheme.titleLarge,
          ),
        ),
      ),
    );
  }
}
