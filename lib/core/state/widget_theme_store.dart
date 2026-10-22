import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Saves the theme chosen for the home screen widget on this device. System
/// here means the widget follows the app theme, and Light or Dark fixes the
/// widget to that look whatever the app is set to. Nothing here leaves the
/// device.
class WidgetThemeStore {
  WidgetThemeStore._();

  static const String _key = 'widget.themeMode';
  static final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  /// Reads the saved choice, or system when nothing has been saved yet.
  static Future<ThemeMode> load() async {
    try {
      final saved = await _prefs.getString(_key);
      return switch (saved) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
    } catch (error) {
      debugPrint('WidgetThemeStore: could not read the saved theme ($error)');
      return ThemeMode.system;
    }
  }

  /// Saves the choice for next launch.
  static Future<void> save(ThemeMode mode) async {
    try {
      await _prefs.setString(_key, mode.name);
    } catch (error) {
      debugPrint('WidgetThemeStore: could not save the theme ($error)');
    }
  }
}
