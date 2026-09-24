import 'package:drift/drift.dart';

/// Where a book is in the reader's life.
enum BookStatus { wantToRead, reading, finished }

/// One row per book on the reader's shelf.
@DataClassName('Book')
class Books extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get author => text().nullable()();

  /// Null when unknown (ebooks, audiobooks): no percentage is shown then.
  IntColumn get totalPages => integer().nullable()();
  IntColumn get currentPage => integer().withDefault(const Constant(0))();

  TextColumn get status => textEnum<BookStatus>()();

  DateTimeColumn get addedAt => dateTime()();
  DateTimeColumn get startedAt => dateTime().nullable()();

  /// Drives 12 of 24 books in 2026.
  DateTimeColumn get finishedAt => dateTime().nullable()();

  /// Photo picked from this device. Null shows a tag-colored placeholder.
  TextColumn get coverPath => text().nullable()();

  /// Index 0-3 into the reserved tag colors (burgundy, dusty blue, teal,
  /// terracotta). Null = untagged.
  IntColumn get tagColor => integer().nullable()();

  /// Last time the reader touched this book. Home shows the most recent one.
  DateTimeColumn get updatedAt => dateTime()();
}

/// One row per page update, so stats (pages this week) are real and a wrong
/// update can be undone.
@DataClassName('ProgressEntry')
class ProgressEntries extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get bookId =>
      integer().references(Books, #id, onDelete: KeyAction.cascade)();

  /// The page the reader was on after this update.
  IntColumn get page => integer()();

  /// Change since the previous update (negative if the reader corrected
  /// backwards).
  IntColumn get pagesAdded => integer()();

  DateTimeColumn get loggedAt => dateTime()();
}
