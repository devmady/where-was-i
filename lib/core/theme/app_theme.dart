import 'package:flutter/material.dart';

/// Theme for "Where Was I?"
///
/// Palette: teal (primary accent) + terracotta (secondary accent) on a
/// warm near-white / near-black base. Burgundy and dusty blue are
/// reserved separately for user-assigned book tag colors — not used
/// here as interface accents. See AppTagColors below.
///
/// Widgets should reference Theme.of(context).colorScheme rather than
/// these constants directly, so light/dark mode switching works
/// correctly throughout the app.
class AppColors {
  AppColors._();

  // Light mode
  static const lightBackground = Color(0xFFFFFFFF);
  static const lightTextPrimary = Color(0xFF1A1A1A);
  static const lightTextSecondary = Color(0xFF6B6B6B);
  static const lightTeal = Color(0xFF0F6E56);
  static const lightTerracotta = Color(0xFFA3491F);

  // Dark mode
  static const darkBackground = Color(0xFF161B19);
  static const darkTextPrimary = Color(0xFFF2F2F0);
  static const darkTextSecondary = Color(0xFF9A9A97);
  static const darkTeal = Color(0xFF4FC9A6);
  static const darkTerracotta = Color(0xFFE08659);
}

/// Reserved colors for user-assigned book tags/shelves — not interface
/// accents. Same hue in both modes; only used inside tag chips/badges,
/// never for buttons, nav, or CTAs.
class AppTagColors {
  AppTagColors._();

  static const burgundy = Color(0xFF7A2233);
  static const dustyBlue = Color(0xFF3D5A73);
  static const teal = AppColors.lightTeal;
  static const terracotta = AppColors.lightTerracotta;

  static const all = [burgundy, dustyBlue, teal, terracotta];
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final colorScheme = ColorScheme.light(
      surface: AppColors.lightBackground,
      onSurface: AppColors.lightTextPrimary,
      primary: AppColors.lightTeal,
      onPrimary: AppColors.lightBackground,
      secondary: AppColors.lightTerracotta,
      onSecondary: AppColors.lightBackground,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: _textTheme(AppColors.lightTextPrimary, AppColors.lightTextSecondary),
    );
  }

  static ThemeData get dark {
    final colorScheme = ColorScheme.dark(
      surface: AppColors.darkBackground,
      onSurface: AppColors.darkTextPrimary,
      primary: AppColors.darkTeal,
      onPrimary: AppColors.darkBackground,
      secondary: AppColors.darkTerracotta,
      onSecondary: AppColors.darkBackground,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: _textTheme(AppColors.darkTextPrimary, AppColors.darkTextSecondary),
    );
  }

  static TextTheme _textTheme(Color primary, Color secondary) {
    return TextTheme(
      bodyLarge: TextStyle(color: primary),
      bodyMedium: TextStyle(color: primary),
      bodySmall: TextStyle(color: secondary),
      titleLarge: TextStyle(color: primary, fontWeight: FontWeight.w600),
      titleMedium: TextStyle(color: primary, fontWeight: FontWeight.w500),
    );
  }
}
