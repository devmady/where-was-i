import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';

import '../../core/database/app_database.dart' show Book;
import '../../core/database/tables.dart' show BookStatus;
import '../../features/library/state/book_repository.dart';

/// Keeps the home screen widget in step with the library and the theme.
///
/// Each time the books change, the list of books being read is written to the
/// storage the widget reads from, and the widget is asked to redraw. The list
/// keeps the order of watchAll, most recently touched first. The theme mode
/// chosen in the app, system, light or dark, is written the same way, so the
/// widget can match the app instead of only the phone. A separate widget theme
/// can override it, so the widget can be fixed to light or dark whatever the
/// app is set to. Which book the widget is showing is remembered by the widget
/// itself, so its arrows keep working when the app is closed.
///
/// The widget can also change the page of a book while the app is closed. The
/// widget shows the new page at once and queues the change. The queue is
/// written into the library when the app starts and each time it comes back to
/// the front, with the time the page was set. Nothing leaves the device.
class WidgetSync {
  WidgetSync._();

  static const String _androidProvider = 'WhereWasIWidgetProvider';
  static const String _booksKey = 'books_json';
  static const String _themeKey = 'widget_theme_mode';
  static const String _pendingKey = 'pending_progress_json';

  static bool _started = false;
  static bool _applying = false;

  /// Starts listening. Safe to call more than once. Does nothing on platforms
  /// that do not have the widget yet.
  static void start({
    required ValueListenable<ThemeMode> themeMode,
    required ValueListenable<ThemeMode> widgetThemeMode,
  }) {
    if (_started) return;
    if (defaultTargetPlatform != TargetPlatform.android) return;
    _started = true;

    // Pages set from the widget are written into the library first, then the
    // widget follows the library.
    unawaited(_applyPendingProgress().then((_) => _listenToBooks()));
    // The listener registers itself and lives as long as the app does.
    AppLifecycleListener(
      onResume: () => unawaited(_applyPendingProgress()),
    );

    // The widget theme wins unless it is set to system, which means follow the
    // app theme.
    void pushTheme() {
      final widgetMode = widgetThemeMode.value;
      final mode = widgetMode == ThemeMode.system ? themeMode.value : widgetMode;
      unawaited(_pushTheme(mode));
    }

    pushTheme();
    themeMode.addListener(pushTheme);
    widgetThemeMode.addListener(pushTheme);
  }

  static void _listenToBooks() {
    BookRepository.instance.watchAll().listen(
      _push,
      onError: (Object error) =>
          debugPrint('WidgetSync: could not read books ($error)'),
    );
  }

  /// Writes the pages queued by the widget into the library, in the order they
  /// were set. A change the widget queues while this runs is kept for the next
  /// time. The library changing makes the widget redraw from the library.
  static Future<void> _applyPendingProgress() async {
    if (_applying) return;
    _applying = true;
    try {
      final queued = _decodeQueue(
        await HomeWidget.getWidgetData<String>(_pendingKey),
      );
      if (queued.isEmpty) return;

      for (final change in queued) {
        final id = change['id'];
        final page = change['page'];
        final at = change['at'];
        if (id is! int || page is! int) continue;
        try {
          await BookRepository.instance.updatePage(
            id,
            page,
            at: at is int ? DateTime.fromMillisecondsSinceEpoch(at) : null,
          );
        } catch (error) {
          debugPrint('WidgetSync: could not save a page from the widget ($error)');
        }
      }

      final latest = _decodeQueue(
        await HomeWidget.getWidgetData<String>(_pendingKey),
      );
      final rest = latest.length > queued.length
          ? latest.sublist(queued.length)
          : <Map<String, dynamic>>[];
      await HomeWidget.saveWidgetData<String>(_pendingKey, jsonEncode(rest));
    } catch (error) {
      debugPrint('WidgetSync: could not read the pages from the widget ($error)');
    } finally {
      _applying = false;
    }
  }

  static List<Map<String, dynamic>> _decodeQueue(String? raw) {
    if (raw == null || raw.isEmpty) return <Map<String, dynamic>>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <Map<String, dynamic>>[];
      return [
        for (final item in decoded)
          if (item is Map<String, dynamic>) item,
      ];
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }

  static Future<void> _push(List<Book> books) async {
    try {
      final reading = books
          .where((book) => book.status == BookStatus.reading)
          .toList();

      final payload = [
        for (final book in reading)
          {
            'id': book.id,
            'title': book.title,
            'author': book.author ?? '',
            'page': book.currentPage,
            'total': book.totalPages ?? 0,
            'cover': book.coverPath ?? '',
          },
      ];

      await HomeWidget.saveWidgetData<String>(_booksKey, jsonEncode(payload));
      await HomeWidget.updateWidget(androidName: _androidProvider);
    } catch (error) {
      debugPrint('WidgetSync: could not update the widget ($error)');
    }
  }

  static Future<void> _pushTheme(ThemeMode mode) async {
    try {
      await HomeWidget.saveWidgetData<String>(_themeKey, mode.name);
      await HomeWidget.updateWidget(androidName: _androidProvider);
    } catch (error) {
      debugPrint('WidgetSync: could not send the theme to the widget ($error)');
    }
  }
}
