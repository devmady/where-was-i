import 'package:flutter/material.dart';

/// Profile screen — right of the Home center, holds settings and
/// account-level content. Currently a plain placeholder.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: Text(
            'Profile',
            style: textTheme.titleLarge,
          ),
        ),
      ),
    );
  }
}
