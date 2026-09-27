import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/tables.dart';
import '../models/week_stats.dart';

/// Current shape of the backup JSON. Bump this if the exported fields ever
/// change in a way that breaks reading an older backup.
const int kBackupSchemaVersion = 1;

/// A quick look at what's inside a backup file, without touching the
/// database. Used to show the reader what they're about to restore before
/// they confirm.
class BackupPreview {
  const BackupPreview({required this.bookCount, required this.exportedAt});

  final int bookCount;

  /// Null if the file is old enough not to have this field, or it could
  /// not be parsed.
  final DateTime? exportedAt;
}

/// Thrown when a file handed to importBackupJson is not a backup this app
/// can read.
class BackupFormatException implements Exception {
  BackupFormatException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Everything the UI does with books. Screens call this instead of touching
/// the database directly, so rules (like logging progress) live in one place.
class BookRepository {
  BookRepository(this._db);

  /// App-wide instance (no dependency-injection package yet).
  static final BookRepository instance = BookRepository(AppDatabase());

  final AppDatabase _db;

  /// Every book, most recently touched first. Emits again on any change.
  Stream<List<Book>> watchAll() {
    final query = _db.select(_db.books)
      ..orderBy([(b) => OrderingTerm.desc(b.updatedAt)]);
    return query.watch();
  }

  Stream<Book?> watchById(int id) {
    final query = _db.select(_db.books)..where((b) => b.id.equals(id));
    return query.watchSingleOrNull();
  }

  /// Adds a book by hand (no online lookups, by design). Returns its id.
  ///
  /// finishedAt lets a reader backfill books they finished earlier; it
  /// defaults to now when status is finished.
  Future<int> addBook({
    required String title,
    String? author,
    int? totalPages,
    int currentPage = 0,
    BookStatus status = BookStatus.reading,
    DateTime? finishedAt,
    String? coverPath,
    int? tagColor,
  }) {
    final now = DateTime.now();
    final cleanAuthor = author?.trim();
    final finished = status == BookStatus.finished;

    return _db.into(_db.books).insert(
          BooksCompanion.insert(
            title: title.trim(),
            status: status,
            addedAt: now,
            updatedAt: now,
            author: Value(
              cleanAuthor == null || cleanAuthor.isEmpty ? null : cleanAuthor,
            ),
            totalPages: Value(totalPages),
            currentPage: Value(finished ? (totalPages ?? currentPage) : currentPage),
            startedAt: Value(status == BookStatus.reading ? now : null),
            finishedAt: Value(finished ? (finishedAt ?? now) : null),
            coverPath: Value(coverPath),
            tagColor: Value(tagColor),
          ),
        );
  }

  /// Records I'm on page page now: logs a progress entry and moves the
  /// book forward. A book that was only wanted becomes reading.
  ///
  /// Reaching the last page does not finish the book by itself; the UI can
  /// offer that (see markFinished).
  Future<void> updatePage(int bookId, int page) {
    return _db.transaction(() async {
      final book = await (_db.select(_db.books)
            ..where((b) => b.id.equals(bookId)))
          .getSingleOrNull();
      if (book == null) return;

      var next = page < 0 ? 0 : page;
      final total = book.totalPages;
      if (total != null && next > total) next = total;
      if (next == book.currentPage) return;

      final now = DateTime.now();
      final startsNow = book.status == BookStatus.wantToRead;

      await _db.into(_db.progressEntries).insert(
            ProgressEntriesCompanion.insert(
              bookId: bookId,
              page: next,
              pagesAdded: next - book.currentPage,
              loggedAt: now,
            ),
          );
      await (_db.update(_db.books)..where((b) => b.id.equals(bookId))).write(
        BooksCompanion(
          currentPage: Value(next),
          updatedAt: Value(now),
          status: Value(startsNow ? BookStatus.reading : book.status),
          startedAt: Value(book.startedAt ?? (startsNow ? now : null)),
        ),
      );
    });
  }

