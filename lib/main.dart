import 'package:flutter/material.dart';
import 'core/app_info.dart';
import 'core/state/theme_mode_store.dart';
import 'core/state/widget_theme_store.dart';
import 'core/theme/app_theme.dart';
import 'shared/state/widget_sync.dart';
import 'shared/widgets/app_shell.dart';

/// Holds the current theme mode so it can be read and changed from
/// anywhere (e.g. the Profile screen's theme toggle) without a full
/// state management package. Defaults to following the OS setting.
final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(ThemeMode.system);

/// The theme chosen for the home screen widget. System means the widget
/// follows the app theme above, Light or Dark fixes it to that look.
final ValueNotifier<ThemeMode> widgetThemeNotifier = ValueNotifier(ThemeMode.system);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  themeModeNotifier.value = await ThemeModeStore.load();
  themeModeNotifier.addListener(() {
    ThemeModeStore.save(themeModeNotifier.value);
  });
  widgetThemeNotifier.value = await WidgetThemeStore.load();
  widgetThemeNotifier.addListener(() {
    WidgetThemeStore.save(widgetThemeNotifier.value);
  });
  await AppInfo.load();
  WidgetSync.start(
    themeMode: themeModeNotifier,
    widgetThemeMode: widgetThemeNotifier,
  );
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
