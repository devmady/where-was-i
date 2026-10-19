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
/// widget can match the app instead of only the phone. Which book the widget
/// is showing is remembered by the widget itself, so its arrows keep working
/// when the app is closed. Nothing leaves the device.
class WidgetSync {
  WidgetSync._();

  static const String _androidProvider = 'WhereWasIWidgetProvider';
  static const String _booksKey = 'books_json';
  static const String _themeKey = 'widget_theme_mode';

  static StreamSubscription<List<Book>>? _subscription;

  /// Starts listening. Safe to call more than once. Does nothing on platforms
  /// that do not have the widget yet.
  static void start({required ValueListenable<ThemeMode> themeMode}) {
    if (_subscription != null) return;
    if (defaultTargetPlatform != TargetPlatform.android) return;

    _subscription = BookRepository.instance.watchAll().listen(
      _push,
      onError: (Object error) =>
          debugPrint('WidgetSync: could not read books ($error)'),
    );

    unawaited(_pushTheme(themeMode.value));
    themeMode.addListener(() => unawaited(_pushTheme(themeMode.value)));
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