  /// I finished this book: jumps to the last page when the total is known
  /// (logging those pages), and stamps the finish date.
  Future<void> markFinished(int bookId) {
    return _db.transaction(() async {
      final book = await (_db.select(_db.books)
            ..where((b) => b.id.equals(bookId)))
          .getSingleOrNull();
      if (book == null) return;

      final now = DateTime.now();
      final total = book.totalPages;
      final lastPage = total ?? book.currentPage;

      if (lastPage != book.currentPage) {
        await _db.into(_db.progressEntries).insert(
              ProgressEntriesCompanion.insert(
                bookId: bookId,
                page: lastPage,
                pagesAdded: lastPage - book.currentPage,
                loggedAt: now,
              ),
            );
      }
      await (_db.update(_db.books)..where((b) => b.id.equals(bookId))).write(
        BooksCompanion(
          status: const Value(BookStatus.finished),
          currentPage: Value(lastPage),
          startedAt: Value(book.startedAt ?? now),
          finishedAt: Value(now),
          updatedAt: Value(now),
        ),
      );
    });
  }

  /// Pages read and days read for the current week, Monday to Sunday. Only
  /// forward progress counts, so a correction backwards never adds a day.
  Stream<WeekStats> watchThisWeek() {
    final now = DateTime.now();
    final start = DateTime(
      now.year,
      now.month,
      now.day - (now.weekday - DateTime.monday),
    );
    final query = _db.select(_db.progressEntries)
      ..where((e) => e.loggedAt.isBiggerOrEqualValue(start));
    return query.watch().map((entries) {
      var pages = 0;
      final days = <int>{};
      for (final entry in entries) {
        if (entry.pagesAdded > 0) {
          pages += entry.pagesAdded;
          days.add(entry.loggedAt.weekday);
        }
      }
      return WeekStats(pages: pages, days: days);
    });
  }

  /// Recent page updates for one book, newest first.
  Stream<List<ProgressEntry>> watchEntries(int bookId, {int limit = 10}) {
    final query = _db.select(_db.progressEntries)
      ..where((e) => e.bookId.equals(bookId))
      ..orderBy([(e) => OrderingTerm.desc(e.loggedAt)])
      ..limit(limit);
    return query.watch();
  }

  /// Edits the details of a book without touching its reading progress.
  Future<void> updateDetails(
    int bookId, {
    required String title,
    String? author,
    int? totalPages,
    int? tagColor,
    String? coverPath,
  }) {
    final cleanAuthor = author?.trim();
    return (_db.update(_db.books)..where((b) => b.id.equals(bookId))).write(
      BooksCompanion(
        title: Value(title.trim()),
        author: Value(
          cleanAuthor == null || cleanAuthor.isEmpty ? null : cleanAuthor,
        ),
        totalPages: Value(totalPages),
        tagColor: Value(tagColor),
        coverPath: Value(coverPath),
      ),
    );
  }

  /// Deletes a book and its progress entries.
  Future<void> deleteBook(int bookId) {
    return _db.transaction(() async {
      await (_db.delete(_db.progressEntries)
            ..where((e) => e.bookId.equals(bookId)))
          .go();
      await (_db.delete(_db.books)..where((b) => b.id.equals(bookId))).go();
    });
  }

  /// Deletes every book and all progress. Used by Erase all data.
  Future<void> eraseAll() {
    return _db.transaction(() async {
      await _db.delete(_db.progressEntries).go();
      await _db.delete(_db.books).go();
    });
  }

  /// Serializes every book and every progress entry to a single JSON
  /// string. Cover images are not included; a restored book keeps whatever
  /// coverPath it had, which will not resolve to a real file on a
  /// different device or after a reinstall. The UI is expected to say so.
  Future<String> exportBackupJson() async {
    final books = await _db.select(_db.books).get();
    final entries = await _db.select(_db.progressEntries).get();

    final map = {
      'app': 'where-was-i',
      'schemaVersion': kBackupSchemaVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'books': [for (final b in books) _bookToJson(b)],
      'progressEntries': [for (final e in entries) _entryToJson(e)],
    };

    return const JsonEncoder.withIndent('  ').convert(map);
  }

  /// Reads a backup file's metadata (how many books, when it was made)
  /// without changing anything in the database. Meant to be shown to the
  /// reader before importBackupJson actually runs, so a restore is never
  /// a total surprise.
  ///
  /// Throws BackupFormatException on the same conditions importBackupJson
  /// would reject the file for.
  Future<BackupPreview> peekBackupJson(String jsonString) async {
    final Object? decoded;
    try {
      decoded = jsonDecode(jsonString);
    } catch (_) {
      throw BackupFormatException('That file is not valid JSON.');
    }

    if (decoded is! Map<String, dynamic>) {
      throw BackupFormatException('That file is not a Where Was I? backup.');
    }
    if (decoded['app'] != 'where-was-i') {
      throw BackupFormatException('That file is not a Where Was I? backup.');
    }

    final booksJson = decoded['books'];
    if (booksJson is! List) {
      throw BackupFormatException('That backup file looks incomplete.');
    }

    final exportedAtRaw = decoded['exportedAt'];
    final exportedAt =
        exportedAtRaw is String ? DateTime.tryParse(exportedAtRaw) : null;

    return BackupPreview(bookCount: booksJson.length, exportedAt: exportedAt);
  }

