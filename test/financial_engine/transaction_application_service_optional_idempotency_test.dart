import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:wafferly/bootstrap/financial_engine_bootstrap.dart';
import 'package:wafferly/core/planning/infrastructure/repositories/memory_allocation_repository.dart';
import 'package:wafferly/core/planning/services/available_balance_projection_service.dart';
import 'package:wafferly/constants/transaction_constants.dart';
import 'package:wafferly/models/account.dart';
import 'package:wafferly/models/enums/account_enums.dart';
import 'package:wafferly/models/enums/entry_type.dart';
import 'package:wafferly/models/enums/ledger_account_type.dart';
import 'package:wafferly/models/enums/ledger_purpose.dart';
import 'package:wafferly/models/ledger_account.dart';
import 'package:wafferly/models/ledger_entry.dart';
import 'package:wafferly/models/transaction.dart';
import 'package:wafferly/financial_engine/results/operation_result.dart';
import 'package:wafferly/services/balance_service.dart';
import 'package:wafferly/services/ledger_account_seeder.dart';
import 'package:wafferly/services/transaction_application_service.dart';
import 'package:wafferly/services/transaction_query_service.dart';

void main() {
  late Directory testDirectory;
  late Box<Transaction> transactionBox;
  late Box<Account> accountsBox;
  late Box<LedgerEntry> ledgerBox;
  late Box<Map> idempotencyBox;

  setUpAll(() async {
    testDirectory = await Directory.systemTemp.createTemp(
      'wafferly_application_idempotency_test_',
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
await Hive.openBox<LedgerAccount>('ledger_accounts');
    idempotencyBox = await Hive.openBox<Map>('financial_idempotency_test');
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

  BalanceService buildBalanceService() {
    return BalanceService(
      availableBalanceProjectionService: AvailableBalanceProjectionService(
        allocationRepository: MemoryAllocationRepository(),
      ),
    );
  }

  test(
    'KNOWN_BUG: addExpense without a key can create a second movement on retry',
    () async {
      final engineContext = FinancialEngineBootstrap.create(
        balanceService: buildBalanceService(),
        transactionBox: transactionBox,
        idempotencyBox: idempotencyBox,
      );
      final applicationService = TransactionApplicationService(
        engine: engineContext.engine,
        transactionQueryService: const TransactionQueryService(),
      );

      final firstResult = await applicationService.addExpense(
        sourceAccountId: 'wallet',
        amount: 100,
        categoryId: 'dailyTransport',
        occurredAt: DateTime(2026, 1, 2),
        isExceptional: false,
      );

      // The service derives the key from milliseconds. Separate the calls so
      // this characterization does not depend on how quickly the test runs.
      await Future<void>.delayed(const Duration(milliseconds: 5));

      final secondResult = await applicationService.addExpense(
        sourceAccountId: 'wallet',
        amount: 100,
        categoryId: 'dailyTransport',
        occurredAt: DateTime(2026, 1, 2),
        isExceptional: false,
      );

      expect(firstResult, isA<OperationSucceeded>());
      expect(secondResult, isA<OperationSucceeded>());
      expect(
        transactionBox.values.where((transaction) =>
            transaction.type == TransactionType.expense),
        hasLength(2),
      );
      expect(idempotencyBox.length, 2);
    },
  );
}
