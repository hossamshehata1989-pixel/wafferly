import 'package:wafferly/core/money/money.dart';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:wafferly/bootstrap/financial_engine_bootstrap.dart';
import 'package:wafferly/core/planning/infrastructure/repositories/memory_allocation_repository.dart';
import 'package:wafferly/core/planning/services/available_balance_projection_service.dart';
import 'package:wafferly/financial_engine/commands/expense/expense_intent.dart';
import 'package:wafferly/financial_engine/commands/shared/transaction_metadata.dart';
import 'package:wafferly/financial_engine/execution_context/execution_context.dart';
import 'package:wafferly/financial_engine/operations/expense_operation.dart';
import 'package:wafferly/financial_engine/results/operation_result.dart';
import 'package:wafferly/models/account.dart';
import 'package:wafferly/models/enums/account_enums.dart';
import 'package:wafferly/models/enums/entry_type.dart';
import 'package:wafferly/models/enums/ledger_account_type.dart';
import 'package:wafferly/models/enums/ledger_purpose.dart';
import 'package:wafferly/constants/transaction_constants.dart';
import 'package:wafferly/models/ledger_account.dart';
import 'package:wafferly/models/ledger_entry.dart';
import 'package:wafferly/models/transaction.dart';
import 'package:wafferly/services/balance_service.dart';
import 'package:wafferly/services/ledger_account_seeder.dart';

void main() {
  late Directory testDirectory;
  late Box<Transaction> transactionBox;
  late Box<Account> accountsBox;
  late Box<LedgerEntry> ledgerBox;
  late Box<LedgerAccount> ledgerAccountsBox;
  late Box<Map> idempotencyBox;

  setUpAll(() async {
    testDirectory = await Directory.systemTemp.createTemp(
      'wafferly_durable_idempotency_test_',
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
    ledgerAccountsBox = await Hive.openBox<LedgerAccount>('ledger_accounts');
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
    final allocationRepository = MemoryAllocationRepository();
    return BalanceService(
      availableBalanceProjectionService: AvailableBalanceProjectionService(
        allocationRepository: allocationRepository,
      ),
    );
  }

  ExpenseOperation buildOperation(String key) {
    return ExpenseOperation(
      intent: ExpenseIntent(
        sourceAccountId: 'wallet',
        categoryId: 'dailyTransport',
        amount: Money.fromDouble(100),
        isExceptional: false,
      ),
      metadata: TransactionMetadata(
        occurredAt: DateTime(2026, 1, 1),
        paymentMethod: 'cash',
        currencyCode: 'EGP',
      ),
      context: ExecutionContext(idempotencyKey: key),
    );
  }

  test('durable idempotency survives engine recreation', () async {
    final firstContext = FinancialEngineBootstrap.create(
      balanceService: buildBalanceService(),
      transactionBox: transactionBox,
      idempotencyBox: idempotencyBox,
    );

    const executionContext = ExecutionContext(
      idempotencyKey: 'durable-restart-key',
    );
    final operation = buildOperation(executionContext.idempotencyKey);

    final firstResult = await firstContext.engine.execute(
      operation,
      executionContext,
    );

    expect(firstResult, isA<OperationSucceeded>());
    expect(transactionBox.values.where((t) => t.type == TransactionType.expense),
        hasLength(1));
    expect(idempotencyBox.containsKey('durable-restart-key'), isTrue);

    await idempotencyBox.close();
    idempotencyBox = await Hive.openBox<Map>('financial_idempotency_test');

    final secondContext = FinancialEngineBootstrap.create(
      balanceService: buildBalanceService(),
      transactionBox: transactionBox,
      idempotencyBox: idempotencyBox,
    );

    final secondResult = await secondContext.engine.execute(
      operation,
      executionContext,
    );

    expect(secondResult, isA<OperationSucceeded>());
    expect(identical(firstResult, secondResult), isFalse);
    expect(transactionBox.values.where((t) => t.type == TransactionType.expense),
        hasLength(1));
  });

  test('failed execution is not durably remembered', () async {
    final context = FinancialEngineBootstrap.create(
      balanceService: buildBalanceService(),
      transactionBox: transactionBox,
      idempotencyBox: idempotencyBox,
    );

    const key = 'retry-after-failure-key';

    final failingOperation = ExpenseOperation(
      intent: ExpenseIntent(
        sourceAccountId: 'wallet',
        categoryId: 'dailyTransport',
        // Negative amounts are rejected by the Expense domain guard.
        // This gives the test a deterministic OperationFailed result rather
        // than relying on a category mapping fallback or confirmation flow.
        amount: Money.fromDouble(-100),
        isExceptional: false,
      ),
      metadata: TransactionMetadata(
        occurredAt: DateTime(2026, 1, 1),
        paymentMethod: 'cash',
        currencyCode: 'EGP',
      ),
      context: const ExecutionContext(idempotencyKey: key),
    );

    final failed = await context.engine.execute(
      failingOperation,
      const ExecutionContext(idempotencyKey: key),
    );

    expect(failed, isA<OperationFailed>());
    expect(idempotencyBox.containsKey(key), isFalse);

    final valid = await context.engine.execute(
      buildOperation(key),
      const ExecutionContext(idempotencyKey: key),
    );

    expect(valid, isA<OperationSucceeded>());
    expect(idempotencyBox.containsKey(key), isTrue);
    expect(transactionBox.values.where((t) => t.type == TransactionType.expense),
        hasLength(1));
  });
}
