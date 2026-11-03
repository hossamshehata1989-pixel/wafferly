import 'package:drift/drift.dart';
import 'package:drift/native.dart';

part 'spike_database.g.dart';

@DriftDatabase(include: {'schema_probe.drift'})
class SpikeDatabase extends _$SpikeDatabase {
  SpikeDatabase()
      : super(
          NativeDatabase.memory(
            setup: (rawDatabase) {
              // SQLite does not guarantee FK enforcement by default.
              // Enable it before Drift begins using the connection.
              rawDatabase.execute('PRAGMA foreign_keys = ON');
            },
          ),
        );

  @override
  int get schemaVersion => 1;
}
