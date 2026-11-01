import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:wafferly/constants/transaction_constants.dart';
import 'package:wafferly/models/enums/entry_type.dart';
import 'package:wafferly/models/enums/ledger_purpose.dart';
import 'package:wafferly/models/ledger_entry.dart';
import 'package:wafferly/models/transaction.dart';
import 'package:wafferly/services/ledger_integrity_service.dart';

void main() {
  late Directory directory;
  late Box<Transaction> transactions;
  late Box<LedgerEntry> ledgerEntries;
  late Box<Map> corrections;
  late Box<Map> invalidations;

  setUpAll(() async {
    directory = await Directory.systemTemp.createTemp(
      'wafferly_ledger_integrity_test_',
    );
    Hive.init(directory.path);

    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(TransactionAdapter());
    }
    if (!Hive.isAdapterRegistered(20)) {
      Hive.registerAdapter(EntryTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(21)) {
      Hive.registerAdapter(LedgerPurposeAdapter());
    }
    if (!Hive.isAdapterRegistered(22)) {
      Hive.registerAdapter(LedgerEntryAdapter());
    }

    transactions = await Hive.openBox<Transaction>('transactions');
    ledgerEntries = await Hive.openBox<LedgerEntry>('ledger_entries');
    corrections = await Hive.openBox<Map>('financial_corrections');
    invalidations = await Hive.openBox<Map>('financial_invalidations');
  });

  tearDownAll(() async {
    await Hive.close();
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  });

  setUp(() async {
    await transactions.clear();
    await ledgerEntries.clear();
    await corrections.clear();
    await invalidations.clear();
  });

  test(
    'correction and invalidation projection groups are not reported as duplicate or orphan transactions',
    () async {
      await transactions.put(
        'tx-original',
        _transaction('tx-original', TransactionType.expense),
      );
      await transactions.put(
        'tx-corrected',
        _transaction('tx-corrected', TransactionType.expense),
      );
      await corrections.put('correction-1', {
        'correctionId': 'correction-1',
        'originalTransactionId': 'tx-original',
        'after': {'transactionId': 'tx-corrected'},
      });
      await invalidations.put('invalidation-1', {
        'invalidationId': 'invalidation-1',
        'originalTransactionId': 'tx-original',
      });

      await ledgerEntries.putAll({
        for (var i = 0; i < 2; i++) 'tx-$i': _entry('tx-original', i),
        for (var i = 0; i < 4; i++) 'correction-$i': _entry('correction-1', i),
        for (var i = 0; i < 2; i++)
          'invalidation-$i': _entry('invalidation-1', i),
      });

      final service = LedgerIntegrityService();
      expect(await service.getDuplicateTransactionIds(), isEmpty);
      expect(await service.getOrphanLedgerEntries(), isEmpty);
      expect(await service.getTransactionsWithoutLedgerEntries(), isEmpty);
    },
  );

  test(
    'unbalanced ledger projection is reported as an integrity issue',
    () async {
      await transactions.put(
        'tx-unbalanced',
        _transaction('tx-unbalanced', TransactionType.expense),
      );
      await ledgerEntries.putAll({
        'tx-unbalanced-debit': _entry('tx-unbalanced', 0, amount: 10),
        'tx-unbalanced-credit': _entry('tx-unbalanced', 1, amount: 8),
      });

      final issues = await LedgerIntegrityService()
          .getDuplicateTransactionIds();
      expect(issues, hasLength(1));
      expect(issues.single, contains('debit=10.0, credit=8.0'));
    },
  );

  test('missing opening-balance projection is detected', () async {
    await transactions.put(
      'opening-without-ledger',
      _transaction('opening-without-ledger', TransactionType.initialBalance),
    );

    final missing = await LedgerIntegrityService()
        .getTransactionsWithoutLedgerEntries();
    expect(missing.map((transaction) => transaction.id), [
      'opening-without-ledger',
    ]);
  });

  test(
    'persisted correction and invalidation without Ledger groups are reported',
    () async {
      await transactions.put(
        'corrected-transaction',
        _transaction('corrected-transaction', TransactionType.expense),
      );
      await transactions.put(
        'invalidated-transaction',
        _transaction('invalidated-transaction', TransactionType.expense),
      );
      await transactions.put(
        'original-transaction',
        _transaction('original-transaction', TransactionType.expense),
      );
      await corrections.put('correction-missing-ledger', {
        'correctionId': 'correction-missing-ledger',
        'originalTransactionId': 'original-transaction',
        'after': {'transactionId': 'corrected-transaction'},
      });
      await invalidations.put('invalidation-missing-ledger', {
        'invalidationId': 'invalidation-missing-ledger',
        'originalTransactionId': 'invalidated-transaction',
      });

      final issues = await LedgerIntegrityService()
          .getDuplicateTransactionIds();
      expect(issues, hasLength(2));
      expect(
        issues.join('\n'),
        contains('correction-missing-ledger: 0 entries (expected 4)'),
      );
      expect(
        issues.join('\n'),
        contains('invalidation-missing-ledger: 0 entries (expected 2)'),
      );
    },
  );

  test(
    'correction projection is reported when its corrected transaction record is missing',
    () async {
      await transactions.put(
        'original-correction-transaction',
        _transaction(
          'original-correction-transaction',
          TransactionType.expense,
        ),
      );
      await corrections.put('correction-without-after-record', {
        'correctionId': 'correction-without-after-record',
        'originalTransactionId': 'original-correction-transaction',
        'after': {'transactionId': 'missing-corrected-transaction'},
      });
      await ledgerEntries.putAll({
        for (var i = 0; i < 4; i++)
          'correction-without-after-record-$i': _entry(
            'correction-without-after-record',
            i,
          ),
      });

      final issues = await LedgerIntegrityService()
          .getDuplicateTransactionIds();
      expect(issues, hasLength(1));
      expect(
        issues.single,
        contains(
          'corrected transaction "missing-corrected-transaction" is missing',
        ),
      );
    },
  );

  test(
    'invalidation projection is reported when its original transaction record is missing',
    () async {
      await invalidations.put('invalidation-without-original-record', {
        'invalidationId': 'invalidation-without-original-record',
        'originalTransactionId': 'missing-original-transaction',
      });
      await ledgerEntries.putAll({
        'invalidation-without-original-record-debit': _entry(
          'invalidation-without-original-record',
          0,
        ),
        'invalidation-without-original-record-credit': _entry(
          'invalidation-without-original-record',
          1,
        ),
      });

      final issues = await LedgerIntegrityService()
          .getDuplicateTransactionIds();
      expect(issues, hasLength(1));
      expect(
        issues.single,
        contains(
          'original transaction "missing-original-transaction" is missing',
        ),
      );
    },
  );

  test('ledger groups with blank account IDs are reported', () async {
    await transactions.put(
      'tx-blank-account',
      _transaction('tx-blank-account', TransactionType.expense),
    );
    await ledgerEntries.putAll({
      'tx-blank-debit': _entry('tx-blank-account', 0),
      'tx-blank-credit': LedgerEntry(
        id: 'tx-blank-credit',
        transactionId: 'tx-blank-account',
        accountId: ' ',
        entryType: EntryType.credit,
        amount: 10,
        date: DateTime(2026, 1, 1),
        purpose: LedgerPurpose.adjustment,
      ),
    });

    expect(
      await LedgerIntegrityService().getDuplicateTransactionIds(),
      hasLength(1),
    );
  });

  test(
    'unknown ledger projection identifier is still reported as orphan',
    () async {
      await ledgerEntries.put('orphan-entry', _entry('missing-projection', 1));

      final orphans = await LedgerIntegrityService().getOrphanLedgerEntries();
      expect(orphans, hasLength(1));
      expect(orphans.single.transactionId, 'missing-projection');
    },
  );
}

Transaction _transaction(String id, String type) {
  return Transaction(
    id: id,
    amount: 10,
    type: type,
    date: DateTime(2026, 1, 1),
    paymentMethod: 'cash',
    currencyCode: 'EGP',
  );
}

LedgerEntry _entry(String projectionId, int index, {double amount = 10}) {
  return LedgerEntry(
    id: '$projectionId-entry-$index',
    transactionId: projectionId,
    accountId: 'account-$index',
    entryType: index.isEven ? EntryType.debit : EntryType.credit,
    amount: amount,
    date: DateTime(2026, 1, 1),
    purpose: LedgerPurpose.adjustment,
  );
}