  /// Reads a backup produced by exportBackupJson and replaces everything
  /// currently in the database with it. Existing books and progress are
  /// deleted first — this does not merge with what is already here.
  ///
  /// Throws BackupFormatException if the file is not a backup this app can
  /// read, before anything existing is touched.
  Future<void> importBackupJson(String jsonString) async {
    final Object? decoded;
    try {
      decoded = jsonDecode(jsonString);
    } catch (_) {
      throw BackupFormatException('That file is not valid JSON.');
    }

    if (decoded is! Map<String, dynamic>) {
      throw BackupFormatException('That file is not a Where Was I? backup.');
    }
    if (decoded['app'] != 'where-was-i') {
      throw BackupFormatException('That file is not a Where Was I? backup.');
    }

    final booksJson = decoded['books'];
    final entriesJson = decoded['progressEntries'];
    if (booksJson is! List || entriesJson is! List) {
      throw BackupFormatException('That backup file looks incomplete.');
    }

    final List<BooksCompanion> bookRows;
    final List<ProgressEntriesCompanion> entryRows;
    try {
      bookRows = [for (final b in booksJson) _bookFromJson(b as Map<String, dynamic>)];
      entryRows = [
        for (final e in entriesJson) _entryFromJson(e as Map<String, dynamic>),
      ];
    } catch (_) {
      throw BackupFormatException('That backup file looks incomplete.');
    }

    await _db.transaction(() async {
      await _db.delete(_db.progressEntries).go();
      await _db.delete(_db.books).go();

      // Insert with the original ids preserved, so progressEntries.bookId
      // still points at the right book after restore.
      for (final row in bookRows) {
        await _db.into(_db.books).insert(row, mode: InsertMode.insertOrReplace);
      }
      for (final row in entryRows) {
        await _db
            .into(_db.progressEntries)
            .insert(row, mode: InsertMode.insertOrReplace);
      }
    });
  }

  Map<String, dynamic> _bookToJson(Book b) => {
        'id': b.id,
        'title': b.title,
        'author': b.author,
        'totalPages': b.totalPages,
        'currentPage': b.currentPage,
        'status': b.status.name,
        'addedAt': b.addedAt.toIso8601String(),
        'updatedAt': b.updatedAt.toIso8601String(),
        'startedAt': b.startedAt?.toIso8601String(),
        'finishedAt': b.finishedAt?.toIso8601String(),
        'coverPath': b.coverPath,
        'tagColor': b.tagColor,
      };

  BooksCompanion _bookFromJson(Map<String, dynamic> j) => BooksCompanion.insert(
        id: Value(j['id'] as int),
        title: j['title'] as String,
        author: Value(j['author'] as String?),
        totalPages: Value(j['totalPages'] as int?),
        currentPage: Value(j['currentPage'] as int? ?? 0),
        status: BookStatus.values.byName(j['status'] as String),
        addedAt: DateTime.parse(j['addedAt'] as String),
        updatedAt: DateTime.parse(j['updatedAt'] as String),
        startedAt: Value(
          j['startedAt'] == null ? null : DateTime.parse(j['startedAt'] as String),
        ),
        finishedAt: Value(
          j['finishedAt'] == null ? null : DateTime.parse(j['finishedAt'] as String),
        ),
        coverPath: Value(j['coverPath'] as String?),
        tagColor: Value(j['tagColor'] as int?),
      );

  Map<String, dynamic> _entryToJson(ProgressEntry e) => {
        'id': e.id,
        'bookId': e.bookId,
        'page': e.page,
        'pagesAdded': e.pagesAdded,
        'loggedAt': e.loggedAt.toIso8601String(),
      };

  ProgressEntriesCompanion _entryFromJson(Map<String, dynamic> j) =>
      ProgressEntriesCompanion.insert(
        id: Value(j['id'] as int),
        bookId: j['bookId'] as int,
        page: j['page'] as int,
        pagesAdded: j['pagesAdded'] as int,
        loggedAt: DateTime.parse(j['loggedAt'] as String),
      );
}
