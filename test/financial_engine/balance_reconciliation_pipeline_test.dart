import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:wafferly/bootstrap/financial_engine_bootstrap.dart';
import 'package:wafferly/bootstrap/financial_engine_context.dart';
import 'package:wafferly/core/planning/infrastructure/repositories/memory_allocation_repository.dart';
import 'package:wafferly/core/planning/services/available_balance_projection_service.dart';
import 'package:wafferly/financial_engine/commands/balance_reconciliation/balance_reconciliation_intent.dart';
import 'package:wafferly/financial_engine/commands/balance_reconciliation/reconciliation_reason.dart';
import 'package:wafferly/financial_engine/commands/shared/transaction_metadata.dart';
import 'package:wafferly/financial_engine/execution_context/execution_context.dart';
import 'package:wafferly/financial_engine/operations/balance_reconciliation_operation.dart';
import 'package:wafferly/financial_engine/planning/chart_of_accounts.dart';
import 'package:wafferly/financial_engine/results/operation_result.dart';
import 'package:wafferly/models/account.dart';
import 'package:wafferly/models/enums/account_enums.dart';
import 'package:wafferly/models/enums/entry_type.dart';
import 'package:wafferly/models/enums/ledger_purpose.dart';
import 'package:wafferly/models/ledger_entry.dart';
import 'package:wafferly/models/transaction.dart';
import 'package:wafferly/constants/transaction_constants.dart';
import 'package:wafferly/services/balance_service.dart';
import 'package:wafferly/services/ledger_projection_service.dart';

