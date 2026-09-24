import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

import 'tables.dart';

part 'app_database.g.dart';

/// The app's local SQLite database. Lives in the app's private storage on
/// this device; nothing is synced anywhere.
///
/// The .g.dart file is generated: run dart run build_runner build
/// whenever tables change (and bump schemaVersion with a migration).
@DriftDatabase(tables: [Books, ProgressEntries])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        beforeOpen: (details) async {
          // SQLite ignores foreign keys unless asked. Needed so deleting a
          // book also deletes its progress entries.
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'where_was_i',
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
    );
  }
}
