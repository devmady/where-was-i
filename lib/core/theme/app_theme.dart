import 'package:flutter/material.dart';

import 'app_fonts.dart';

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
  static const lightSurfaceContainer = Color(0xFFF3F1ED);
  static const lightSurfaceContainerHigh = Color(0xFFE9E6E0);
  static const lightOutline = Color(0xFFA39B90);
  static const lightOutlineVariant = Color(0xFFE1DBD1);
  static const lightTealContainer = Color(0xFFD9EBE4);
  static const lightOnTealContainer = Color(0xFF0A4A3A);
  static const lightError = Color(0xFFB3261C);

  // Dark mode
  static const darkBackground = Color(0xFF161B19);
  static const darkTextPrimary = Color(0xFFF2F2F0);
  static const darkTextSecondary = Color(0xFF9A9A97);
  static const darkTeal = Color(0xFF4FC9A6);
  static const darkTerracotta = Color(0xFFE08659);
  static const darkSurfaceContainer = Color(0xFF1E2523);
  static const darkSurfaceContainerHigh = Color(0xFF2A3230);
  static const darkOutline = Color(0xFF5B6560);
  static const darkOutlineVariant = Color(0xFF2F3835);
  static const darkTealContainer = Color(0xFF1D3B32);
  static const darkOnTealContainer = Color(0xFFBFEBDD);
  static const darkError = Color(0xFFF2B8B5);
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
      onSurfaceVariant: AppColors.lightTextSecondary,
      primary: AppColors.lightTeal,
      onPrimary: AppColors.lightBackground,
      secondary: AppColors.lightTerracotta,
      onSecondary: AppColors.lightBackground,
      surfaceContainerHighest: const Color(0xFFF2F1EE),
      surfaceContainer: AppColors.lightSurfaceContainer,
      surfaceContainerHigh: AppColors.lightSurfaceContainerHigh,
      outline: AppColors.lightOutline,
      outlineVariant: AppColors.lightOutlineVariant,
      primaryContainer: AppColors.lightTealContainer,
      onPrimaryContainer: AppColors.lightOnTealContainer,
      error: AppColors.lightError,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: AppFonts.sans,
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
      onSurfaceVariant: AppColors.darkTextSecondary,
      primary: AppColors.darkTeal,
      onPrimary: AppColors.darkBackground,
      secondary: AppColors.darkTerracotta,
      onSecondary: AppColors.darkBackground,
      surfaceContainerHighest: const Color(0xFF1F2624),
      surfaceContainer: AppColors.darkSurfaceContainer,
      surfaceContainerHigh: AppColors.darkSurfaceContainerHigh,
      outline: AppColors.darkOutline,
      outlineVariant: AppColors.darkOutlineVariant,
      primaryContainer: AppColors.darkTealContainer,
      onPrimaryContainer: AppColors.darkOnTealContainer,
      error: AppColors.darkError,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: AppFonts.sans,
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
