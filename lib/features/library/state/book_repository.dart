import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/tables.dart';
import '../models/week_stats.dart';

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
}
