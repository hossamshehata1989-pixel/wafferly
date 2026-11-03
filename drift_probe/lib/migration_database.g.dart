// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'migration_database.dart';

// ignore_for_file: type=lint
class MigrationRecords extends Table
    with TableInfo<MigrationRecords, MigrationRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  MigrationRecords(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _amountMinorMeta = const VerificationMeta(
    'amountMinor',
  );
  late final GeneratedColumn<int> amountMinor = GeneratedColumn<int>(
    'amount_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (typeof(amount_minor) = \'integer\' AND amount_minor BETWEEN 0 AND 9000000000000000)',
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  @override
  List<GeneratedColumn> get $columns => [id, amountMinor, note];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'migration_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<MigrationRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('amount_minor')) {
      context.handle(
        _amountMinorMeta,
        amountMinor.isAcceptableOrUnknown(
          data['amount_minor']!,
          _amountMinorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountMinorMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MigrationRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MigrationRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      amountMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_minor'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
    );
  }

  @override
  MigrationRecords createAlias(String alias) {
    return MigrationRecords(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class MigrationRecord extends DataClass implements Insertable<MigrationRecord> {
  final String id;
  final int amountMinor;
  final String? note;
  const MigrationRecord({
    required this.id,
    required this.amountMinor,
    this.note,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['amount_minor'] = Variable<int>(amountMinor);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    return map;
  }

  MigrationRecordsCompanion toCompanion(bool nullToAbsent) {
    return MigrationRecordsCompanion(
      id: Value(id),
      amountMinor: Value(amountMinor),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
    );
  }

  factory MigrationRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MigrationRecord(
      id: serializer.fromJson<String>(json['id']),
      amountMinor: serializer.fromJson<int>(json['amount_minor']),
      note: serializer.fromJson<String?>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'amount_minor': serializer.toJson<int>(amountMinor),
      'note': serializer.toJson<String?>(note),
    };
  }

  MigrationRecord copyWith({
    String? id,
    int? amountMinor,
    Value<String?> note = const Value.absent(),
  }) => MigrationRecord(
    id: id ?? this.id,
    amountMinor: amountMinor ?? this.amountMinor,
    note: note.present ? note.value : this.note,
  );
  MigrationRecord copyWithCompanion(MigrationRecordsCompanion data) {
    return MigrationRecord(
      id: data.id.present ? data.id.value : this.id,
      amountMinor: data.amountMinor.present
          ? data.amountMinor.value
          : this.amountMinor,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MigrationRecord(')
          ..write('id: $id, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, amountMinor, note);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MigrationRecord &&
          other.id == this.id &&
          other.amountMinor == this.amountMinor &&
          other.note == this.note);
}

class MigrationRecordsCompanion extends UpdateCompanion<MigrationRecord> {
  final Value<String> id;
  final Value<int> amountMinor;
  final Value<String?> note;
  final Value<int> rowid;
  const MigrationRecordsCompanion({
    this.id = const Value.absent(),
    this.amountMinor = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MigrationRecordsCompanion.insert({
    required String id,
    required int amountMinor,
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       amountMinor = Value(amountMinor);
  static Insertable<MigrationRecord> custom({
    Expression<String>? id,
    Expression<int>? amountMinor,
    Expression<String>? note,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (amountMinor != null) 'amount_minor': amountMinor,
      if (note != null) 'note': note,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MigrationRecordsCompanion copyWith({
    Value<String>? id,
    Value<int>? amountMinor,
    Value<String?>? note,
    Value<int>? rowid,
  }) {
    return MigrationRecordsCompanion(
      id: id ?? this.id,
      amountMinor: amountMinor ?? this.amountMinor,
      note: note ?? this.note,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (amountMinor.present) {
      map['amount_minor'] = Variable<int>(amountMinor.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MigrationRecordsCompanion(')
          ..write('id: $id, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('note: $note, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$MigrationDatabase extends GeneratedDatabase {
  _$MigrationDatabase(QueryExecutor e) : super(e);
  $MigrationDatabaseManager get managers => $MigrationDatabaseManager(this);
  late final MigrationRecords migrationRecords = MigrationRecords(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [migrationRecords];
}

typedef $MigrationRecordsCreateCompanionBuilder =
    MigrationRecordsCompanion Function({
      required String id,
      required int amountMinor,
      Value<String?> note,
      Value<int> rowid,
    });
typedef $MigrationRecordsUpdateCompanionBuilder =
    MigrationRecordsCompanion Function({
      Value<String> id,
      Value<int> amountMinor,
      Value<String?> note,
      Value<int> rowid,
    });

class $MigrationRecordsFilterComposer
    extends Composer<_$MigrationDatabase, MigrationRecords> {
  $MigrationRecordsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );
}

class $MigrationRecordsOrderingComposer
    extends Composer<_$MigrationDatabase, MigrationRecords> {
  $MigrationRecordsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );
}

class $MigrationRecordsAnnotationComposer
    extends Composer<_$MigrationDatabase, MigrationRecords> {
  $MigrationRecordsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);
}

class $MigrationRecordsTableManager
    extends
        RootTableManager<
          _$MigrationDatabase,
          MigrationRecords,
          MigrationRecord,
          $MigrationRecordsFilterComposer,
          $MigrationRecordsOrderingComposer,
          $MigrationRecordsAnnotationComposer,
          $MigrationRecordsCreateCompanionBuilder,
          $MigrationRecordsUpdateCompanionBuilder,
          (
            MigrationRecord,
            BaseReferences<
              _$MigrationDatabase,
              MigrationRecords,
              MigrationRecord
            >,
          ),
          MigrationRecord,
          PrefetchHooks Function()
        > {
  $MigrationRecordsTableManager(_$MigrationDatabase db, MigrationRecords table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $MigrationRecordsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $MigrationRecordsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $MigrationRecordsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> amountMinor = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MigrationRecordsCompanion(
                id: id,
                amountMinor: amountMinor,
                note: note,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int amountMinor,
                Value<String?> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MigrationRecordsCompanion.insert(
                id: id,
                amountMinor: amountMinor,
                note: note,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<MigrationRecords, MigrationRecord>(table),
                  BaseReferences<
                    _$MigrationDatabase,
                    MigrationRecords,
                    MigrationRecord
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $MigrationRecordsProcessedTableManager =
    ProcessedTableManager<
      _$MigrationDatabase,
      MigrationRecords,
      MigrationRecord,
      $MigrationRecordsFilterComposer,
      $MigrationRecordsOrderingComposer,
      $MigrationRecordsAnnotationComposer,
      $MigrationRecordsCreateCompanionBuilder,
      $MigrationRecordsUpdateCompanionBuilder,
      (
        MigrationRecord,
        BaseReferences<_$MigrationDatabase, MigrationRecords, MigrationRecord>,
      ),
      MigrationRecord,
      PrefetchHooks Function()
    >;

class $MigrationDatabaseManager {
  final _$MigrationDatabase _db;
  $MigrationDatabaseManager(this._db);
  $MigrationRecordsTableManager get migrationRecords =>
      $MigrationRecordsTableManager(_db, _db.migrationRecords);
}
