import 'package:flutter/painting.dart';

/// Font families bundled as assets (see pubspec.yaml).
///
/// They are bundled on purpose: the google_fonts package downloads fonts
/// from Google's servers at runtime, which would break the app's
/// local-only / no-network promise.
abstract final class AppFonts {
  /// UI text. Set this as ThemeData.fontFamily in AppTheme so every
  /// widget inherits it.
  static const String sans = 'InstrumentSans';

  /// Reading serif. Used only for names, screen titles and numerals.
  static const String serif = 'Literata';

  /// Serif style for a name, title or number. Colors must come from
  /// Theme.of(context).colorScheme — pass them in via color.
  static TextStyle serifStyle({
    required double size,
    FontWeight weight = FontWeight.w600,
    double? height,
    Color? color,
  }) {
    return TextStyle(
      fontFamily: serif,
      fontSize: size,
      fontWeight: weight,
      height: height,
      color: color,
    );
  }
}
