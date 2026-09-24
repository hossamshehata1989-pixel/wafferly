import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:wafferly/bootstrap/financial_engine_bootstrap.dart';
import 'package:wafferly/core/money/money.dart';
import 'package:wafferly/core/planning/infrastructure/repositories/memory_allocation_repository.dart';
import 'package:wafferly/core/planning/services/available_balance_projection_service.dart';
import 'package:wafferly/financial_engine/commands/correction/correction_intent.dart';
import 'package:wafferly/financial_engine/commands/shared/transaction_metadata.dart';
import 'package:wafferly/financial_engine/domain/financial_transaction_record.dart';
import 'package:wafferly/financial_engine/execution_context/execution_context.dart';
import 'package:wafferly/financial_engine/operations/correction_financial_operation.dart';
import 'package:wafferly/financial_engine/results/operation_result.dart';
import 'package:wafferly/models/account.dart';
import 'package:wafferly/models/enums/account_enums.dart';
import 'package:wafferly/models/enums/entry_type.dart';
import 'package:wafferly/models/enums/ledger_account_type.dart';
import 'package:wafferly/models/enums/ledger_purpose.dart';
import 'package:wafferly/models/ledger_account.dart';
import 'package:wafferly/models/ledger_entry.dart';
import 'package:wafferly/constants/transaction_constants.dart';
import 'package:wafferly/models/transaction.dart';
import 'package:wafferly/services/balance_service.dart';
import 'package:wafferly/services/ledger_account_seeder.dart';
import 'package:wafferly/services/ledger_projection_service.dart';

