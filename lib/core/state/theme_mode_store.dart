import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Saves the reader's theme choice on this device, so System, Light or Dark
/// survives quitting the app. Nothing here leaves the device.
class ThemeModeStore {
  ThemeModeStore._();

  static const String _key = 'theme.mode';
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
      debugPrint('ThemeModeStore: could not read the saved theme ($error)');
      return ThemeMode.system;
    }
  }

  /// Saves the reader's choice for next launch.
  static Future<void> save(ThemeMode mode) async {
    try {
      await _prefs.setString(_key, mode.name);
    } catch (error) {
      debugPrint('ThemeModeStore: could not save the theme ($error)');
    }
  }
}
