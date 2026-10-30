import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:wafferly/config/category_config.dart';
import 'package:wafferly/constants/transaction_constants.dart';
import 'package:wafferly/core/money/money.dart';
import 'package:wafferly/financial_engine/domain/financial_transaction_record.dart';
import 'package:wafferly/financial_engine/handlers/create_transaction_mutation_handler.dart';
import 'package:wafferly/financial_engine/execution/memory_financial_unit_of_work.dart';
import 'package:wafferly/financial_engine/mutations/create_transaction_mutation.dart';
import 'package:wafferly/ports/ledger_port.dart';
import 'package:wafferly/financial_engine/ports/transaction_port.dart';
import 'package:wafferly/models/enums/ledger_account_type.dart';
import 'package:wafferly/models/ledger_account.dart';
import 'package:wafferly/models/ledger_entry.dart';
import 'package:wafferly/services/ledger_projection_service.dart';

void main() {
  late Directory testDirectory;
  late Box<LedgerAccount> ledgerAccountsBox;

  setUpAll(() async {
    testDirectory = await Directory.systemTemp.createTemp(
      'wafferly_missing_category_mapping_test_',
    );
    Hive.init(testDirectory.path);

    if (!Hive.isAdapterRegistered(30)) {
      Hive.registerAdapter(LedgerAccountTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(31)) {
      Hive.registerAdapter(LedgerAccountAdapter());
    }

    ledgerAccountsBox = await Hive.openBox<LedgerAccount>('ledger_accounts');
  });

  tearDownAll(() async {
    await Hive.close();
    if (await testDirectory.exists()) {
      await testDirectory.delete(recursive: true);
    }
  });

  setUp(() async {
    // Use a real configured category but deliberately leave its expected
    // LedgerAccount unseeded to characterize the current missing-seed path.
    await ledgerAccountsBox.clear();
  });

  test(
    'KNOWN_BUG: transaction write succeeds when the configured category has no ledger mapping',
    () async {
      final transactionPort = _MemoryTransactionPort();
      final ledgerPort = _MemoryLedgerPort();
      final projectionService = LedgerProjectionService(ledgerPort: ledgerPort);
      final handler = CreateTransactionMutationHandler(
        transactionPort,
        projectionService,
      );
      final record = _expenseRecordUsingConfiguredCategory();

      await const MemoryFinancialUnitOfWork().execute((context) async {
        await handler.execute(
          CreateTransactionMutation(record: record),
          context,
        );
      });

      expect(transactionPort.records, contains(record.transactionId));
      expect(ledgerPort.entries, isEmpty);
    },
  );

  test(
    'M2 REGRESSION: a configured category without a ledger mapping fails instead of committing without projection',
    () async {
      final transactionPort = _MemoryTransactionPort();
      final ledgerPort = _MemoryLedgerPort();
      final handler = CreateTransactionMutationHandler(
        transactionPort,
        LedgerProjectionService(ledgerPort: ledgerPort),
      );
      final record = _expenseRecordUsingConfiguredCategory();

      await expectLater(
        const MemoryFinancialUnitOfWork().execute((context) async {
          await handler.execute(
            CreateTransactionMutation(record: record),
            context,
          );
        }),
        throwsA(anything),
      );

      expect(transactionPort.records, isEmpty);
      expect(ledgerPort.entries, isEmpty);
    },
    skip: 'يتفعّل في M2 بعد تحديد استثناء صريح لحالة غياب الـ mapping.',
  );
}

FinancialTransactionRecord _expenseRecordUsingConfiguredCategory() {
  return FinancialTransactionRecord(
    transactionId: 'txn-missing-category-ledger',
    type: TransactionType.expense,
    fromAccountId: 'wallet',
    categoryId: expenseCategories.first.id,
    amount: Money.fromDouble(50),
    currencyCode: 'EGP',
    paymentMethod: 'cash',
    occurredAt: DateTime(2026, 1, 2),
    isExceptional: false,
    source: 'manual',
  );
}

final class _MemoryTransactionPort implements TransactionPort {
  final Map<String, FinancialTransactionRecord> records = {};

  @override
  Future<void> save(FinancialTransactionRecord record) async {
    records[record.transactionId] = record;
  }

  @override
  Future<void> delete(String transactionId) async {
    records.remove(transactionId);
  }
}

final class _MemoryLedgerPort implements LedgerPort {
  final List<LedgerEntry> entries = [];

  @override
  Future<void> createEntries(List<LedgerEntry> newEntries) async {
    entries.addAll(newEntries);
  }

  @override
  Future<List<LedgerEntry>> getEntriesByTransactionId(
    String transactionId,
  ) async {
    return entries
        .where((entry) => entry.transactionId == transactionId)
        .toList(growable: false);
  }

  @override
  Future<void> deleteEntriesByTransactionId(String transactionId) async {
    entries.removeWhere((entry) => entry.transactionId == transactionId);
  }
}
