import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:wafferly/bootstrap/financial_engine_bootstrap.dart';
import 'package:wafferly/constants/transaction_constants.dart';
import 'package:wafferly/core/planning/infrastructure/repositories/memory_allocation_repository.dart';
import 'package:wafferly/core/planning/services/available_balance_projection_service.dart';
import 'package:wafferly/financial_engine/results/operation_result.dart';
import 'package:wafferly/models/account.dart';
import 'package:wafferly/models/enums/account_enums.dart';
import 'package:wafferly/models/enums/entry_type.dart';
import 'package:wafferly/models/enums/ledger_account_type.dart';
import 'package:wafferly/models/enums/ledger_purpose.dart';
import 'package:wafferly/models/ledger_account.dart';
import 'package:wafferly/models/ledger_entry.dart';
import 'package:wafferly/models/transaction.dart';
import 'package:wafferly/services/balance_service.dart';
import 'package:wafferly/services/ledger_account_seeder.dart';
import 'package:wafferly/services/transaction_application_service.dart';
import 'package:wafferly/services/transaction_query_service.dart';

/// M2.3-B4: Update (Correction) and Delete (Invalidation) must use stable
/// idempotency keys derived from the target transaction identity:
///
///   correction-v1-<transactionId>
///   delete-v1-<transactionId>
///
/// They must not depend on the clock, so a retry of the same request is
/// recognised by the Idempotency Guard.
void main() {
  late Directory testDirectory;
  late Box<Transaction> transactionBox;
  late Box<Account> accountsBox;
  late Box<LedgerEntry> ledgerBox;
  late Box<Map> correctionBox;
  late Box<Map> invalidationBox;
  late Box<Map> idempotencyBox;

  const createKey = 'b4-create-expense-key';

  setUpAll(() async {
    testDirectory = await Directory.systemTemp.createTemp(
      'wafferly_b4_keys_test_',
    );
    Hive.init(testDirectory.path);

    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(AccountAdapter());
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(AccountNatureAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(AccountGroupAdapter());
    }
    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(TransactionAdapter());
    }
    if (!Hive.isAdapterRegistered(20)) Hive.registerAdapter(EntryTypeAdapter());
    if (!Hive.isAdapterRegistered(21)) {
      Hive.registerAdapter(LedgerPurposeAdapter());
    }
    if (!Hive.isAdapterRegistered(22)) {
      Hive.registerAdapter(LedgerEntryAdapter());
    }
    if (!Hive.isAdapterRegistered(30)) {
      Hive.registerAdapter(LedgerAccountTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(31)) {
      Hive.registerAdapter(LedgerAccountAdapter());
    }

    transactionBox = await Hive.openBox<Transaction>('transactions');
    accountsBox = await Hive.openBox<Account>('accounts');
    ledgerBox = await Hive.openBox<LedgerEntry>('ledger_entries');
    // These two names are read directly by the effective-transaction query.
    correctionBox = await Hive.openBox<Map>('financial_corrections');
    invalidationBox = await Hive.openBox<Map>('financial_invalidations');
    idempotencyBox = await Hive.openBox<Map>('financial_idempotency_b4_test');
    await Hive.openBox<LedgerAccount>('ledger_accounts');
    await LedgerAccountSeeder().seedIfNeeded();
  });

  tearDownAll(() async {
    await Hive.close();
    if (await testDirectory.exists()) {
      await testDirectory.delete(recursive: true);
    }
  });

  setUp(() async {
    await transactionBox.clear();
    await accountsBox.clear();
    await ledgerBox.clear();
    await correctionBox.clear();
    await invalidationBox.clear();
    await idempotencyBox.clear();

    await accountsBox.put(
      'wallet',
      Account(
        id: 'wallet',
        bookId: 'default',
        memberId: 'owner',
        name: 'Wallet',
        type: 'wallet',
        nature: AccountNature.asset,
        currency: 'EGP',
        createdAt: DateTime(2026, 1, 1),
        group: AccountGroup.values.first,
      ),
    );
    await transactionBox.put(
      'initial-wallet-balance',
      Transaction(
        id: 'initial-wallet-balance',
        amount: 1000,
        type: TransactionType.initialBalance,
        toAccountId: 'wallet',
        date: DateTime(2026, 1, 1),
        paymentMethod: 'cash',
        currencyCode: 'EGP',
      ),
    );
  });

  TransactionApplicationService buildService() {
    final engineContext = FinancialEngineBootstrap.create(
      balanceService: BalanceService(
        availableBalanceProjectionService: AvailableBalanceProjectionService(
          allocationRepository: MemoryAllocationRepository(),
        ),
      ),
      transactionBox: transactionBox,
      correctionBox: correctionBox,
      invalidationBox: invalidationBox,
      idempotencyBox: idempotencyBox,
    );
    return TransactionApplicationService(
      engine: engineContext.engine,
      transactionQueryService: const TransactionQueryService(),
    );
  }

  /// Creates one expense through the engine and returns its effective record.
  Future<Transaction> createExpense(
    TransactionApplicationService service,
  ) async {
    final result = await service.addExpense(
      sourceAccountId: 'wallet',
      amount: 100,
      categoryId: 'dailyTransport',
      occurredAt: DateTime(2026, 1, 2),
      isExceptional: false,
      idempotencyKey: createKey,
    );
    expect(result, isA<OperationSucceeded>());

    return service
        .getAllTransactions()
        .singleWhere((tx) => tx.type == TransactionType.expense);
  }

  List<Transaction> effectiveExpenses(TransactionApplicationService service) =>
      service
          .getAllTransactions()
          .where((tx) => tx.type == TransactionType.expense)
          .toList();

  test(
    'updateExpense uses the stable key correction-v1-<transactionId>',
    () async {
      final service = buildService();
      final original = await createExpense(service);

      final result = await service.updateExpense(
        original.copyWith(amount: 150),
      );

      expect(result, isA<OperationSucceeded>());
      expect(
        idempotencyBox.keys.toSet(),
        {createKey, 'correction-v1-${original.id}'},
        reason: 'The correction key must not be derived from the clock.',
      );
    },
  );

  test(
    'delete uses the stable key delete-v1-<transactionId>',
    () async {
      final service = buildService();
      final original = await createExpense(service);

      final result = await service.delete(original.id);

      expect(result, isA<OperationSucceeded>());
      expect(
        idempotencyBox.keys.toSet(),
        {createKey, 'delete-v1-${original.id}'},
        reason: 'The delete key must not be derived from the clock.',
      );
      expect(invalidationBox.length, 1);
    },
  );

  test(
    'chained correction targets the effective copy with its own key',
    () async {
      final service = buildService();
      final original = await createExpense(service);

      expect(
        await service.updateExpense(original.copyWith(amount: 150)),
        isA<OperationSucceeded>(),
      );

      final corrected = effectiveExpenses(service).single;
      expect(corrected.id, isNot(original.id));
      expect(corrected.amount, 150);

      expect(
        await service.updateExpense(corrected.copyWith(amount: 175)),
        isA<OperationSucceeded>(),
      );

      final latest = effectiveExpenses(service).single;
      expect(latest.amount, 175);
      expect(
        idempotencyBox.keys.toSet(),
        {
          createKey,
          'correction-v1-${original.id}',
          'correction-v1-${corrected.id}',
        },
      );
    },
  );

  test(
    'a stale request for an already corrected transaction is rejected '
    'before any new write',
    () async {
      final service = buildService();
      final original = await createExpense(service);

      expect(
        await service.updateExpense(original.copyWith(amount: 150)),
        isA<OperationSucceeded>(),
      );
      final ledgerCountAfterFirst = ledgerBox.length;
      final correctionCountAfterFirst = correctionBox.length;

      // Characterization: the original is no longer effective, so a second
      // correction for it throws before reaching the engine.
      await expectLater(
        service.updateExpense(original.copyWith(amount: 999)),
        throwsA(anything),
      );

      expect(ledgerBox.length, ledgerCountAfterFirst);
      expect(correctionBox.length, correctionCountAfterFirst);
      expect(effectiveExpenses(service).single.amount, 150);
    },
  );

  test(
    'failed correction can be retried through the application service with '
    'the same derived key and corrected data',
    () async {
      final service = buildService();
      final original = await createExpense(service);
      final correctionKey = 'correction-v1-${original.id}';
      final ledgerCountBefore = ledgerBox.length;

      // The unsupported category has no Ledger mapping. The correction
      // mutation is persisted before projection, so this failure exercises
      // the application service + engine + UnitOfWork rollback path rather
      // than failing during request construction.
      final failed = await service.updateExpense(
        original.copyWith(
          amount: 125,
          categoryId: 'b4-unsupported-category',
        ),
      );

      expect(failed, isA<OperationFailed>());
      expect(
        (failed as OperationFailed).error.toString(),
        contains('Correction projection cannot be empty'),
      );
      expect(correctionBox.isEmpty, isTrue);
      expect(transactionBox.containsKey(original.id), isTrue);
      expect(transactionBox.length, 2); // opening balance + original expense
      expect(service.getById(original.id), isNotNull);
      expect(ledgerBox.length, ledgerCountBefore);
      expect(idempotencyBox.containsKey(correctionKey), isFalse);

      // The service derives the same key from original.id. Because the first
      // attempt failed, the Guard did not persist a success record; a retry
      // with corrected data is therefore allowed under that same key.
      final retried = await service.updateExpense(
        original.copyWith(
          amount: 125,
          categoryId: 'dailyTransport',
        ),
      );

      expect(retried, isA<OperationSucceeded>());
      expect(idempotencyBox.containsKey(correctionKey), isTrue);
      expect(correctionBox.length, 1);
      expect(transactionBox.length, 3);

      final effective = effectiveExpenses(service);
      expect(effective, hasLength(1));
      expect(effective.single.amount, 125);
      expect(effective.single.categoryId, 'dailyTransport');
      expect(ledgerBox.length, ledgerCountBefore + 4);
    },
  );

  test(
    'deleting the same transaction twice does not create a second '
    'invalidation or extra ledger entries',
    () async {
      final service = buildService();
      final original = await createExpense(service);

      expect(await service.delete(original.id), isA<OperationSucceeded>());
      final ledgerCountAfterFirst = ledgerBox.length;

      // Characterization: after invalidation the transaction is no longer
      // effective, so the second request throws before reaching the engine.
      await expectLater(service.delete(original.id), throwsA(anything));

      expect(invalidationBox.length, 1);
      expect(ledgerBox.length, ledgerCountAfterFirst);
      expect(effectiveExpenses(service), isEmpty);
    },
  );
}
