import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../../core/database/app_database.dart' show Book;
import '../../core/database/tables.dart' show BookStatus;
import '../../features/library/state/book_repository.dart';

/// Keeps the home screen widget in step with the library.
///
/// Each time the books change, the list of books being read is written to the
/// storage the widget reads from, and the widget is asked to redraw. The list
/// keeps the order of watchAll, most recently touched first. Which book the
/// widget is showing is remembered by the widget itself, so its arrows keep
/// working when the app is closed. Nothing leaves the device.
class WidgetSync {
  WidgetSync._();

  static const String _androidProvider = 'WhereWasIWidgetProvider';
  static const String _booksKey = 'books_json';

  static StreamSubscription<List<Book>>? _subscription;

  /// Starts listening. Safe to call more than once. Does nothing on platforms
  /// that do not have the widget yet.
  static void start() {
    if (_subscription != null) return;
    if (defaultTargetPlatform != TargetPlatform.android) return;

    _subscription = BookRepository.instance.watchAll().listen(
      _push,
      onError: (Object error) =>
          debugPrint('WidgetSync: could not read books ($error)'),
    );
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
}
