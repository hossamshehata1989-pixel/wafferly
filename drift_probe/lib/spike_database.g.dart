// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'spike_database.dart';

// ignore_for_file: type=lint
class Books extends Table with TableInfo<Books, Book> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Books(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (length(trim(name)) > 0)',
  );
  static const VerificationMeta _isDefaultMeta = const VerificationMeta(
    'isDefault',
  );
  late final GeneratedColumn<int> isDefault = GeneratedColumn<int>(
    'is_default',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (typeof(is_default) = \'integer\' AND is_default IN (0, 1))',
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, isDefault];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'books';
  @override
  VerificationContext validateIntegrity(
    Insertable<Book> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('is_default')) {
      context.handle(
        _isDefaultMeta,
        isDefault.isAcceptableOrUnknown(data['is_default']!, _isDefaultMeta),
      );
    } else if (isInserting) {
      context.missing(_isDefaultMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Book map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Book(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      isDefault: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}is_default'],
      )!,
    );
  }

  @override
  Books createAlias(String alias) {
    return Books(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class Book extends DataClass implements Insertable<Book> {
  final String id;
  final String name;
  final int isDefault;
  const Book({required this.id, required this.name, required this.isDefault});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['is_default'] = Variable<int>(isDefault);
    return map;
  }

  BooksCompanion toCompanion(bool nullToAbsent) {
    return BooksCompanion(
      id: Value(id),
      name: Value(name),
      isDefault: Value(isDefault),
    );
  }

  factory Book.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Book(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      isDefault: serializer.fromJson<int>(json['is_default']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'is_default': serializer.toJson<int>(isDefault),
    };
  }

  Book copyWith({String? id, String? name, int? isDefault}) => Book(
    id: id ?? this.id,
    name: name ?? this.name,
    isDefault: isDefault ?? this.isDefault,
  );
  Book copyWithCompanion(BooksCompanion data) {
    return Book(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      isDefault: data.isDefault.present ? data.isDefault.value : this.isDefault,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Book(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('isDefault: $isDefault')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, isDefault);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Book &&
          other.id == this.id &&
          other.name == this.name &&
          other.isDefault == this.isDefault);
}

class BooksCompanion extends UpdateCompanion<Book> {
  final Value<String> id;
  final Value<String> name;
  final Value<int> isDefault;
  final Value<int> rowid;
  const BooksCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BooksCompanion.insert({
    required String id,
    required String name,
    required int isDefault,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       isDefault = Value(isDefault);
  static Insertable<Book> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? isDefault,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (isDefault != null) 'is_default': isDefault,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BooksCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<int>? isDefault,
    Value<int>? rowid,
  }) {
    return BooksCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      isDefault: isDefault ?? this.isDefault,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (isDefault.present) {
      map['is_default'] = Variable<int>(isDefault.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BooksCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('isDefault: $isDefault, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class LedgerAccounts extends Table
    with TableInfo<LedgerAccounts, LedgerAccount> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  LedgerAccounts(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _accountTypeMeta = const VerificationMeta(
    'accountType',
  );
  late final GeneratedColumn<String> accountType = GeneratedColumn<String>(
    'account_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (account_type IN (\'asset\', \'liability\', \'expense\', \'income\', \'equity\', \'system\'))',
  );
  static const VerificationMeta _linkedAccountNatureMeta =
      const VerificationMeta('linkedAccountNature');
  late final GeneratedColumn<String> linkedAccountNature =
      GeneratedColumn<String>(
        'linked_account_nature',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        $customConstraints:
            'CHECK (linked_account_nature IN (\'asset\', \'liability\'))',
      );
  @override
  List<GeneratedColumn> get $columns => [id, accountType, linkedAccountNature];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ledger_accounts';
  @override
  VerificationContext validateIntegrity(
    Insertable<LedgerAccount> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('account_type')) {
      context.handle(
        _accountTypeMeta,
        accountType.isAcceptableOrUnknown(
          data['account_type']!,
          _accountTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_accountTypeMeta);
    }
    if (data.containsKey('linked_account_nature')) {
      context.handle(
        _linkedAccountNatureMeta,
        linkedAccountNature.isAcceptableOrUnknown(
          data['linked_account_nature']!,
          _linkedAccountNatureMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {id, linkedAccountNature},
  ];
  @override
  LedgerAccount map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LedgerAccount(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      accountType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_type'],
      )!,
      linkedAccountNature: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}linked_account_nature'],
      ),
    );
  }

  @override
  LedgerAccounts createAlias(String alias) {
    return LedgerAccounts(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'UNIQUE(id, linked_account_nature)',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class LedgerAccount extends DataClass implements Insertable<LedgerAccount> {
  final String id;
  final String accountType;
  final String? linkedAccountNature;
  const LedgerAccount({
    required this.id,
    required this.accountType,
    this.linkedAccountNature,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['account_type'] = Variable<String>(accountType);
    if (!nullToAbsent || linkedAccountNature != null) {
      map['linked_account_nature'] = Variable<String>(linkedAccountNature);
    }
    return map;
  }

  LedgerAccountsCompanion toCompanion(bool nullToAbsent) {
    return LedgerAccountsCompanion(
      id: Value(id),
      accountType: Value(accountType),
      linkedAccountNature: linkedAccountNature == null && nullToAbsent
          ? const Value.absent()
          : Value(linkedAccountNature),
    );
  }

  factory LedgerAccount.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LedgerAccount(
      id: serializer.fromJson<String>(json['id']),
      accountType: serializer.fromJson<String>(json['account_type']),
      linkedAccountNature: serializer.fromJson<String?>(
        json['linked_account_nature'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'account_type': serializer.toJson<String>(accountType),
      'linked_account_nature': serializer.toJson<String?>(linkedAccountNature),
    };
  }

  LedgerAccount copyWith({
    String? id,
    String? accountType,
    Value<String?> linkedAccountNature = const Value.absent(),
  }) => LedgerAccount(
    id: id ?? this.id,
    accountType: accountType ?? this.accountType,
    linkedAccountNature: linkedAccountNature.present
        ? linkedAccountNature.value
        : this.linkedAccountNature,
  );
  LedgerAccount copyWithCompanion(LedgerAccountsCompanion data) {
    return LedgerAccount(
      id: data.id.present ? data.id.value : this.id,
      accountType: data.accountType.present
          ? data.accountType.value
          : this.accountType,
      linkedAccountNature: data.linkedAccountNature.present
          ? data.linkedAccountNature.value
          : this.linkedAccountNature,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LedgerAccount(')
          ..write('id: $id, ')
          ..write('accountType: $accountType, ')
          ..write('linkedAccountNature: $linkedAccountNature')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, accountType, linkedAccountNature);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LedgerAccount &&
          other.id == this.id &&
          other.accountType == this.accountType &&
          other.linkedAccountNature == this.linkedAccountNature);
}

class LedgerAccountsCompanion extends UpdateCompanion<LedgerAccount> {
  final Value<String> id;
  final Value<String> accountType;
  final Value<String?> linkedAccountNature;
  final Value<int> rowid;
  const LedgerAccountsCompanion({
    this.id = const Value.absent(),
    this.accountType = const Value.absent(),
    this.linkedAccountNature = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LedgerAccountsCompanion.insert({
    required String id,
    required String accountType,
    this.linkedAccountNature = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       accountType = Value(accountType);
  static Insertable<LedgerAccount> custom({
    Expression<String>? id,
    Expression<String>? accountType,
    Expression<String>? linkedAccountNature,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (accountType != null) 'account_type': accountType,
      if (linkedAccountNature != null)
        'linked_account_nature': linkedAccountNature,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LedgerAccountsCompanion copyWith({
    Value<String>? id,
    Value<String>? accountType,
    Value<String?>? linkedAccountNature,
    Value<int>? rowid,
  }) {
    return LedgerAccountsCompanion(
      id: id ?? this.id,
      accountType: accountType ?? this.accountType,
      linkedAccountNature: linkedAccountNature ?? this.linkedAccountNature,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (accountType.present) {
      map['account_type'] = Variable<String>(accountType.value);
    }
    if (linkedAccountNature.present) {
      map['linked_account_nature'] = Variable<String>(
        linkedAccountNature.value,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LedgerAccountsCompanion(')
          ..write('id: $id, ')
          ..write('accountType: $accountType, ')
          ..write('linkedAccountNature: $linkedAccountNature, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Accounts extends Table with TableInfo<Accounts, Account> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Accounts(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _bookIdMeta = const VerificationMeta('bookId');
  late final GeneratedColumn<String> bookId = GeneratedColumn<String>(
    'book_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES books(id)ON DELETE RESTRICT',
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _natureMeta = const VerificationMeta('nature');
  late final GeneratedColumn<String> nature = GeneratedColumn<String>(
    'nature',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (nature IN (\'asset\', \'liability\'))',
  );
  static const VerificationMeta _ledgerAccountIdMeta = const VerificationMeta(
    'ledgerAccountId',
  );
  late final GeneratedColumn<String> ledgerAccountId = GeneratedColumn<String>(
    'ledger_account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL UNIQUE',
  );
  @override
  List<GeneratedColumn> get $columns => [bookId, id, nature, ledgerAccountId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'accounts';
  @override
  VerificationContext validateIntegrity(
    Insertable<Account> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('book_id')) {
      context.handle(
        _bookIdMeta,
        bookId.isAcceptableOrUnknown(data['book_id']!, _bookIdMeta),
      );
    } else if (isInserting) {
      context.missing(_bookIdMeta);
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('nature')) {
      context.handle(
        _natureMeta,
        nature.isAcceptableOrUnknown(data['nature']!, _natureMeta),
      );
    } else if (isInserting) {
      context.missing(_natureMeta);
    }
    if (data.containsKey('ledger_account_id')) {
      context.handle(
        _ledgerAccountIdMeta,
        ledgerAccountId.isAcceptableOrUnknown(
          data['ledger_account_id']!,
          _ledgerAccountIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_ledgerAccountIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {bookId, id};
  @override
  Account map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Account(
      bookId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}book_id'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      nature: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nature'],
      )!,
      ledgerAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ledger_account_id'],
      )!,
    );
  }

  @override
  Accounts createAlias(String alias) {
    return Accounts(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'PRIMARY KEY(book_id, id)',
    'FOREIGN KEY(ledger_account_id, nature)REFERENCES ledger_accounts(id, linked_account_nature)ON UPDATE RESTRICT ON DELETE RESTRICT',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class Account extends DataClass implements Insertable<Account> {
  final String bookId;
  final String id;
  final String nature;
  final String ledgerAccountId;
  const Account({
    required this.bookId,
    required this.id,
    required this.nature,
    required this.ledgerAccountId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['book_id'] = Variable<String>(bookId);
    map['id'] = Variable<String>(id);
    map['nature'] = Variable<String>(nature);
    map['ledger_account_id'] = Variable<String>(ledgerAccountId);
    return map;
  }

  AccountsCompanion toCompanion(bool nullToAbsent) {
    return AccountsCompanion(
      bookId: Value(bookId),
      id: Value(id),
      nature: Value(nature),
      ledgerAccountId: Value(ledgerAccountId),
    );
  }

  factory Account.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Account(
      bookId: serializer.fromJson<String>(json['book_id']),
      id: serializer.fromJson<String>(json['id']),
      nature: serializer.fromJson<String>(json['nature']),
      ledgerAccountId: serializer.fromJson<String>(json['ledger_account_id']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'book_id': serializer.toJson<String>(bookId),
      'id': serializer.toJson<String>(id),
      'nature': serializer.toJson<String>(nature),
      'ledger_account_id': serializer.toJson<String>(ledgerAccountId),
    };
  }

  Account copyWith({
    String? bookId,
    String? id,
    String? nature,
    String? ledgerAccountId,
  }) => Account(
    bookId: bookId ?? this.bookId,
    id: id ?? this.id,
    nature: nature ?? this.nature,
    ledgerAccountId: ledgerAccountId ?? this.ledgerAccountId,
  );
  Account copyWithCompanion(AccountsCompanion data) {
    return Account(
      bookId: data.bookId.present ? data.bookId.value : this.bookId,
      id: data.id.present ? data.id.value : this.id,
      nature: data.nature.present ? data.nature.value : this.nature,
      ledgerAccountId: data.ledgerAccountId.present
          ? data.ledgerAccountId.value
          : this.ledgerAccountId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Account(')
          ..write('bookId: $bookId, ')
          ..write('id: $id, ')
          ..write('nature: $nature, ')
          ..write('ledgerAccountId: $ledgerAccountId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(bookId, id, nature, ledgerAccountId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Account &&
          other.bookId == this.bookId &&
          other.id == this.id &&
          other.nature == this.nature &&
          other.ledgerAccountId == this.ledgerAccountId);
}

class AccountsCompanion extends UpdateCompanion<Account> {
  final Value<String> bookId;
  final Value<String> id;
  final Value<String> nature;
  final Value<String> ledgerAccountId;
  final Value<int> rowid;
  const AccountsCompanion({
    this.bookId = const Value.absent(),
    this.id = const Value.absent(),
    this.nature = const Value.absent(),
    this.ledgerAccountId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AccountsCompanion.insert({
    required String bookId,
    required String id,
    required String nature,
    required String ledgerAccountId,
    this.rowid = const Value.absent(),
  }) : bookId = Value(bookId),
       id = Value(id),
       nature = Value(nature),
       ledgerAccountId = Value(ledgerAccountId);
  static Insertable<Account> custom({
    Expression<String>? bookId,
    Expression<String>? id,
    Expression<String>? nature,
    Expression<String>? ledgerAccountId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (bookId != null) 'book_id': bookId,
      if (id != null) 'id': id,
      if (nature != null) 'nature': nature,
      if (ledgerAccountId != null) 'ledger_account_id': ledgerAccountId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AccountsCompanion copyWith({
    Value<String>? bookId,
    Value<String>? id,
    Value<String>? nature,
    Value<String>? ledgerAccountId,
    Value<int>? rowid,
  }) {
    return AccountsCompanion(
      bookId: bookId ?? this.bookId,
      id: id ?? this.id,
      nature: nature ?? this.nature,
      ledgerAccountId: ledgerAccountId ?? this.ledgerAccountId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (bookId.present) {
      map['book_id'] = Variable<String>(bookId.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (nature.present) {
      map['nature'] = Variable<String>(nature.value);
    }
    if (ledgerAccountId.present) {
      map['ledger_account_id'] = Variable<String>(ledgerAccountId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AccountsCompanion(')
          ..write('bookId: $bookId, ')
          ..write('id: $id, ')
          ..write('nature: $nature, ')
          ..write('ledgerAccountId: $ledgerAccountId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Transactions extends Table with TableInfo<Transactions, Transaction> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Transactions(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _bookIdMeta = const VerificationMeta('bookId');
  late final GeneratedColumn<String> bookId = GeneratedColumn<String>(
    'book_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES books(id)',
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _sourceAccountIdMeta = const VerificationMeta(
    'sourceAccountId',
  );
  late final GeneratedColumn<String> sourceAccountId = GeneratedColumn<String>(
    'source_account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
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
  @override
  List<GeneratedColumn> get $columns => [
    bookId,
    id,
    sourceAccountId,
    amountMinor,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transactions';
  @override
  VerificationContext validateIntegrity(
    Insertable<Transaction> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('book_id')) {
      context.handle(
        _bookIdMeta,
        bookId.isAcceptableOrUnknown(data['book_id']!, _bookIdMeta),
      );
    } else if (isInserting) {
      context.missing(_bookIdMeta);
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('source_account_id')) {
      context.handle(
        _sourceAccountIdMeta,
        sourceAccountId.isAcceptableOrUnknown(
          data['source_account_id']!,
          _sourceAccountIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sourceAccountIdMeta);
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {bookId, id};
  @override
  Transaction map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Transaction(
      bookId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}book_id'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sourceAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_account_id'],
      )!,
      amountMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_minor'],
      )!,
    );
  }

  @override
  Transactions createAlias(String alias) {
    return Transactions(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'PRIMARY KEY(book_id, id)',
    'FOREIGN KEY(book_id, source_account_id)REFERENCES accounts(book_id, id)',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class Transaction extends DataClass implements Insertable<Transaction> {
  final String bookId;
  final String id;
  final String sourceAccountId;
  final int amountMinor;
  const Transaction({
    required this.bookId,
    required this.id,
    required this.sourceAccountId,
    required this.amountMinor,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['book_id'] = Variable<String>(bookId);
    map['id'] = Variable<String>(id);
    map['source_account_id'] = Variable<String>(sourceAccountId);
    map['amount_minor'] = Variable<int>(amountMinor);
    return map;
  }

  TransactionsCompanion toCompanion(bool nullToAbsent) {
    return TransactionsCompanion(
      bookId: Value(bookId),
      id: Value(id),
      sourceAccountId: Value(sourceAccountId),
      amountMinor: Value(amountMinor),
    );
  }

  factory Transaction.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Transaction(
      bookId: serializer.fromJson<String>(json['book_id']),
      id: serializer.fromJson<String>(json['id']),
      sourceAccountId: serializer.fromJson<String>(json['source_account_id']),
      amountMinor: serializer.fromJson<int>(json['amount_minor']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'book_id': serializer.toJson<String>(bookId),
      'id': serializer.toJson<String>(id),
      'source_account_id': serializer.toJson<String>(sourceAccountId),
      'amount_minor': serializer.toJson<int>(amountMinor),
    };
  }

  Transaction copyWith({
    String? bookId,
    String? id,
    String? sourceAccountId,
    int? amountMinor,
  }) => Transaction(
    bookId: bookId ?? this.bookId,
    id: id ?? this.id,
    sourceAccountId: sourceAccountId ?? this.sourceAccountId,
    amountMinor: amountMinor ?? this.amountMinor,
  );
  Transaction copyWithCompanion(TransactionsCompanion data) {
    return Transaction(
      bookId: data.bookId.present ? data.bookId.value : this.bookId,
      id: data.id.present ? data.id.value : this.id,
      sourceAccountId: data.sourceAccountId.present
          ? data.sourceAccountId.value
          : this.sourceAccountId,
      amountMinor: data.amountMinor.present
          ? data.amountMinor.value
          : this.amountMinor,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Transaction(')
          ..write('bookId: $bookId, ')
          ..write('id: $id, ')
          ..write('sourceAccountId: $sourceAccountId, ')
          ..write('amountMinor: $amountMinor')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(bookId, id, sourceAccountId, amountMinor);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Transaction &&
          other.bookId == this.bookId &&
          other.id == this.id &&
          other.sourceAccountId == this.sourceAccountId &&
          other.amountMinor == this.amountMinor);
}

class TransactionsCompanion extends UpdateCompanion<Transaction> {
  final Value<String> bookId;
  final Value<String> id;
  final Value<String> sourceAccountId;
  final Value<int> amountMinor;
  final Value<int> rowid;
  const TransactionsCompanion({
    this.bookId = const Value.absent(),
    this.id = const Value.absent(),
    this.sourceAccountId = const Value.absent(),
    this.amountMinor = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TransactionsCompanion.insert({
    required String bookId,
    required String id,
    required String sourceAccountId,
    required int amountMinor,
    this.rowid = const Value.absent(),
  }) : bookId = Value(bookId),
       id = Value(id),
       sourceAccountId = Value(sourceAccountId),
       amountMinor = Value(amountMinor);
  static Insertable<Transaction> custom({
    Expression<String>? bookId,
    Expression<String>? id,
    Expression<String>? sourceAccountId,
    Expression<int>? amountMinor,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (bookId != null) 'book_id': bookId,
      if (id != null) 'id': id,
      if (sourceAccountId != null) 'source_account_id': sourceAccountId,
      if (amountMinor != null) 'amount_minor': amountMinor,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TransactionsCompanion copyWith({
    Value<String>? bookId,
    Value<String>? id,
    Value<String>? sourceAccountId,
    Value<int>? amountMinor,
    Value<int>? rowid,
  }) {
    return TransactionsCompanion(
      bookId: bookId ?? this.bookId,
      id: id ?? this.id,
      sourceAccountId: sourceAccountId ?? this.sourceAccountId,
      amountMinor: amountMinor ?? this.amountMinor,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (bookId.present) {
      map['book_id'] = Variable<String>(bookId.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sourceAccountId.present) {
      map['source_account_id'] = Variable<String>(sourceAccountId.value);
    }
    if (amountMinor.present) {
      map['amount_minor'] = Variable<int>(amountMinor.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionsCompanion(')
          ..write('bookId: $bookId, ')
          ..write('id: $id, ')
          ..write('sourceAccountId: $sourceAccountId, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class LedgerEntries extends Table with TableInfo<LedgerEntries, LedgerEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  LedgerEntries(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _bookIdMeta = const VerificationMeta('bookId');
  late final GeneratedColumn<String> bookId = GeneratedColumn<String>(
    'book_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES books(id)',
  );
  static const VerificationMeta _ledgerAccountIdMeta = const VerificationMeta(
    'ledgerAccountId',
  );
  late final GeneratedColumn<String> ledgerAccountId = GeneratedColumn<String>(
    'ledger_account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES ledger_accounts(id)',
  );
  static const VerificationMeta _transactionIdMeta = const VerificationMeta(
    'transactionId',
  );
  late final GeneratedColumn<String> transactionId = GeneratedColumn<String>(
    'transaction_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    bookId,
    ledgerAccountId,
    transactionId,
    amountMinor,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ledger_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<LedgerEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('book_id')) {
      context.handle(
        _bookIdMeta,
        bookId.isAcceptableOrUnknown(data['book_id']!, _bookIdMeta),
      );
    } else if (isInserting) {
      context.missing(_bookIdMeta);
    }
    if (data.containsKey('ledger_account_id')) {
      context.handle(
        _ledgerAccountIdMeta,
        ledgerAccountId.isAcceptableOrUnknown(
          data['ledger_account_id']!,
          _ledgerAccountIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_ledgerAccountIdMeta);
    }
    if (data.containsKey('transaction_id')) {
      context.handle(
        _transactionIdMeta,
        transactionId.isAcceptableOrUnknown(
          data['transaction_id']!,
          _transactionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_transactionIdMeta);
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LedgerEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LedgerEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      bookId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}book_id'],
      )!,
      ledgerAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ledger_account_id'],
      )!,
      transactionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transaction_id'],
      )!,
      amountMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_minor'],
      )!,
    );
  }

  @override
  LedgerEntries createAlias(String alias) {
    return LedgerEntries(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'FOREIGN KEY(book_id, transaction_id)REFERENCES transactions(book_id, id)',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class LedgerEntry extends DataClass implements Insertable<LedgerEntry> {
  final String id;
  final String bookId;
  final String ledgerAccountId;
  final String transactionId;
  final int amountMinor;
  const LedgerEntry({
    required this.id,
    required this.bookId,
    required this.ledgerAccountId,
    required this.transactionId,
    required this.amountMinor,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['book_id'] = Variable<String>(bookId);
    map['ledger_account_id'] = Variable<String>(ledgerAccountId);
    map['transaction_id'] = Variable<String>(transactionId);
    map['amount_minor'] = Variable<int>(amountMinor);
    return map;
  }

  LedgerEntriesCompanion toCompanion(bool nullToAbsent) {
    return LedgerEntriesCompanion(
      id: Value(id),
      bookId: Value(bookId),
      ledgerAccountId: Value(ledgerAccountId),
      transactionId: Value(transactionId),
      amountMinor: Value(amountMinor),
    );
  }

  factory LedgerEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LedgerEntry(
      id: serializer.fromJson<String>(json['id']),
      bookId: serializer.fromJson<String>(json['book_id']),
      ledgerAccountId: serializer.fromJson<String>(json['ledger_account_id']),
      transactionId: serializer.fromJson<String>(json['transaction_id']),
      amountMinor: serializer.fromJson<int>(json['amount_minor']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'book_id': serializer.toJson<String>(bookId),
      'ledger_account_id': serializer.toJson<String>(ledgerAccountId),
      'transaction_id': serializer.toJson<String>(transactionId),
      'amount_minor': serializer.toJson<int>(amountMinor),
    };
  }

  LedgerEntry copyWith({
    String? id,
    String? bookId,
    String? ledgerAccountId,
    String? transactionId,
    int? amountMinor,
  }) => LedgerEntry(
    id: id ?? this.id,
    bookId: bookId ?? this.bookId,
    ledgerAccountId: ledgerAccountId ?? this.ledgerAccountId,
    transactionId: transactionId ?? this.transactionId,
    amountMinor: amountMinor ?? this.amountMinor,
  );
  LedgerEntry copyWithCompanion(LedgerEntriesCompanion data) {
    return LedgerEntry(
      id: data.id.present ? data.id.value : this.id,
      bookId: data.bookId.present ? data.bookId.value : this.bookId,
      ledgerAccountId: data.ledgerAccountId.present
          ? data.ledgerAccountId.value
          : this.ledgerAccountId,
      transactionId: data.transactionId.present
          ? data.transactionId.value
          : this.transactionId,
      amountMinor: data.amountMinor.present
          ? data.amountMinor.value
          : this.amountMinor,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LedgerEntry(')
          ..write('id: $id, ')
          ..write('bookId: $bookId, ')
          ..write('ledgerAccountId: $ledgerAccountId, ')
          ..write('transactionId: $transactionId, ')
          ..write('amountMinor: $amountMinor')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, bookId, ledgerAccountId, transactionId, amountMinor);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LedgerEntry &&
          other.id == this.id &&
          other.bookId == this.bookId &&
          other.ledgerAccountId == this.ledgerAccountId &&
          other.transactionId == this.transactionId &&
          other.amountMinor == this.amountMinor);
}

class LedgerEntriesCompanion extends UpdateCompanion<LedgerEntry> {
  final Value<String> id;
  final Value<String> bookId;
  final Value<String> ledgerAccountId;
  final Value<String> transactionId;
  final Value<int> amountMinor;
  final Value<int> rowid;
  const LedgerEntriesCompanion({
    this.id = const Value.absent(),
    this.bookId = const Value.absent(),
    this.ledgerAccountId = const Value.absent(),
    this.transactionId = const Value.absent(),
    this.amountMinor = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LedgerEntriesCompanion.insert({
    required String id,
    required String bookId,
    required String ledgerAccountId,
    required String transactionId,
    required int amountMinor,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       bookId = Value(bookId),
       ledgerAccountId = Value(ledgerAccountId),
       transactionId = Value(transactionId),
       amountMinor = Value(amountMinor);
  static Insertable<LedgerEntry> custom({
    Expression<String>? id,
    Expression<String>? bookId,
    Expression<String>? ledgerAccountId,
    Expression<String>? transactionId,
    Expression<int>? amountMinor,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (bookId != null) 'book_id': bookId,
      if (ledgerAccountId != null) 'ledger_account_id': ledgerAccountId,
      if (transactionId != null) 'transaction_id': transactionId,
      if (amountMinor != null) 'amount_minor': amountMinor,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LedgerEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? bookId,
    Value<String>? ledgerAccountId,
    Value<String>? transactionId,
    Value<int>? amountMinor,
    Value<int>? rowid,
  }) {
    return LedgerEntriesCompanion(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      ledgerAccountId: ledgerAccountId ?? this.ledgerAccountId,
      transactionId: transactionId ?? this.transactionId,
      amountMinor: amountMinor ?? this.amountMinor,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (bookId.present) {
      map['book_id'] = Variable<String>(bookId.value);
    }
    if (ledgerAccountId.present) {
      map['ledger_account_id'] = Variable<String>(ledgerAccountId.value);
    }
    if (transactionId.present) {
      map['transaction_id'] = Variable<String>(transactionId.value);
    }
    if (amountMinor.present) {
      map['amount_minor'] = Variable<int>(amountMinor.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LedgerEntriesCompanion(')
          ..write('id: $id, ')
          ..write('bookId: $bookId, ')
          ..write('ledgerAccountId: $ledgerAccountId, ')
          ..write('transactionId: $transactionId, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$SpikeDatabase extends GeneratedDatabase {
  _$SpikeDatabase(QueryExecutor e) : super(e);
  $SpikeDatabaseManager get managers => $SpikeDatabaseManager(this);
  late final Books books = Books(this);
  late final Index uqBooksSingleDefault = Index(
    'uq_books_single_default',
    'CREATE UNIQUE INDEX uq_books_single_default ON books (is_default) WHERE is_default = 1',
  );
  late final LedgerAccounts ledgerAccounts = LedgerAccounts(this);
  late final Accounts accounts = Accounts(this);
  late final Transactions transactions = Transactions(this);
  late final LedgerEntries ledgerEntries = LedgerEntries(this);
  late final Trigger ledgerEntryBookScopeInsert = Trigger(
    'CREATE TRIGGER ledger_entry_book_scope_insert BEFORE INSERT ON ledger_entries BEGIN SELECT CASE WHEN EXISTS (SELECT 1 FROM ledger_accounts AS la WHERE la.id = NEW.ledger_account_id AND la.linked_account_nature IS NOT NULL AND NOT EXISTS (SELECT 1 FROM accounts AS a WHERE a.ledger_account_id = la.id AND a.book_id = NEW.book_id AND a.nature = la.linked_account_nature)) THEN RAISE (ABORT, \'user ledger account belongs to another book\') END;END',
    'ledger_entry_book_scope_insert',
  );
  late final Trigger ledgerEntryBookScopeUpdate = Trigger(
    'CREATE TRIGGER ledger_entry_book_scope_update BEFORE UPDATE OF book_id, ledger_account_id ON ledger_entries BEGIN SELECT CASE WHEN EXISTS (SELECT 1 FROM ledger_accounts AS la WHERE la.id = NEW.ledger_account_id AND la.linked_account_nature IS NOT NULL AND NOT EXISTS (SELECT 1 FROM accounts AS a WHERE a.ledger_account_id = la.id AND a.book_id = NEW.book_id AND a.nature = la.linked_account_nature)) THEN RAISE (ABORT, \'user ledger account belongs to another book\') END;END',
    'ledger_entry_book_scope_update',
  );
  Selectable<Book> allBooks() {
    return customSelect(
      'SELECT * FROM books ORDER BY id',
      variables: [],
      readsFrom: {this.books},
    ).asyncMap(this.books.mapFromRow);
  }

  Future<int> insertBook(String id, String name, int isDefault) {
    return customInsert(
      'INSERT INTO books (id, name, is_default) VALUES (?1, ?2, ?3)',
      variables: [
        Variable<String>(id),
        Variable<String>(name),
        Variable<int>(isDefault),
      ],
      updates: {this.books},
    );
  }

  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    books,
    uqBooksSingleDefault,
    ledgerAccounts,
    accounts,
    transactions,
    ledgerEntries,
    ledgerEntryBookScopeInsert,
    ledgerEntryBookScopeUpdate,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'ledger_entries',
        limitUpdateKind: UpdateKind.insert,
      ),
      result: [],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'ledger_entries',
        limitUpdateKind: UpdateKind.update,
      ),
      result: [],
    ),
  ]);
}

typedef $BooksCreateCompanionBuilder =
    BooksCompanion Function({
      required String id,
      required String name,
      required int isDefault,
      Value<int> rowid,
    });
typedef $BooksUpdateCompanionBuilder =
    BooksCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<int> isDefault,
      Value<int> rowid,
    });

final class $BooksReferences
    extends BaseReferences<_$SpikeDatabase, Books, Book> {
  $BooksReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<Accounts, List<Account>> _accountsRefsTable(
    _$SpikeDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.accounts,
    aliasName: 'books__id__accounts__book_id',
  );

  $AccountsProcessedTableManager get accountsRefs {
    final manager = $AccountsTableManager(
      $_db,
      $_db.accounts,
    ).filter((f) => f.bookId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_accountsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<Transactions, List<Transaction>>
  _transactionsRefsTable(_$SpikeDatabase db) => MultiTypedResultKey.fromTable(
    db.transactions,
    aliasName: 'books__id__transactions__book_id',
  );

  $TransactionsProcessedTableManager get transactionsRefs {
    final manager = $TransactionsTableManager(
      $_db,
      $_db.transactions,
    ).filter((f) => f.bookId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_transactionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<LedgerEntries, List<LedgerEntry>>
  _ledgerEntriesRefsTable(_$SpikeDatabase db) => MultiTypedResultKey.fromTable(
    db.ledgerEntries,
    aliasName: 'books__id__ledger_entries__book_id',
  );

  $LedgerEntriesProcessedTableManager get ledgerEntriesRefs {
    final manager = $LedgerEntriesTableManager(
      $_db,
      $_db.ledgerEntries,
    ).filter((f) => f.bookId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_ledgerEntriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $BooksFilterComposer extends Composer<_$SpikeDatabase, Books> {
  $BooksFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> accountsRefs(
    Expression<bool> Function($AccountsFilterComposer f) f,
  ) {
    final $AccountsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.bookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $AccountsFilterComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> transactionsRefs(
    Expression<bool> Function($TransactionsFilterComposer f) f,
  ) {
    final $TransactionsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.bookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $TransactionsFilterComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> ledgerEntriesRefs(
    Expression<bool> Function($LedgerEntriesFilterComposer f) f,
  ) {
    final $LedgerEntriesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ledgerEntries,
      getReferencedColumn: (t) => t.bookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $LedgerEntriesFilterComposer(
            $db: $db,
            $table: $db.ledgerEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $BooksOrderingComposer extends Composer<_$SpikeDatabase, Books> {
  $BooksOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnOrderings(column),
  );
}

class $BooksAnnotationComposer extends Composer<_$SpikeDatabase, Books> {
  $BooksAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get isDefault =>
      $composableBuilder(column: $table.isDefault, builder: (column) => column);

  Expression<T> accountsRefs<T extends Object>(
    Expression<T> Function($AccountsAnnotationComposer a) f,
  ) {
    final $AccountsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.bookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $AccountsAnnotationComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> transactionsRefs<T extends Object>(
    Expression<T> Function($TransactionsAnnotationComposer a) f,
  ) {
    final $TransactionsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.bookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $TransactionsAnnotationComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> ledgerEntriesRefs<T extends Object>(
    Expression<T> Function($LedgerEntriesAnnotationComposer a) f,
  ) {
    final $LedgerEntriesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ledgerEntries,
      getReferencedColumn: (t) => t.bookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $LedgerEntriesAnnotationComposer(
            $db: $db,
            $table: $db.ledgerEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $BooksTableManager
    extends
        RootTableManager<
          _$SpikeDatabase,
          Books,
          Book,
          $BooksFilterComposer,
          $BooksOrderingComposer,
          $BooksAnnotationComposer,
          $BooksCreateCompanionBuilder,
          $BooksUpdateCompanionBuilder,
          (Book, $BooksReferences),
          Book,
          PrefetchHooks Function({
            bool accountsRefs,
            bool transactionsRefs,
            bool ledgerEntriesRefs,
          })
        > {
  $BooksTableManager(_$SpikeDatabase db, Books table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $BooksFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $BooksOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $BooksAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> isDefault = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BooksCompanion(
                id: id,
                name: name,
                isDefault: isDefault,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required int isDefault,
                Value<int> rowid = const Value.absent(),
              }) => BooksCompanion.insert(
                id: id,
                name: name,
                isDefault: isDefault,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<Books, Book>(table),
                  $BooksReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                accountsRefs = false,
                transactionsRefs = false,
                ledgerEntriesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (accountsRefs) db.accounts,
                    if (transactionsRefs) db.transactions,
                    if (ledgerEntriesRefs) db.ledgerEntries,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (accountsRefs)
                        await $_getPrefetchedDataByColumns<
                          Book,
                          Books,
                          Account,
                          Accounts
                        >(
                          currentTable: table,
                          referencedTable: $BooksReferences._accountsRefsTable(
                            db,
                          ),
                          managerFromTypedResult: (p0) =>
                              $BooksReferences(db, table, p0).accountsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'book_id',
                          typedResults: items,
                        ),
                      if (transactionsRefs)
                        await $_getPrefetchedDataByColumns<
                          Book,
                          Books,
                          Transaction,
                          Transactions
                        >(
                          currentTable: table,
                          referencedTable: $BooksReferences
                              ._transactionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $BooksReferences(db, table, p0).transactionsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'book_id',
                          typedResults: items,
                        ),
                      if (ledgerEntriesRefs)
                        await $_getPrefetchedDataByColumns<
                          Book,
                          Books,
                          LedgerEntry,
                          LedgerEntries
                        >(
                          currentTable: table,
                          referencedTable: $BooksReferences
                              ._ledgerEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $BooksReferences(db, table, p0).ledgerEntriesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'book_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $BooksProcessedTableManager =
    ProcessedTableManager<
      _$SpikeDatabase,
      Books,
      Book,
      $BooksFilterComposer,
      $BooksOrderingComposer,
      $BooksAnnotationComposer,
      $BooksCreateCompanionBuilder,
      $BooksUpdateCompanionBuilder,
      (Book, $BooksReferences),
      Book,
      PrefetchHooks Function({
        bool accountsRefs,
        bool transactionsRefs,
        bool ledgerEntriesRefs,
      })
    >;
typedef $LedgerAccountsCreateCompanionBuilder =
    LedgerAccountsCompanion Function({
      required String id,
      required String accountType,
      Value<String?> linkedAccountNature,
      Value<int> rowid,
    });
typedef $LedgerAccountsUpdateCompanionBuilder =
    LedgerAccountsCompanion Function({
      Value<String> id,
      Value<String> accountType,
      Value<String?> linkedAccountNature,
      Value<int> rowid,
    });

final class $LedgerAccountsReferences
    extends BaseReferences<_$SpikeDatabase, LedgerAccounts, LedgerAccount> {
  $LedgerAccountsReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<LedgerEntries, List<LedgerEntry>>
  _ledgerEntriesRefsTable(_$SpikeDatabase db) => MultiTypedResultKey.fromTable(
    db.ledgerEntries,
    aliasName: 'ledger_accounts__id__ledger_entries__ledger_account_id',
  );

  $LedgerEntriesProcessedTableManager get ledgerEntriesRefs {
    final manager = $LedgerEntriesTableManager($_db, $_db.ledgerEntries).filter(
      (f) => f.ledgerAccountId.id.sqlEquals($_itemColumn<String>('id')!),
    );

    final cache = $_typedResult.readTableOrNull(_ledgerEntriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $LedgerAccountsFilterComposer
    extends Composer<_$SpikeDatabase, LedgerAccounts> {
  $LedgerAccountsFilterComposer({
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

  ColumnFilters<String> get accountType => $composableBuilder(
    column: $table.accountType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get linkedAccountNature => $composableBuilder(
    column: $table.linkedAccountNature,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> ledgerEntriesRefs(
    Expression<bool> Function($LedgerEntriesFilterComposer f) f,
  ) {
    final $LedgerEntriesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ledgerEntries,
      getReferencedColumn: (t) => t.ledgerAccountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $LedgerEntriesFilterComposer(
            $db: $db,
            $table: $db.ledgerEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $LedgerAccountsOrderingComposer
    extends Composer<_$SpikeDatabase, LedgerAccounts> {
  $LedgerAccountsOrderingComposer({
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

  ColumnOrderings<String> get accountType => $composableBuilder(
    column: $table.accountType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get linkedAccountNature => $composableBuilder(
    column: $table.linkedAccountNature,
    builder: (column) => ColumnOrderings(column),
  );
}

class $LedgerAccountsAnnotationComposer
    extends Composer<_$SpikeDatabase, LedgerAccounts> {
  $LedgerAccountsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get accountType => $composableBuilder(
    column: $table.accountType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get linkedAccountNature => $composableBuilder(
    column: $table.linkedAccountNature,
    builder: (column) => column,
  );

  Expression<T> ledgerEntriesRefs<T extends Object>(
    Expression<T> Function($LedgerEntriesAnnotationComposer a) f,
  ) {
    final $LedgerEntriesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ledgerEntries,
      getReferencedColumn: (t) => t.ledgerAccountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $LedgerEntriesAnnotationComposer(
            $db: $db,
            $table: $db.ledgerEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $LedgerAccountsTableManager
    extends
        RootTableManager<
          _$SpikeDatabase,
          LedgerAccounts,
          LedgerAccount,
          $LedgerAccountsFilterComposer,
          $LedgerAccountsOrderingComposer,
          $LedgerAccountsAnnotationComposer,
          $LedgerAccountsCreateCompanionBuilder,
          $LedgerAccountsUpdateCompanionBuilder,
          (LedgerAccount, $LedgerAccountsReferences),
          LedgerAccount,
          PrefetchHooks Function({bool ledgerEntriesRefs})
        > {
  $LedgerAccountsTableManager(_$SpikeDatabase db, LedgerAccounts table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $LedgerAccountsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $LedgerAccountsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $LedgerAccountsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> accountType = const Value.absent(),
                Value<String?> linkedAccountNature = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LedgerAccountsCompanion(
                id: id,
                accountType: accountType,
                linkedAccountNature: linkedAccountNature,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String accountType,
                Value<String?> linkedAccountNature = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LedgerAccountsCompanion.insert(
                id: id,
                accountType: accountType,
                linkedAccountNature: linkedAccountNature,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<LedgerAccounts, LedgerAccount>(table),
                  $LedgerAccountsReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({ledgerEntriesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (ledgerEntriesRefs) db.ledgerEntries,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (ledgerEntriesRefs)
                    await $_getPrefetchedDataByColumns<
                      LedgerAccount,
                      LedgerAccounts,
                      LedgerEntry,
                      LedgerEntries
                    >(
                      currentTable: table,
                      referencedTable: $LedgerAccountsReferences
                          ._ledgerEntriesRefsTable(db),
                      managerFromTypedResult: (p0) => $LedgerAccountsReferences(
                        db,
                        table,
                        p0,
                      ).ledgerEntriesRefs,
                      currentColumn: 'id',
                      referencedColumn: 'ledger_account_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $LedgerAccountsProcessedTableManager =
    ProcessedTableManager<
      _$SpikeDatabase,
      LedgerAccounts,
      LedgerAccount,
      $LedgerAccountsFilterComposer,
      $LedgerAccountsOrderingComposer,
      $LedgerAccountsAnnotationComposer,
      $LedgerAccountsCreateCompanionBuilder,
      $LedgerAccountsUpdateCompanionBuilder,
      (LedgerAccount, $LedgerAccountsReferences),
      LedgerAccount,
      PrefetchHooks Function({bool ledgerEntriesRefs})
    >;
typedef $AccountsCreateCompanionBuilder =
    AccountsCompanion Function({
      required String bookId,
      required String id,
      required String nature,
      required String ledgerAccountId,
      Value<int> rowid,
    });
typedef $AccountsUpdateCompanionBuilder =
    AccountsCompanion Function({
      Value<String> bookId,
      Value<String> id,
      Value<String> nature,
      Value<String> ledgerAccountId,
      Value<int> rowid,
    });

final class $AccountsReferences
    extends BaseReferences<_$SpikeDatabase, Accounts, Account> {
  $AccountsReferences(super.$_db, super.$_table, super.$_typedResult);

  static Books _bookIdTable(_$SpikeDatabase db) =>
      db.books.createAlias('accounts__book_id__books__id');

  $BooksProcessedTableManager get bookId {
    final $_column = $_itemColumn<String>('book_id')!;

    final manager = $BooksTableManager(
      $_db,
      $_db.books,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_bookIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $AccountsFilterComposer extends Composer<_$SpikeDatabase, Accounts> {
  $AccountsFilterComposer({
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

  ColumnFilters<String> get nature => $composableBuilder(
    column: $table.nature,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ledgerAccountId => $composableBuilder(
    column: $table.ledgerAccountId,
    builder: (column) => ColumnFilters(column),
  );

  $BooksFilterComposer get bookId {
    final $BooksFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $BooksFilterComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $AccountsOrderingComposer extends Composer<_$SpikeDatabase, Accounts> {
  $AccountsOrderingComposer({
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

  ColumnOrderings<String> get nature => $composableBuilder(
    column: $table.nature,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ledgerAccountId => $composableBuilder(
    column: $table.ledgerAccountId,
    builder: (column) => ColumnOrderings(column),
  );

  $BooksOrderingComposer get bookId {
    final $BooksOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $BooksOrderingComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $AccountsAnnotationComposer extends Composer<_$SpikeDatabase, Accounts> {
  $AccountsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nature =>
      $composableBuilder(column: $table.nature, builder: (column) => column);

  GeneratedColumn<String> get ledgerAccountId => $composableBuilder(
    column: $table.ledgerAccountId,
    builder: (column) => column,
  );

  $BooksAnnotationComposer get bookId {
    final $BooksAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $BooksAnnotationComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $AccountsTableManager
    extends
        RootTableManager<
          _$SpikeDatabase,
          Accounts,
          Account,
          $AccountsFilterComposer,
          $AccountsOrderingComposer,
          $AccountsAnnotationComposer,
          $AccountsCreateCompanionBuilder,
          $AccountsUpdateCompanionBuilder,
          (Account, $AccountsReferences),
          Account,
          PrefetchHooks Function({bool bookId})
        > {
  $AccountsTableManager(_$SpikeDatabase db, Accounts table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $AccountsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $AccountsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $AccountsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> bookId = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> nature = const Value.absent(),
                Value<String> ledgerAccountId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AccountsCompanion(
                bookId: bookId,
                id: id,
                nature: nature,
                ledgerAccountId: ledgerAccountId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String bookId,
                required String id,
                required String nature,
                required String ledgerAccountId,
                Value<int> rowid = const Value.absent(),
              }) => AccountsCompanion.insert(
                bookId: bookId,
                id: id,
                nature: nature,
                ledgerAccountId: ledgerAccountId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<Accounts, Account>(table),
                  $AccountsReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({bookId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (bookId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.bookId,
                                referencedTable: $AccountsReferences
                                    ._bookIdTable(db),
                                referencedColumn: $AccountsReferences
                                    ._bookIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $AccountsProcessedTableManager =
    ProcessedTableManager<
      _$SpikeDatabase,
      Accounts,
      Account,
      $AccountsFilterComposer,
      $AccountsOrderingComposer,
      $AccountsAnnotationComposer,
      $AccountsCreateCompanionBuilder,
      $AccountsUpdateCompanionBuilder,
      (Account, $AccountsReferences),
      Account,
      PrefetchHooks Function({bool bookId})
    >;
typedef $TransactionsCreateCompanionBuilder =
    TransactionsCompanion Function({
      required String bookId,
      required String id,
      required String sourceAccountId,
      required int amountMinor,
      Value<int> rowid,
    });
typedef $TransactionsUpdateCompanionBuilder =
    TransactionsCompanion Function({
      Value<String> bookId,
      Value<String> id,
      Value<String> sourceAccountId,
      Value<int> amountMinor,
      Value<int> rowid,
    });

final class $TransactionsReferences
    extends BaseReferences<_$SpikeDatabase, Transactions, Transaction> {
  $TransactionsReferences(super.$_db, super.$_table, super.$_typedResult);

  static Books _bookIdTable(_$SpikeDatabase db) =>
      db.books.createAlias('transactions__book_id__books__id');

  $BooksProcessedTableManager get bookId {
    final $_column = $_itemColumn<String>('book_id')!;

    final manager = $BooksTableManager(
      $_db,
      $_db.books,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_bookIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $TransactionsFilterComposer
    extends Composer<_$SpikeDatabase, Transactions> {
  $TransactionsFilterComposer({
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

  ColumnFilters<String> get sourceAccountId => $composableBuilder(
    column: $table.sourceAccountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => ColumnFilters(column),
  );

  $BooksFilterComposer get bookId {
    final $BooksFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $BooksFilterComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $TransactionsOrderingComposer
    extends Composer<_$SpikeDatabase, Transactions> {
  $TransactionsOrderingComposer({
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

  ColumnOrderings<String> get sourceAccountId => $composableBuilder(
    column: $table.sourceAccountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => ColumnOrderings(column),
  );

  $BooksOrderingComposer get bookId {
    final $BooksOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $BooksOrderingComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $TransactionsAnnotationComposer
    extends Composer<_$SpikeDatabase, Transactions> {
  $TransactionsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sourceAccountId => $composableBuilder(
    column: $table.sourceAccountId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => column,
  );

  $BooksAnnotationComposer get bookId {
    final $BooksAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $BooksAnnotationComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $TransactionsTableManager
    extends
        RootTableManager<
          _$SpikeDatabase,
          Transactions,
          Transaction,
          $TransactionsFilterComposer,
          $TransactionsOrderingComposer,
          $TransactionsAnnotationComposer,
          $TransactionsCreateCompanionBuilder,
          $TransactionsUpdateCompanionBuilder,
          (Transaction, $TransactionsReferences),
          Transaction,
          PrefetchHooks Function({bool bookId})
        > {
  $TransactionsTableManager(_$SpikeDatabase db, Transactions table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $TransactionsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $TransactionsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $TransactionsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> bookId = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> sourceAccountId = const Value.absent(),
                Value<int> amountMinor = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransactionsCompanion(
                bookId: bookId,
                id: id,
                sourceAccountId: sourceAccountId,
                amountMinor: amountMinor,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String bookId,
                required String id,
                required String sourceAccountId,
                required int amountMinor,
                Value<int> rowid = const Value.absent(),
              }) => TransactionsCompanion.insert(
                bookId: bookId,
                id: id,
                sourceAccountId: sourceAccountId,
                amountMinor: amountMinor,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<Transactions, Transaction>(table),
                  $TransactionsReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({bookId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (bookId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.bookId,
                                referencedTable: $TransactionsReferences
                                    ._bookIdTable(db),
                                referencedColumn: $TransactionsReferences
                                    ._bookIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $TransactionsProcessedTableManager =
    ProcessedTableManager<
      _$SpikeDatabase,
      Transactions,
      Transaction,
      $TransactionsFilterComposer,
      $TransactionsOrderingComposer,
      $TransactionsAnnotationComposer,
      $TransactionsCreateCompanionBuilder,
      $TransactionsUpdateCompanionBuilder,
      (Transaction, $TransactionsReferences),
      Transaction,
      PrefetchHooks Function({bool bookId})
    >;
typedef $LedgerEntriesCreateCompanionBuilder =
    LedgerEntriesCompanion Function({
      required String id,
      required String bookId,
      required String ledgerAccountId,
      required String transactionId,
      required int amountMinor,
      Value<int> rowid,
    });
typedef $LedgerEntriesUpdateCompanionBuilder =
    LedgerEntriesCompanion Function({
      Value<String> id,
      Value<String> bookId,
      Value<String> ledgerAccountId,
      Value<String> transactionId,
      Value<int> amountMinor,
      Value<int> rowid,
    });

final class $LedgerEntriesReferences
    extends BaseReferences<_$SpikeDatabase, LedgerEntries, LedgerEntry> {
  $LedgerEntriesReferences(super.$_db, super.$_table, super.$_typedResult);

  static Books _bookIdTable(_$SpikeDatabase db) =>
      db.books.createAlias('ledger_entries__book_id__books__id');

  $BooksProcessedTableManager get bookId {
    final $_column = $_itemColumn<String>('book_id')!;

    final manager = $BooksTableManager(
      $_db,
      $_db.books,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_bookIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static LedgerAccounts _ledgerAccountIdTable(_$SpikeDatabase db) => db
      .ledgerAccounts
      .createAlias('ledger_entries__ledger_account_id__ledger_accounts__id');

  $LedgerAccountsProcessedTableManager get ledgerAccountId {
    final $_column = $_itemColumn<String>('ledger_account_id')!;

    final manager = $LedgerAccountsTableManager(
      $_db,
      $_db.ledgerAccounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_ledgerAccountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $LedgerEntriesFilterComposer
    extends Composer<_$SpikeDatabase, LedgerEntries> {
  $LedgerEntriesFilterComposer({
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

  ColumnFilters<String> get transactionId => $composableBuilder(
    column: $table.transactionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => ColumnFilters(column),
  );

  $BooksFilterComposer get bookId {
    final $BooksFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $BooksFilterComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $LedgerAccountsFilterComposer get ledgerAccountId {
    final $LedgerAccountsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ledgerAccountId,
      referencedTable: $db.ledgerAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $LedgerAccountsFilterComposer(
            $db: $db,
            $table: $db.ledgerAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $LedgerEntriesOrderingComposer
    extends Composer<_$SpikeDatabase, LedgerEntries> {
  $LedgerEntriesOrderingComposer({
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

  ColumnOrderings<String> get transactionId => $composableBuilder(
    column: $table.transactionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => ColumnOrderings(column),
  );

  $BooksOrderingComposer get bookId {
    final $BooksOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $BooksOrderingComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $LedgerAccountsOrderingComposer get ledgerAccountId {
    final $LedgerAccountsOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ledgerAccountId,
      referencedTable: $db.ledgerAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $LedgerAccountsOrderingComposer(
            $db: $db,
            $table: $db.ledgerAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $LedgerEntriesAnnotationComposer
    extends Composer<_$SpikeDatabase, LedgerEntries> {
  $LedgerEntriesAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get transactionId => $composableBuilder(
    column: $table.transactionId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => column,
  );

  $BooksAnnotationComposer get bookId {
    final $BooksAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $BooksAnnotationComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $LedgerAccountsAnnotationComposer get ledgerAccountId {
    final $LedgerAccountsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ledgerAccountId,
      referencedTable: $db.ledgerAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $LedgerAccountsAnnotationComposer(
            $db: $db,
            $table: $db.ledgerAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $LedgerEntriesTableManager
    extends
        RootTableManager<
          _$SpikeDatabase,
          LedgerEntries,
          LedgerEntry,
          $LedgerEntriesFilterComposer,
          $LedgerEntriesOrderingComposer,
          $LedgerEntriesAnnotationComposer,
          $LedgerEntriesCreateCompanionBuilder,
          $LedgerEntriesUpdateCompanionBuilder,
          (LedgerEntry, $LedgerEntriesReferences),
          LedgerEntry,
          PrefetchHooks Function({bool bookId, bool ledgerAccountId})
        > {
  $LedgerEntriesTableManager(_$SpikeDatabase db, LedgerEntries table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $LedgerEntriesFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $LedgerEntriesOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $LedgerEntriesAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> bookId = const Value.absent(),
                Value<String> ledgerAccountId = const Value.absent(),
                Value<String> transactionId = const Value.absent(),
                Value<int> amountMinor = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LedgerEntriesCompanion(
                id: id,
                bookId: bookId,
                ledgerAccountId: ledgerAccountId,
                transactionId: transactionId,
                amountMinor: amountMinor,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String bookId,
                required String ledgerAccountId,
                required String transactionId,
                required int amountMinor,
                Value<int> rowid = const Value.absent(),
              }) => LedgerEntriesCompanion.insert(
                id: id,
                bookId: bookId,
                ledgerAccountId: ledgerAccountId,
                transactionId: transactionId,
                amountMinor: amountMinor,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<LedgerEntries, LedgerEntry>(table),
                  $LedgerEntriesReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({bookId = false, ledgerAccountId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (bookId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.bookId,
                                referencedTable: $LedgerEntriesReferences
                                    ._bookIdTable(db),
                                referencedColumn: $LedgerEntriesReferences
                                    ._bookIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (ledgerAccountId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.ledgerAccountId,
                                referencedTable: $LedgerEntriesReferences
                                    ._ledgerAccountIdTable(db),
                                referencedColumn: $LedgerEntriesReferences
                                    ._ledgerAccountIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $LedgerEntriesProcessedTableManager =
    ProcessedTableManager<
      _$SpikeDatabase,
      LedgerEntries,
      LedgerEntry,
      $LedgerEntriesFilterComposer,
      $LedgerEntriesOrderingComposer,
      $LedgerEntriesAnnotationComposer,
      $LedgerEntriesCreateCompanionBuilder,
      $LedgerEntriesUpdateCompanionBuilder,
      (LedgerEntry, $LedgerEntriesReferences),
      LedgerEntry,
      PrefetchHooks Function({bool bookId, bool ledgerAccountId})
    >;

class $SpikeDatabaseManager {
  final _$SpikeDatabase _db;
  $SpikeDatabaseManager(this._db);
  $BooksTableManager get books => $BooksTableManager(_db, _db.books);
  $LedgerAccountsTableManager get ledgerAccounts =>
      $LedgerAccountsTableManager(_db, _db.ledgerAccounts);
  $AccountsTableManager get accounts =>
      $AccountsTableManager(_db, _db.accounts);
  $TransactionsTableManager get transactions =>
      $TransactionsTableManager(_db, _db.transactions);
  $LedgerEntriesTableManager get ledgerEntries =>
      $LedgerEntriesTableManager(_db, _db.ledgerEntries);
}
