import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';

part 'migration_database.g.dart';

@DriftDatabase(include: {'migration_probe.drift'})
class MigrationDatabase extends _$MigrationDatabase {
  MigrationDatabase(
    String path, {
    this.failAfterMigrationDdl = false,
  }) : super(
          NativeDatabase(
            File(path),
            setup: (rawDatabase) {
              rawDatabase.execute('PRAGMA foreign_keys = ON');
            },
          ),
        );

  final bool failAfterMigrationDdl;

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (migrator, from, to) async {
          if (from < 2 && to >= 2) {
            // Drift does not wrap migration callbacks in a transaction by
            // default. Keep this schema step atomic so a failure cannot leave
            // a partially upgraded V1 database behind.
            await transaction(() async {
              // The V1 table has id + amount_minor. V2 adds note, an index,
              // and a trigger. These are intentionally explicit SQL DDL so
              // the probe verifies objects beyond Drift's generated tables.
              await customStatement(
                'ALTER TABLE migration_records ADD COLUMN note TEXT',
              );

              await customStatement(
                'CREATE INDEX idx_migration_records_amount '
                'ON migration_records(amount_minor)',
              );

              await customStatement('''
                CREATE TRIGGER migration_records_integer_update
                BEFORE UPDATE OF amount_minor ON migration_records
                WHEN typeof(NEW.amount_minor) <> 'integer'
                BEGIN
                  SELECT RAISE(ABORT, 'amount_minor must be an integer');
                END
              ''');

              if (failAfterMigrationDdl) {
                throw StateError('intentional migration failure after DDL');
              }
            });
          }
        },
        beforeOpen: (details) async {
          final rows = await customSelect('PRAGMA foreign_keys').get();
          if (rows.single.read<int>('foreign_keys') != 1) {
            throw StateError('Foreign keys are not enabled after opening');
          }
        },
      );
}
