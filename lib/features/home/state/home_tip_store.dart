import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../profile/state/profile_store.dart';

/// Decides whether the press and hold Home tip is showing. It appears during
/// the first days of use and stays gone once the reader dismisses it. The
/// choice is saved on this device only.
class HomeTipStore {
  HomeTipStore._() {
    _load();
  }

  static final HomeTipStore instance = HomeTipStore._();

  static const int _daysToShow = 7;
  static const String _dismissedKey = 'tips.homeShortcutDismissed';

  /// False until the saved choice has been read, so the tip never flashes.
  final ValueNotifier<bool> visible = ValueNotifier(false);

  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  Future<void> _load() async {
    try {
      final dismissed = await _prefs.getBool(_dismissedKey) ?? false;
      await ProfileStore.instance.load();
      final since = ProfileStore.instance.profile.value.since;
      final days = DateTime.now().difference(since).inDays;
      visible.value = !dismissed && days < _daysToShow;
    } catch (error) {
      debugPrint('HomeTipStore: could not read the tip setting ($error)');
    }
  }

  Future<void> dismiss() async {
    visible.value = false;
    try {
      await _prefs.setBool(_dismissedKey, true);
    } catch (error) {
      debugPrint('HomeTipStore: could not save the tip setting ($error)');
    }
  }
}
