import 'package:package_info_plus/package_info_plus.dart';

/// App-wide constants that more than one screen needs.
const String kAppName = 'Where Was I?';

/// The version shown in the About screen.
///
/// Reads the version pubspec.yaml actually builds with, so it can never
/// drift out of sync the way a hand-copied string could. Call
/// AppInfo.load() once in main() before runApp, the same way
/// ThemeModeStore is loaded — everywhere else just reads kAppVersion.
class AppInfo {
  AppInfo._();

  static Future<void> load() async {
    try {
      final info = await PackageInfo.fromPlatform();
      kAppVersion = info.version;
    } catch (_) {
      // Keep the fallback below if the platform call fails for any reason.
    }
  }
}

/// Set by AppInfo.load() at startup. Falls back to this literal if load()
/// was never called or the platform lookup failed, so the app never shows
/// a blank version string.
String kAppVersion = '0.1.0';

/// Public repository and issue tracker, opened from the About screen.
const String kSourceUrl = 'https://github.com/devmady/where-was-i';
const String kIssuesUrl = '$kSourceUrl/issues';
