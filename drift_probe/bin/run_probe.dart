import 'package:sqlite3/sqlite3.dart' show SqliteException;
import 'package:wafferly_drift_codegen_probe/spike_database.dart';

Future<void> expectSqliteFailure(
  Future<void> Function() action,
  String label,
) async {
  try {
    await action();
  } on SqliteException {
    print('PASS negative: $label');
    return;
  }
  throw StateError('Expected SQLite constraint failure: $label');
}

Future<void> main() async {
  final db = SpikeDatabase();
  try {
    final fkRows = await db.customSelect('PRAGMA foreign_keys').get();
    final fkEnabled = fkRows.single.read<int>('foreign_keys');
    if (fkEnabled != 1) {
      throw StateError('Foreign key enforcement is not enabled on this connection');
    }
    print('PASS: PRAGMA foreign_keys is ON for Drift connection');

    await db.insertBook('personal', 'Personal', 1);
    await db.customStatement(
      "INSERT INTO ledger_accounts (id, account_type, linked_account_nature) "
      "VALUES ('la-cash', 'asset', 'asset')",
    );
    await db.customStatement(
      "INSERT INTO ledger_accounts (id, account_type, linked_account_nature) "
      "VALUES ('la-expense', 'expense', NULL)",
    );
    await db.customStatement(
      "INSERT INTO accounts (book_id, id, nature, ledger_account_id) "
      "VALUES ('personal', 'cash', 'asset', 'la-cash')",
    );
    await db.customStatement(
      "INSERT INTO transactions (book_id, id, source_account_id, amount_minor) "
      "VALUES ('personal', 'tx-1', 'cash', 1250)",
    );
    await db.customStatement(
      "INSERT INTO ledger_entries (id, book_id, ledger_account_id, transaction_id, amount_minor) "
      "VALUES ('le-1', 'personal', 'la-expense', 'tx-1', 1250)",
    );
    print('PASS: Drift-generated schema creates tables, composite FKs and trigger');

    await expectSqliteFailure(
      () => db.customStatement(
        "INSERT INTO accounts (book_id, id, nature, ledger_account_id) "
        "VALUES ('personal', 'wrong-nature', 'liability', 'la-cash')",
      ),
      'composite nature FK rejects wrong Account nature',
    );
    await expectSqliteFailure(
      () => db.customStatement(
        "INSERT INTO transactions (book_id, id, source_account_id, amount_minor) "
        "VALUES ('missing-book', 'tx-bad', 'cash', 1)",
      ),
      'composite FK rejects Transaction from another Book',
    );
    await expectSqliteFailure(
      () => db.customStatement(
        "INSERT INTO transactions (book_id, id, source_account_id, amount_minor) "
        "VALUES ('personal', 'tx-fraction', 'cash', 1.25)",
      ),
      'typeof CHECK rejects fractional Minor Units',
    );

    // Exercise the INSERT trigger, not merely its creation.
    await db.insertBook('business', 'Business', 0);
    await db.customStatement(
      "INSERT INTO ledger_accounts (id, account_type, linked_account_nature) "
      "VALUES ('la-business-cash', 'asset', 'asset')",
    );
    await db.customStatement(
      "INSERT INTO accounts (book_id, id, nature, ledger_account_id) "
      "VALUES ('business', 'cash', 'asset', 'la-business-cash')",
    );
    await db.customStatement(
      "INSERT INTO transactions (book_id, id, source_account_id, amount_minor) "
      "VALUES ('business', 'tx-business', 'cash', 500)",
    );
    await db.customStatement(
      "INSERT INTO ledger_entries "
      "(id, book_id, ledger_account_id, transaction_id, amount_minor) "
      "VALUES ('le-business', 'business', 'la-business-cash', 'tx-business', 500)",
    );
    await expectSqliteFailure(
      () => db.customStatement(
        "INSERT INTO ledger_entries "
        "(id, book_id, ledger_account_id, transaction_id, amount_minor) "
        "VALUES ('le-cross-book', 'business', 'la-cash', 'tx-business', 500)",
      ),
      'INSERT trigger rejects user Ledger Account from another Book',
    );

    // UPDATE must enforce the same Book ownership rule as INSERT.
    await expectSqliteFailure(
      () => db.customStatement(
        "UPDATE ledger_entries SET ledger_account_id = 'la-cash' "
        "WHERE id = 'le-business'",
      ),
      'UPDATE trigger rejects user Ledger Account from another Book',
    );

    // SQLite INTEGER affinity alone is insufficient; the CHECK must also
    // protect updates, not only inserts.
    await expectSqliteFailure(
      () => db.customStatement(
        "UPDATE transactions SET amount_minor = 1.25 "
        "WHERE book_id = 'personal' AND id = 'tx-1'",
      ),
      'UPDATE CHECK rejects fractional Minor Units',
    );

    // Account.nature participates in a composite FK with the linked ledger
    // account, so changing its nature must be rejected when it no longer
    // matches the ledger account's declared nature.
    await expectSqliteFailure(
      () => db.customStatement(
        "UPDATE accounts SET nature = 'liability' "
        "WHERE book_id = 'personal' AND id = 'cash'",
      ),
      'UPDATE composite FK rejects mismatched Account nature',
    );

    final books = await db.allBooks().get();
    if (books.length != 2 ||
        !books.any((book) => book.id == 'personal') ||
        !books.any((book) => book.id == 'business')) {
      throw StateError('Named .drift query did not return expected Books');
    }
    print('PASS: named .drift query is callable through generated Dart API');

    try {
      await db.transaction(() async {
        await db.insertBook('rolled-back', 'Temporary', 0);
        throw StateError('simulated failure');
      });
    } on StateError {
      // Expected: transaction must roll back the insert.
    }
    final afterRollback = await db.allBooks().get();
    if (afterRollback.any((book) => book.id == 'rolled-back')) {
      throw StateError('Drift transaction did not roll back its insert');
    }
    print('PASS: Drift transaction rolls back all enclosed writes');
  } finally {
    await db.close();
  }
}
