import 'package:flutter/material.dart';
import 'core/app_info.dart';
import 'core/state/theme_mode_store.dart';
import 'core/theme/app_theme.dart';
import 'shared/widgets/app_shell.dart';

/// Holds the current theme mode so it can be read and changed from
/// anywhere (e.g. the Profile screen's theme toggle) without a full
/// state management package. Defaults to following the OS setting.
final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(ThemeMode.system);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  themeModeNotifier.value = await ThemeModeStore.load();
  themeModeNotifier.addListener(() {
    ThemeModeStore.save(themeModeNotifier.value);
  });
  await AppInfo.load();
  runApp(const WhereWasIApp());
}

class WhereWasIApp extends StatelessWidget {
  const WhereWasIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, themeMode, _) {
        return MaterialApp(
          title: 'Where Was I?',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeMode,
          home: const AppShell(),
        );
      },
    );
  }
}
