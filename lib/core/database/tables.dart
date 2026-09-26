import 'package:drift/drift.dart';

enum BookStatus { wantToRead, reading, finished }

class Books extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get title => text()();
  TextColumn get author => text().nullable()();
  IntColumn get totalPages => integer().nullable()();
  IntColumn get currentPage => integer().withDefault(const Constant(0))();

  IntColumn get status => intEnum<BookStatus>()();

  DateTimeColumn get addedAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get startedAt => dateTime().nullable()();
  DateTimeColumn get finishedAt => dateTime().nullable()();

  TextColumn get coverPath => text().nullable()();
  IntColumn get tagColor => integer().nullable()();
}

class ProgressEntries extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get bookId => integer().references(Books, #id)();
  IntColumn get page => integer()();
  IntColumn get pagesAdded => integer()();
  DateTimeColumn get loggedAt => dateTime()();
}