void main() {
  late Directory testDirectory;
  late Box<Transaction> transactionBox;
  late Box<Map> correctionBox;
  late Box<LedgerEntry> ledgerBox;
  late Box<Account> accountsBox;
  late Box<LedgerAccount> ledgerAccountsBox;

  setUpAll(() async {
    testDirectory = await Directory.systemTemp.createTemp(
      'wafferly_correction_pipeline_test_',
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
    if (!Hive.isAdapterRegistered(20)) {
      Hive.registerAdapter(EntryTypeAdapter());
    }
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
    correctionBox = await Hive.openBox<Map>('financial_corrections');
    ledgerBox = await Hive.openBox<LedgerEntry>('ledger_entries');
    accountsBox = await Hive.openBox<Account>('accounts');
    ledgerAccountsBox = await Hive.openBox<LedgerAccount>('ledger_accounts');

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
    await correctionBox.clear();
    await ledgerBox.clear();
    await accountsBox.clear();
  });

  test('expense correction preserves before truth and projects reversal + after', () async {
    final allocationRepository = MemoryAllocationRepository();
    final balanceProjection = AvailableBalanceProjectionService(
      allocationRepository: allocationRepository,
    );
    final balanceService = BalanceService(
      availableBalanceProjectionService: balanceProjection,
    );

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
      'opening',
      Transaction(
        id: 'opening',
        amount: 1000,
        type: TransactionType.initialBalance,
        toAccountId: 'wallet',
        date: DateTime(2026, 1, 1),
        paymentMethod: 'cash',
        currencyCode: 'EGP',
      ),
    );

    final before = FinancialTransactionRecord(
      transactionId: 'tx-1',
      type: TransactionType.expense,
      fromAccountId: 'wallet',
      categoryId: 'dailyTransport',
      amount: Money.fromDouble(100),
      currencyCode: 'EGP',
      paymentMethod: 'cash',
      occurredAt: DateTime(2026, 1, 2),
      isExceptional: false,
      source: 'manual',
    );

    final original = Transaction(
      id: before.transactionId,
      amount: 100,
      type: TransactionType.expense,
      fromAccountId: 'wallet',
      categoryId: 'dailyTransport',
      date: before.occurredAt,
      paymentMethod: 'cash',
      currencyCode: 'EGP',
    );

    await transactionBox.put(original.id, original);
    await LedgerProjectionService().project(original);

    final after = FinancialTransactionRecord(
      transactionId: 'tx-1',
      type: TransactionType.expense,
      fromAccountId: 'wallet',
      categoryId: 'dailyTransport',
      amount: Money.fromDouble(150),
      currencyCode: 'EGP',
      paymentMethod: 'cash',
      occurredAt: DateTime(2026, 1, 2),
      isExceptional: false,
      source: 'manual',
    );

    final context = FinancialEngineBootstrap.create(
      balanceService: balanceService,
      transactionBox: transactionBox,
      correctionBox: correctionBox,
      allocationRepository: allocationRepository,
    );

    const executionContext = ExecutionContext(
      idempotencyKey: 'correction-expense-test',
    );

    final result = await context.engine.execute(
      buildCorrectionOperation(
        before: before,
        after: after,
        executionContext: executionContext,
      ),
      executionContext,
    );

    expect(result, isA<OperationSucceeded>());
    expect(transactionBox.get('tx-1')!.amount, 100);
    expect(transactionBox.get('corrected-correction-correction-expense-test')!.amount, 150);
    expect(transactionBox.length, 3);
    expect(correctionBox.length, 1);

    final correctionEntries = ledgerBox.values
        .where((entry) => entry.transactionId == 'correction-correction-expense-test')
        .toList();

    expect(correctionEntries.length, 4);
    expect(
      correctionEntries.where((entry) => entry.purpose == LedgerPurpose.adjustment),
      hasLength(2),
    );

    final expenseEntries = correctionEntries
        .where((entry) => entry.accountId != 'wallet')
        .toList();
    expect(expenseEntries.fold<double>(
      0,
      (sum, entry) => sum + (entry.entryType == EntryType.debit ? entry.amount : -entry.amount),
    ), 50);

    final persistedCorrection = correctionBox.get(
      'correction-correction-expense-test',
    )!;
    expect(persistedCorrection['originalTransactionId'], 'tx-1');
    expect(
      (persistedCorrection['before'] as Map)['transactionId'],
      'tx-1',
    );
    expect(
      (persistedCorrection['after'] as Map)['transactionId'],
      'corrected-correction-correction-expense-test',
    );
  });

  test('replaying the same correction is idempotent', () async {
    final allocationRepository = MemoryAllocationRepository();
    final balanceProjection = AvailableBalanceProjectionService(
      allocationRepository: allocationRepository,
    );
    final balanceService = BalanceService(
      availableBalanceProjectionService: balanceProjection,
    );

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
      'opening-idempotent',
      Transaction(
        id: 'opening-idempotent',
        amount: 1000,
        type: TransactionType.initialBalance,
        toAccountId: 'wallet',
        date: DateTime(2026, 1, 1),
        paymentMethod: 'cash',
        currencyCode: 'EGP',
      ),
    );

    await transactionBox.put(
      'tx-idempotent-original',
      Transaction(
        id: 'tx-idempotent-original',
        amount: 100,
        type: TransactionType.expense,
        fromAccountId: 'wallet',
        categoryId: 'dailyTransport',
        date: DateTime(2026, 1, 2),
        paymentMethod: 'cash',
        currencyCode: 'EGP',
      ),
    );

    final before = FinancialTransactionRecord(
      transactionId: 'tx-idempotent-original',
      type: TransactionType.expense,
      fromAccountId: 'wallet',
      categoryId: 'dailyTransport',
      amount: Money.fromDouble(100),
      currencyCode: 'EGP',
      paymentMethod: 'cash',
      occurredAt: DateTime(2026, 1, 2),
      isExceptional: false,
      source: 'manual',
    );

    final after = FinancialTransactionRecord(
      transactionId: 'tx-idempotent-original',
      type: TransactionType.expense,
      fromAccountId: 'wallet',
      categoryId: 'dailyTransport',
      amount: Money.fromDouble(120),
      currencyCode: 'EGP',
      paymentMethod: 'cash',
      occurredAt: DateTime(2026, 1, 2),
      isExceptional: false,
      source: 'manual',
    );

    // Test precondition: policy must see enough available balance so this
    // test reaches the idempotency boundary rather than stopping for confirmation.
    expect(balanceService.getBalance('wallet'), 900);

    final context = FinancialEngineBootstrap.create(
      balanceService: balanceService,
      transactionBox: transactionBox,
      correctionBox: correctionBox,
      allocationRepository: allocationRepository,
    );

    const executionContext = ExecutionContext(
      idempotencyKey: 'correction-idempotency-test',
    );

    final operation = buildCorrectionOperation(
      before: before,
      after: after,
      executionContext: executionContext,
    );

    final first = await context.engine.execute(operation, executionContext);
    expect(first, isA<OperationSucceeded>());

    final transactionCountAfterFirst = transactionBox.length;
    final correctionCountAfterFirst = correctionBox.length;
    final ledgerCountAfterFirst = ledgerBox.length;

    final second = await context.engine.execute(operation, executionContext);
    expect(second, isA<OperationSucceeded>());
    expect(transactionBox.length, transactionCountAfterFirst);
    expect(correctionBox.length, correctionCountAfterFirst);
    expect(ledgerBox.length, ledgerCountAfterFirst);
  });

  test('correction failure rolls back correction and corrected truth', () async {
    final allocationRepository = MemoryAllocationRepository();
    final balanceProjection = AvailableBalanceProjectionService(
      allocationRepository: allocationRepository,
    );
    final balanceService = BalanceService(
      availableBalanceProjectionService: balanceProjection,
    );

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
      'opening-rollback',
      Transaction(
        id: 'opening-rollback',
        amount: 1000,
        type: TransactionType.initialBalance,
        toAccountId: 'wallet',
        date: DateTime(2026, 1, 1),
        paymentMethod: 'cash',
        currencyCode: 'EGP',
      ),
    );

    final original = Transaction(
      id: 'tx-rollback-original',
      amount: 100,
      type: TransactionType.expense,
      fromAccountId: 'wallet',
      categoryId: 'dailyTransport',
      date: DateTime(2026, 1, 2),
      paymentMethod: 'cash',
      currencyCode: 'EGP',
    );
    await transactionBox.put(original.id, original);
    await LedgerProjectionService().project(original);

    final before = FinancialTransactionRecord(
      transactionId: original.id,
      type: TransactionType.expense,
      fromAccountId: 'wallet',
      categoryId: 'dailyTransport',
      amount: Money.fromDouble(100),
      currencyCode: 'EGP',
      paymentMethod: 'cash',
      occurredAt: DateTime(2026, 1, 2),
      isExceptional: false,
      source: 'manual',
    );

    // The invalid category is deliberately chosen so that planning succeeds
    // but the projection layer rejects the corrected truth after the
    // correction and transaction have already been persisted.
    final after = FinancialTransactionRecord(
      transactionId: original.id,
      type: TransactionType.expense,
      fromAccountId: 'wallet',
      categoryId: 'notMapped',
      amount: Money.fromDouble(150),
      currencyCode: 'EGP',
      paymentMethod: 'cash',
      occurredAt: DateTime(2026, 1, 2),
      isExceptional: false,
      source: 'manual',
    );

    // Test precondition: the request must pass policy so the deliberately
    // broken projection can exercise executor rollback.
    expect(balanceService.getBalance('wallet'), 900);

    final context = FinancialEngineBootstrap.create(
      balanceService: balanceService,
      transactionBox: transactionBox,
      correctionBox: correctionBox,
      allocationRepository: allocationRepository,
    );

    const executionContext = ExecutionContext(
      idempotencyKey: 'correction-rollback-test',
    );

    final result = await context.engine.execute(
      buildCorrectionOperation(
        before: before,
        after: after,
        executionContext: executionContext,
      ),
      executionContext,
    );

    expect(result, isA<OperationFailed>());
    expect(transactionBox.get(original.id)!.amount, 100);
    expect(
      transactionBox.get('corrected-correction-correction-rollback-test'),
      isNull,
    );
    expect(correctionBox.isEmpty, isTrue);
    expect(ledgerBox.length, 2);
  });


  test('income correction preserves before truth and projects reversal + after', () async {
    final allocationRepository = MemoryAllocationRepository();
    final balanceProjection = AvailableBalanceProjectionService(
      allocationRepository: allocationRepository,
    );
    final balanceService = BalanceService(
      availableBalanceProjectionService: balanceProjection,
    );

    await accountsBox.put(
      'wallet-income',
      Account(
        id: 'wallet-income',
        bookId: 'default',
        memberId: 'owner',
        name: 'Income Wallet',
        type: 'wallet',
        nature: AccountNature.asset,
        currency: 'EGP',
        createdAt: DateTime(2026, 1, 1),
        group: AccountGroup.values.first,
      ),
    );

    // Seed unrelated available balance so the correction test exercises
    // correction semantics rather than the insufficient-balance policy.
    final balanceSeed = Transaction(
      id: 'income-balance-seed',
      amount: 1000,
      type: TransactionType.income,
      toAccountId: 'wallet-income',
      categoryId: 'salary',
      date: DateTime(2026, 1, 1),
      paymentMethod: 'bank',
      currencyCode: 'EGP',
    );
    await transactionBox.put(balanceSeed.id, balanceSeed);
    await LedgerProjectionService().project(balanceSeed);

    final original = Transaction(
      id: 'tx-income-original',
      amount: 500,
      type: TransactionType.income,
      toAccountId: 'wallet-income',
      categoryId: 'salary',
      date: DateTime(2026, 1, 2),
      paymentMethod: 'bank',
      currencyCode: 'EGP',
    );
    await transactionBox.put(original.id, original);
    await LedgerProjectionService().project(original);

    final before = FinancialTransactionRecord(
      transactionId: original.id,
      type: TransactionType.income,
      toAccountId: 'wallet-income',
      categoryId: 'salary',
      amount: Money.fromDouble(500),
      currencyCode: 'EGP',
      paymentMethod: 'bank',
      occurredAt: original.date,
      isExceptional: false,
      source: 'manual',
    );
    final after = FinancialTransactionRecord(
      transactionId: original.id,
      type: TransactionType.income,
      toAccountId: 'wallet-income',
      categoryId: 'salary',
      amount: Money.fromDouble(650),
      currencyCode: 'EGP',
      paymentMethod: 'bank',
      occurredAt: original.date,
      isExceptional: false,
      source: 'manual',
    );

    final context = FinancialEngineBootstrap.create(
      balanceService: balanceService,
      transactionBox: transactionBox,
      correctionBox: correctionBox,
      allocationRepository: allocationRepository,
    );
    const executionContext = ExecutionContext(
      idempotencyKey: 'correction-income-test',
    );

    final result = await context.engine.execute(
      buildCorrectionOperation(
        before: before,
        after: after,
        executionContext: executionContext,
      ),
      executionContext,
    );

    expect(result, isA<OperationSucceeded>());
    expect(transactionBox.get(original.id)!.amount, 500);
    expect(
      transactionBox.get('corrected-correction-correction-income-test')!.amount,
      650,
    );

    final entries = ledgerBox.values
        .where((entry) => entry.transactionId == 'correction-correction-income-test')
        .toList();
    expect(entries, hasLength(4));
    expect(
      entries.where((entry) => entry.purpose == LedgerPurpose.adjustment),
      hasLength(2),
    );

    final incomeEntries = entries.where((entry) => entry.accountId != 'wallet-income');
    expect(
      incomeEntries.fold<double>(
        0,
        (sum, entry) => sum + (entry.entryType == EntryType.credit ? entry.amount : -entry.amount),
      ),
      150,
    );
  });

  test('transfer correction preserves before truth and projects reversal + after', () async {
    final allocationRepository = MemoryAllocationRepository();
    final balanceProjection = AvailableBalanceProjectionService(
      allocationRepository: allocationRepository,
    );
    final balanceService = BalanceService(
      availableBalanceProjectionService: balanceProjection,
    );

    await accountsBox.put(
      'wallet-from',
      Account(
        id: 'wallet-from',
        bookId: 'default',
        memberId: 'owner',
        name: 'From Wallet',
        type: 'wallet',
        nature: AccountNature.asset,
        currency: 'EGP',
        createdAt: DateTime(2026, 1, 1),
        group: AccountGroup.values.first,
      ),
    );
    await accountsBox.put(
      'wallet-to',
      Account(
        id: 'wallet-to',
        bookId: 'default',
        memberId: 'owner',
        name: 'To Wallet',
        type: 'wallet',
        nature: AccountNature.asset,
        currency: 'EGP',
        createdAt: DateTime(2026, 1, 1),
        group: AccountGroup.values.first,
      ),
    );

    await transactionBox.put(
      'opening-transfer',
      Transaction(
        id: 'opening-transfer',
        amount: 1000,
        type: TransactionType.initialBalance,
        toAccountId: 'wallet-from',
        date: DateTime(2026, 1, 1),
        paymentMethod: 'cash',
        currencyCode: 'EGP',
      ),
    );

    final original = Transaction(
      id: 'tx-transfer-original',
      amount: 300,
      type: TransactionType.transfer,
      fromAccountId: 'wallet-from',
      toAccountId: 'wallet-to',
      date: DateTime(2026, 1, 2),
      paymentMethod: 'cash',
      currencyCode: 'EGP',
    );
    await transactionBox.put(original.id, original);
    await LedgerProjectionService().project(original);

    final before = FinancialTransactionRecord(
      transactionId: original.id,
      type: TransactionType.transfer,
      fromAccountId: 'wallet-from',
      toAccountId: 'wallet-to',
      amount: Money.fromDouble(300),
      currencyCode: 'EGP',
      paymentMethod: 'cash',
      occurredAt: original.date,
      isExceptional: false,
      source: 'manual',
    );
    final after = FinancialTransactionRecord(
      transactionId: original.id,
      type: TransactionType.transfer,
      fromAccountId: 'wallet-from',
      toAccountId: 'wallet-to',
      amount: Money.fromDouble(450),
      currencyCode: 'EGP',
      paymentMethod: 'cash',
      occurredAt: original.date,
      isExceptional: false,
      source: 'manual',
    );

    final context = FinancialEngineBootstrap.create(
      balanceService: balanceService,
      transactionBox: transactionBox,
      correctionBox: correctionBox,
      allocationRepository: allocationRepository,
    );
    const executionContext = ExecutionContext(
      idempotencyKey: 'correction-transfer-test',
    );

    final result = await context.engine.execute(
      buildCorrectionOperation(
        before: before,
        after: after,
        executionContext: executionContext,
      ),
      executionContext,
    );

    expect(result, isA<OperationSucceeded>());
    expect(transactionBox.get(original.id)!.amount, 300);
    expect(
      transactionBox.get('corrected-correction-correction-transfer-test')!.amount,
      450,
    );

    final entries = ledgerBox.values
        .where((entry) => entry.transactionId == 'correction-correction-transfer-test')
        .toList();
    expect(entries, hasLength(4));
    expect(
      entries.where((entry) => entry.purpose == LedgerPurpose.adjustment),
      hasLength(2),
    );

    final fromEntries = entries.where((entry) => entry.accountId == 'wallet-from').toList();
    final toEntries = entries.where((entry) => entry.accountId == 'wallet-to').toList();
    expect(fromEntries, hasLength(2));
    expect(toEntries, hasLength(2));
    expect(
      fromEntries.fold<double>(
        0,
        (sum, entry) => sum + (entry.entryType == EntryType.debit ? entry.amount : -entry.amount),
      ),
      -150,
    );
    expect(
      toEntries.fold<double>(
        0,
        (sum, entry) => sum + (entry.entryType == EntryType.debit ? entry.amount : -entry.amount),
      ),
      150,
    );
  });
}

/// Test helper that builds the real production operation.
CorrectionOperation buildCorrectionOperation({
  required FinancialTransactionRecord before,
  required FinancialTransactionRecord after,
  required ExecutionContext executionContext,
}) {
  return CorrectionOperation(
    intent: CorrectionIntent(
      transactionId: before.transactionId,
      before: before,
      after: after,
    ),
    metadata: TransactionMetadata(
      occurredAt: after.occurredAt,
      paymentMethod: after.paymentMethod,
      currencyCode: after.currencyCode,
    ),
    context: executionContext,
  );
}
