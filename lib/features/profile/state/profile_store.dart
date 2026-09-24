import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/database/app_database.dart' show Book;
import '../../../core/database/tables.dart' show BookStatus;
import '../../library/models/book_extensions.dart';
import '../../library/state/book_repository.dart';
import '../models/reading_progress.dart';
import '../models/reminder_settings.dart';
import '../models/user_profile.dart';

/// Home for everything the profile screens read and write.
///
/// Values live in ValueNotifiers, matching themeModeNotifier in main.dart
/// (no state-management package yet), and are saved on this device with
/// shared_preferences whenever they change. Nothing leaves the device.
///
/// Loading starts the first time instance is touched. To avoid a brief flash
/// of default values at startup, await ProfileStore.instance.load() in
/// main() before runApp.
///
/// progress is derived live from the books database.
class ProfileStore {
  ProfileStore._() {
    load();
    _watchBooks();
  }

  static final ProfileStore instance = ProfileStore._();

  final ValueNotifier<UserProfile> profile = ValueNotifier(
    UserProfile(
      name: UserProfile.defaultName,
      yearlyGoal: 24,
      since: DateTime.now(),
    ),
  );

  final ValueNotifier<ReminderSettings> reminders =
      ValueNotifier(ReminderSettings.defaults);

  final ValueNotifier<ReadingProgress> progress =
      ValueNotifier(ReadingProgress.empty);

  /// When the reader last exported a backup, or null if never.
  final ValueNotifier<DateTime?> lastBackup = ValueNotifier(null);

  static const _kName = 'profile.name';
  static const _kGoal = 'profile.yearlyGoal';
  static const _kSince = 'profile.since';
  static const _kPhoto = 'profile.photoPath';
  static const _kRemindersEnabled = 'reminders.enabled';
  static const _kRemindersMinutes = 'reminders.minutesSinceMidnight';
  static const _kRemindersDays = 'reminders.weekdays';
  static const _kLastBackup = 'backup.last';

  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();
  Future<void>? _loading;

  /// Keeps progress in step with the books database.
  void _watchBooks() {
    BookRepository.instance.watchAll().listen(
      (books) => progress.value = _progressFrom(books),
      onError: (Object error) =>
          debugPrint('ProfileStore: could not read books ($error)'),
    );
  }

  ReadingProgress _progressFrom(List<Book> books) {
    final year = DateTime.now().year;
    final finished = books
        .where((b) => b.status == BookStatus.finished && b.finishedAt?.year == year)
        .length;
    // Books arrive most-recently-touched first. Unknown page counts show as
    // half-read spines.
    final reading = [
      for (final b in books)
        if (b.status == BookStatus.reading) b.progressFraction ?? 0.5,
    ];
    return ReadingProgress(finished: finished, inProgress: reading);
  }

  /// Reads the saved values. Safe to call more than once.
  Future<void> load() => _loading ??= _load();

  Future<void> _load() async {
    try {
      // Profile
      final name = await _prefs.getString(_kName);
      final goal = await _prefs.getInt(_kGoal);
      final since = await _prefs.getString(_kSince);
      final photo = await _prefs.getString(_kPhoto);
      final fallback = profile.value;
      profile.value = UserProfile(
        name: (name == null || name.trim().isEmpty) ? fallback.name : name,
        yearlyGoal: (goal ?? fallback.yearlyGoal)
            .clamp(UserProfile.minGoal, UserProfile.maxGoal)
            .toInt(),
        since: DateTime.tryParse(since ?? '') ?? fallback.since,
        photoPath: photo,
      );
      // First launch: remember the start date from now on.
      if (since == null) await _saveProfile();

      // Reminders
      final enabled = await _prefs.getBool(_kRemindersEnabled);
      final minutes = await _prefs.getInt(_kRemindersMinutes);
      final days = await _prefs.getStringList(_kRemindersDays);
      final savedDays = (days ?? const <String>[])
          .map(int.tryParse)
          .whereType<int>()
          .where((d) => d >= 1 && d <= 7)
          .toSet();
      final dayMinutes = minutes == null ? null : minutes % (24 * 60);
      reminders.value = reminders.value.copyWith(
        enabled: enabled,
        time: dayMinutes == null
            ? null
            : TimeOfDay(hour: dayMinutes ~/ 60, minute: dayMinutes % 60),
        weekdays: savedDays.isEmpty ? null : savedDays,
      );

      // Backup
      final backup = await _prefs.getString(_kLastBackup);
      lastBackup.value = DateTime.tryParse(backup ?? '');
    } catch (error) {
      debugPrint('ProfileStore: could not read saved settings ($error)');
    } finally {
      // Attach only after loading, so defaults never overwrite saved data.
      profile.addListener(_saveProfile);
      reminders.addListener(_saveReminders);
      lastBackup.addListener(_saveLastBackup);
    }
  }

  Future<void> _saveProfile() => _safely(() async {
        final p = profile.value;
        await _prefs.setString(_kName, p.name);
        await _prefs.setInt(_kGoal, p.yearlyGoal);
        await _prefs.setString(_kSince, p.since.toIso8601String());
        final photo = p.photoPath;
        if (photo == null) {
          await _prefs.remove(_kPhoto);
        } else {
          await _prefs.setString(_kPhoto, photo);
        }
      });

  Future<void> _saveReminders() => _safely(() async {
        final r = reminders.value;
        await _prefs.setBool(_kRemindersEnabled, r.enabled);
        await _prefs.setInt(
          _kRemindersMinutes,
          r.time.hour * 60 + r.time.minute,
        );
        final days = r.weekdays.toList()..sort();
        await _prefs.setStringList(_kRemindersDays, [
          for (final d in days) '$d',
        ]);
      });

  Future<void> _saveLastBackup() => _safely(() async {
        final when = lastBackup.value;
        if (when == null) {
          await _prefs.remove(_kLastBackup);
        } else {
          await _prefs.setString(_kLastBackup, when.toIso8601String());
        }
      });

  Future<void> _safely(Future<void> Function() action) async {
    try {
      await action();
    } catch (error) {
      debugPrint('ProfileStore: could not save ($error)');
    }
  }
}