void main() {
  late Directory testDirectory;
  late Box<Transaction> transactionBox;
  late Box<LedgerEntry> ledgerBox;
  late Box<Account> accountsBox;

  setUpAll(() async {
    testDirectory = await Directory.systemTemp.createTemp(
      'wafferly_balance_reconciliation_test_',
    );

    Hive.init(testDirectory.path);

    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(AccountAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(AccountNatureAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(AccountGroupAdapter());
    if (!Hive.isAdapterRegistered(10)) Hive.registerAdapter(TransactionAdapter());
    if (!Hive.isAdapterRegistered(20)) Hive.registerAdapter(EntryTypeAdapter());
    if (!Hive.isAdapterRegistered(21)) Hive.registerAdapter(LedgerPurposeAdapter());
    if (!Hive.isAdapterRegistered(22)) Hive.registerAdapter(LedgerEntryAdapter());

    transactionBox = await Hive.openBox<Transaction>('transactions');
    ledgerBox = await Hive.openBox<LedgerEntry>('ledger_entries');
    accountsBox = await Hive.openBox<Account>('accounts');
  });

  tearDownAll(() async {
    await Hive.close();
    if (await testDirectory.exists()) {
      await testDirectory.delete(recursive: true);
    }
  });

  setUp(() async {
    await transactionBox.clear();
    await ledgerBox.clear();
    await accountsBox.clear();
  });

  Future<void> seedAccount(
    String id, {
    AccountNature nature = AccountNature.asset,
  }) async {
    await accountsBox.put(
      id,
      Account(
        id: id,
        bookId: 'default',
        memberId: 'owner',
        name: id,
        type: 'test',
        nature: nature,
        currency: 'EGP',
        createdAt: DateTime(2026, 1, 1),
        group: nature == AccountNature.liability
            ? AccountGroup.liabilities
            : AccountGroup.liquidity,
      ),
    );
  }

  Future<void> seedBalance({
    required String accountId,
    required double amount,
    required AccountNature nature,
  }) async {
    await transactionBox.put(
      'seed-$accountId',
      Transaction(
        id: 'seed-$accountId',
        amount: amount,
        type: TransactionType.initialBalance,
        toAccountId: nature == AccountNature.asset ? accountId : null,
        fromAccountId: nature == AccountNature.liability ? accountId : null,
        date: DateTime(2026, 1, 1),
        paymentMethod: 'cash',
        currencyCode: 'EGP',
      ),
    );
  }

  final occurredAt = DateTime(2026, 9, 24);

  FinancialEngineContext buildContext() {
    final allocationRepository = MemoryAllocationRepository();
    final balanceProjection = AvailableBalanceProjectionService(
      allocationRepository: allocationRepository,
    );
    final balanceService = BalanceService(
      availableBalanceProjectionService: balanceProjection,
    );

    return FinancialEngineBootstrap.create(
      balanceService: balanceService,
      transactionBox: transactionBox,
      allocationRepository: allocationRepository,
    );
  }

  BalanceReconciliationOperation operation({
    required String accountId,
    required double systemBalance,
    required double observedBalance,
    required bool isLiability,
    required String idempotencyKey,
  }) {
    final context = ExecutionContext(idempotencyKey: idempotencyKey);

    return BalanceReconciliationOperation(
      intent: BalanceReconciliationIntent(
        accountId: accountId,
        systemBalance: systemBalance,
        observedBalance: observedBalance,
        isLiability: isLiability,
        reason: ReconciliationReason.cashCountDifference,
      ),
      metadata: TransactionMetadata(
        occurredAt: occurredAt,
        note: 'Reconciliation test',
        paymentMethod: 'cash',
        currencyCode: 'EGP',
      ),
      context: context,
    );
  }

  test('asset reconciliation increases balance through a balanced journal', () async {
    await seedAccount('wallet');
    await seedBalance(
      accountId: 'wallet',
      amount: 8500,
      nature: AccountNature.asset,
    );

    final context = buildContext();
    final executionContext = const ExecutionContext(
      idempotencyKey: 'asset-plus',
    );

    final result = await context.engine.execute(
      operation(
        accountId: 'wallet',
        systemBalance: 8500,
        observedBalance: 10000,
        isLiability: false,
        idempotencyKey: executionContext.idempotencyKey,
      ),
      executionContext,
    );

    expect(result, isA<OperationSucceeded>());
    expect(transactionBox.length, 2);
    expect(
      transactionBox.values.where(
        (t) => t.type == TransactionType.balanceReconciliation,
      ),
      hasLength(1),
    );

    final reconciliation = transactionBox.values
        .firstWhere((t) => t.type == TransactionType.balanceReconciliation);
    expect(reconciliation.amount, 1500);
    expect(reconciliation.fromAccountId, ChartOfAccounts.balanceReconciliationEquityAccountId);
    expect(reconciliation.toAccountId, 'wallet');

    final entries = ledgerBox.values
        .where((e) => e.transactionId == 'reconciliation-asset-plus')
        .toList();
    expect(entries, hasLength(2));
    expect(entries.firstWhere((e) => e.accountId == 'wallet').entryType, EntryType.debit);
    expect(entries.firstWhere((e) => e.accountId == ChartOfAccounts.balanceReconciliationEquityAccountId).entryType, EntryType.credit);
    expect(entries.every((e) => e.purpose == LedgerPurpose.adjustment), isTrue);
    expect(BalanceService().getBalance('wallet'), 10000);
  });

  test('asset reconciliation decrease debits reconciliation equity and credits the account', () async {
    await seedAccount('wallet');
    await seedBalance(
      accountId: 'wallet',
      amount: 10000,
      nature: AccountNature.asset,
    );

    final context = buildContext();
    const executionContext = ExecutionContext(
      idempotencyKey: 'asset-minus',
    );

    final result = await context.engine.execute(
      operation(
        accountId: 'wallet',
        systemBalance: 10000,
        observedBalance: 8500,
        isLiability: false,
        idempotencyKey: executionContext.idempotencyKey,
      ),
      executionContext,
    );

    expect(result, isA<OperationSucceeded>());
    final reconciliation = transactionBox.values
        .firstWhere((t) => t.type == TransactionType.balanceReconciliation);
    expect(reconciliation.fromAccountId, 'wallet');
    expect(reconciliation.toAccountId, ChartOfAccounts.balanceReconciliationEquityAccountId);
    expect(BalanceService().getBalance('wallet'), 8500);
  });

  test('liability reconciliation uses liability nature for debit/credit semantics', () async {
    await seedAccount('loan', nature: AccountNature.liability);
    await seedBalance(
      accountId: 'loan',
      amount: 1000,
      nature: AccountNature.liability,
    );

    final context = buildContext();
    const executionContext = ExecutionContext(
      idempotencyKey: 'liability-plus',
    );

    final result = await context.engine.execute(
      operation(
        accountId: 'loan',
        systemBalance: -1000,
        observedBalance: -1300,
        isLiability: true,
        idempotencyKey: executionContext.idempotencyKey,
      ),
      executionContext,
    );

    expect(result, isA<OperationSucceeded>());
    final reconciliation = transactionBox.values
        .firstWhere((t) => t.type == TransactionType.balanceReconciliation);
    expect(reconciliation.fromAccountId, 'loan');
    expect(reconciliation.toAccountId, ChartOfAccounts.balanceReconciliationEquityAccountId);

    final journalEntries = ledgerBox.values
        .where((entry) => entry.transactionId == reconciliation.id)
        .toList();
    expect(journalEntries, hasLength(2));
    expect(
      journalEntries.any(
        (entry) =>
            entry.accountId == 'loan' && entry.entryType == EntryType.credit,
      ),
      isTrue,
    );
    expect(
      journalEntries.any(
        (entry) =>
            entry.accountId == ChartOfAccounts.balanceReconciliationEquityAccountId &&
            entry.entryType == EntryType.debit,
      ),
      isTrue,
    );
    expect(BalanceService().getBalance('loan'), -1300);
  });

  test('liability reconciliation decrease debits the liability and credits equity', () async {
    await seedAccount('loan', nature: AccountNature.liability);
    await seedBalance(
      accountId: 'loan',
      amount: 1000,
      nature: AccountNature.liability,
    );

    final context = buildContext();
    const executionContext = ExecutionContext(
      idempotencyKey: 'liability-minus',
    );

    final result = await context.engine.execute(
      operation(
        accountId: 'loan',
        systemBalance: -1000,
        observedBalance: -700,
        isLiability: true,
        idempotencyKey: executionContext.idempotencyKey,
      ),
      executionContext,
    );

    expect(result, isA<OperationSucceeded>());
    final reconciliation = transactionBox.values
        .firstWhere((t) => t.type == TransactionType.balanceReconciliation);
    expect(reconciliation.fromAccountId, ChartOfAccounts.balanceReconciliationEquityAccountId);
    expect(reconciliation.toAccountId, 'loan');

    final journalEntries = ledgerBox.values
        .where((entry) => entry.transactionId == reconciliation.id)
        .toList();
    expect(journalEntries, hasLength(2));
    expect(
      journalEntries.any(
        (entry) =>
            entry.accountId == 'loan' && entry.entryType == EntryType.debit,
      ),
      isTrue,
    );
    expect(
      journalEntries.any(
        (entry) =>
            entry.accountId == ChartOfAccounts.balanceReconciliationEquityAccountId &&
            entry.entryType == EntryType.credit,
      ),
      isTrue,
    );
    expect(BalanceService().getBalance('loan'), -700);
  });

  test('zero difference is rejected before planning', () async {
    await seedAccount('wallet');
    await seedBalance(
      accountId: 'wallet',
      amount: 1000,
      nature: AccountNature.asset,
    );

    final context = buildContext();
    const executionContext = ExecutionContext(
      idempotencyKey: 'zero-difference',
    );

    final result = await context.engine.execute(
      operation(
        accountId: 'wallet',
        systemBalance: 1000,
        observedBalance: 1000,
        isLiability: false,
        idempotencyKey: executionContext.idempotencyKey,
      ),
      executionContext,
    );

    expect(result, isA<DomainViolationResult>());
    expect(transactionBox.length, 1);
    expect(ledgerBox.length, 0);
  });

  test('replaying the same reconciliation is idempotent', () async {
    await seedAccount('wallet');
    await seedBalance(
      accountId: 'wallet',
      amount: 1000,
      nature: AccountNature.asset,
    );

    final context = buildContext();
    const executionContext = ExecutionContext(
      idempotencyKey: 'reconciliation-idempotency',
    );
    final op = operation(
      accountId: 'wallet',
      systemBalance: 1000,
      observedBalance: 1200,
      isLiability: false,
      idempotencyKey: executionContext.idempotencyKey,
    );

    final first = await context.engine.execute(op, executionContext);
    final second = await context.engine.execute(op, executionContext);

    expect(first, isA<OperationSucceeded>());
    expect(second, isA<OperationSucceeded>());
    expect(transactionBox.length, 2);
    expect(ledgerBox.values.where(
      (e) => e.transactionId == 'reconciliation-reconciliation-idempotency',
    ), hasLength(2));
    expect(BalanceService().getBalance('wallet'), 1200);
  });
}
