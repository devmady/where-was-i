import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'shared/widgets/app_shell.dart';

void main() {
  runApp(const WhereWasIApp());
}

class WhereWasIApp extends StatelessWidget {
  const WhereWasIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Where Was I?',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system, // follows OS setting; swap for a
      // user-toggleable switch later (store choice locally, no cloud)
      home: const AppShell(),
    );
  }
}
