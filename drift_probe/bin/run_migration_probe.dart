import 'dart:io';

import 'package:sqlite3/sqlite3.dart' show SqliteException, sqlite3;
import 'package:wafferly_drift_codegen_probe/migration_database.dart';

Future<void> expectSqliteFailure(
  Future<void> Function() action,
  String label,
) async {
  try {
    await action();
  } on SqliteException {
    stdout.writeln('PASS negative: $label');
    return;
  }
  throw StateError('Expected SQLite constraint failure: $label');
}

void createV1Fixture(String path) {
  final raw = sqlite3.open(path);
  try {
    raw.execute('PRAGMA foreign_keys = ON');
    raw.execute('''
      CREATE TABLE migration_records (
        id TEXT NOT NULL PRIMARY KEY,
        amount_minor INTEGER NOT NULL CHECK (
          typeof(amount_minor) = 'integer'
          AND amount_minor BETWEEN 0 AND 9000000000000000
        )
      )
    ''');
    raw.execute(
      "INSERT INTO migration_records (id, amount_minor) VALUES ('existing-1', 1250)",
    );
    raw.execute('PRAGMA user_version = 1');
  } finally {
    raw.close();
  }
}

int readUserVersion(String path) {
  final raw = sqlite3.open(path);
  try {
    return raw.select('PRAGMA user_version').first['user_version'] as int;
  } finally {
    raw.close();
  }
}

Set<String> readObjectNames(String path, String type) {
  final raw = sqlite3.open(path);
  try {
    return raw
        .select(
          "SELECT name FROM sqlite_master WHERE type = ?",
          [type],
        )
        .map((row) => row['name'] as String)
        .toSet();
  } finally {
    raw.close();
  }
}

Set<String> readColumnNames(String path) {
  final raw = sqlite3.open(path);
  try {
    return raw
        .select('PRAGMA table_info(migration_records)')
        .map((row) => row['name'] as String)
        .toSet();
  } finally {
    raw.close();
  }
}

Future<void> main() async {
  final temp = await Directory.systemTemp.createTemp('wafferly_drift_migration_');
  final successPath = '${temp.path}${Platform.pathSeparator}success.sqlite';
  final failurePath = '${temp.path}${Platform.pathSeparator}failure.sqlite';

  try {
    createV1Fixture(successPath);
    if (readUserVersion(successPath) != 1) {
      throw StateError('V1 fixture did not retain user_version=1');
    }
    stdout.writeln('PASS: V1 fixture created with user_version=1');

    final db = MigrationDatabase(successPath);
    try {
      await db.customSelect('SELECT 1').get();
      final version = await db.customSelect('PRAGMA user_version').getSingle();
      if (version.read<int>('user_version') != 2) {
        throw StateError('Drift did not advance user_version to 2');
      }
      stdout.writeln('PASS: Drift upgraded V1 -> V2');

      final existing = await db
          .customSelect(
            "SELECT id, amount_minor, note FROM migration_records WHERE id = 'existing-1'",
          )
          .getSingle();
      if (existing.read<String>('id') != 'existing-1' ||
          existing.read<int>('amount_minor') != 1250 ||
          existing.read<String?>('note') != null) {
        throw StateError('Existing V1 row was not preserved correctly');
      }
      stdout.writeln('PASS: pre-existing row preserved');

      final columns = readColumnNames(successPath);
      if (!columns.containsAll({'id', 'amount_minor', 'note'})) {
        throw StateError('V2 note column is missing');
      }
      final indexes = readObjectNames(successPath, 'index');
      final triggers = readObjectNames(successPath, 'trigger');
      if (!indexes.contains('idx_migration_records_amount')) {
        throw StateError('V2 index is missing');
      }
      if (!triggers.contains('migration_records_integer_update')) {
        throw StateError('V2 trigger is missing');
      }
      stdout.writeln('PASS: V2 column, index and trigger exist');

      await expectSqliteFailure(
        () => db.customStatement(
          "UPDATE migration_records SET amount_minor = 1.25 WHERE id = 'existing-1'",
        ),
        'migrated trigger rejects fractional Minor Units',
      );
    } finally {
      await db.close();
    }

    createV1Fixture(failurePath);
    final failingDb = MigrationDatabase(
      failurePath,
      failAfterMigrationDdl: true,
    );
    var migrationFailed = false;
    try {
      await failingDb.customSelect('SELECT 1').get();
    } on StateError catch (error) {
      if (!error.toString().contains('intentional migration failure')) rethrow;
      migrationFailed = true;
    } finally {
      await failingDb.close();
    }

    if (!migrationFailed) {
      throw StateError('The deliberately failing migration unexpectedly succeeded');
    }
    if (readUserVersion(failurePath) != 1) {
      throw StateError('Failed migration advanced user_version; rollback failed');
    }
    if (readColumnNames(failurePath).contains('note')) {
      throw StateError('Failed migration left the V2 note column behind');
    }
    if (readObjectNames(failurePath, 'index').contains('idx_migration_records_amount') ||
        readObjectNames(failurePath, 'trigger').contains('migration_records_integer_update')) {
      throw StateError('Failed migration left V2 schema objects behind');
    }
    stdout.writeln(
      'PASS: failed migration rolls back DDL and keeps user_version=1',
    );
  } finally {
    await temp.delete(recursive: true);
  }
}
