import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:wafferly/bootstrap/financial_engine_bootstrap.dart';
import 'package:wafferly/bootstrap/financial_engine_context.dart';
import 'package:wafferly/core/planning/infrastructure/repositories/memory_allocation_repository.dart';
import 'package:wafferly/core/planning/services/available_balance_projection_service.dart';
import 'package:wafferly/financial_engine/commands/correction/delete_transaction_command.dart';
import 'package:wafferly/financial_engine/commands/correction/deletion_transaction_intent.dart';
import 'package:wafferly/financial_engine/commands/shared/transaction_metadata.dart';
import 'package:wafferly/financial_engine/execution_context/execution_context.dart';
import 'package:wafferly/financial_engine/operations/deletion_operation.dart';
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
import 'package:wafferly/services/transaction_service.dart';

void main() {
  late Directory testDirectory;
  late Box<Transaction> transactionBox;
  late Box<Map> invalidationBox;
  late Box<LedgerEntry> ledgerBox;
  late Box<Account> accountsBox;
  late Box<LedgerAccount> ledgerAccountsBox;

  setUpAll(() async {
    testDirectory = await Directory.systemTemp.createTemp(
      'wafferly_deletion_pipeline_test_',
    );

    Hive.init(testDirectory.path);

    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(AccountAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(AccountNatureAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(AccountGroupAdapter());
    if (!Hive.isAdapterRegistered(10)) Hive.registerAdapter(TransactionAdapter());
    if (!Hive.isAdapterRegistered(20)) Hive.registerAdapter(EntryTypeAdapter());
    if (!Hive.isAdapterRegistered(21)) Hive.registerAdapter(LedgerPurposeAdapter());
    if (!Hive.isAdapterRegistered(22)) Hive.registerAdapter(LedgerEntryAdapter());
    if (!Hive.isAdapterRegistered(30)) Hive.registerAdapter(LedgerAccountTypeAdapter());
    if (!Hive.isAdapterRegistered(31)) Hive.registerAdapter(LedgerAccountAdapter());

    transactionBox = await Hive.openBox<Transaction>('transactions');
    invalidationBox = await Hive.openBox<Map>('financial_invalidations');
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
    await invalidationBox.clear();
    await ledgerBox.clear();
    await accountsBox.clear();
  });

  Future<void> seedAccount(String id) async {
    await accountsBox.put(
      id,
      Account(
        id: id,
        bookId: 'default',
        memberId: 'owner',
        name: id,
        type: 'wallet',
        nature: AccountNature.asset,
        currency: 'EGP',
        createdAt: DateTime(2026, 1, 1),
        group: AccountGroup.values.first,
      ),
    );
  }

  Future<void> seedTransaction(Transaction tx) async {
    await transactionBox.put(tx.id, tx);
    await LedgerProjectionService().project(tx);
  }

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
      invalidationBox: invalidationBox,
      allocationRepository: allocationRepository,
    );
  }

  test('expense deletion preserves original truth and reverses ledger', () async {
    await seedAccount('wallet');
    await transactionBox.put(
      'opening-delete-expense',
      Transaction(
        id: 'opening-delete-expense',
        amount: 1000,
        type: TransactionType.initialBalance,
        toAccountId: 'wallet',
        date: DateTime(2026, 1, 1),
        paymentMethod: 'cash',
        currencyCode: 'EGP',
      ),
    );

    final original = Transaction(
      id: 'delete-expense-original',
      amount: 100,
      type: TransactionType.expense,
      fromAccountId: 'wallet',
      categoryId: 'dailyTransport',
      date: DateTime(2026, 1, 2),
      paymentMethod: 'cash',
      currencyCode: 'EGP',
    );
    await seedTransaction(original);

    final context = buildContext();
    final executionContext = const ExecutionContext(
      idempotencyKey: 'delete-expense-test',
    );

    final result = await context.engine.execute(
      buildDeleteOperation(original, executionContext),
      executionContext,
    );

    expect(result, isA<OperationSucceeded>());
    expect(transactionBox.get(original.id), isNotNull);
    expect(invalidationBox.length, 1);
    expect(
      invalidationBox.get('invalidation-delete-expense-test')!['originalTransactionId'],
      original.id,
    );

    final entries = ledgerBox.values
        .where((e) => e.transactionId == 'invalidation-delete-expense-test')
        .toList();
    expect(entries, hasLength(2));
    expect(entries.every((e) => e.purpose == LedgerPurpose.adjustment), isTrue);
    expect(
      entries.fold<double>(
        0,
        (sum, e) => sum + (e.entryType == EntryType.debit ? e.amount : -e.amount),
      ),
      0,
    );

    final balance = BalanceService().getBalance('wallet');
    expect(balance, 1000);
    expect(
      TransactionService.instance.getById(original.id),
      isNull,
    );
  });

  test('income deletion preserves original truth and reverses income effect', () async {
    await seedAccount('wallet-income');

    final original = Transaction(
      id: 'delete-income-original',
      amount: 500,
      type: TransactionType.income,
      toAccountId: 'wallet-income',
      categoryId: 'salary',
      date: DateTime(2026, 1, 2),
      paymentMethod: 'cash',
      currencyCode: 'EGP',
    );
    await seedTransaction(original);

    final context = buildContext();
    final executionContext = const ExecutionContext(
      idempotencyKey: 'delete-income-test',
    );

    final result = await context.engine.execute(
      buildDeleteOperation(original, executionContext),
      executionContext,
    );

    expect(result, isA<OperationSucceeded>());
    expect(transactionBox.get(original.id), isNotNull);
    expect(invalidationBox.length, 1);
    expect(
      ledgerBox.values
          .where((e) => e.transactionId == 'invalidation-delete-income-test'),
      hasLength(2),
    );
    expect(BalanceService().getBalance('wallet-income'), 0);
  });

  test('transfer deletion preserves original truth and reverses both sides', () async {
    await seedAccount('wallet-from');
    await seedAccount('wallet-to');

    final original = Transaction(
      id: 'delete-transfer-original',
      amount: 300,
      type: TransactionType.transfer,
      fromAccountId: 'wallet-from',
      toAccountId: 'wallet-to',
      date: DateTime(2026, 1, 2),
      paymentMethod: 'cash',
      currencyCode: 'EGP',
    );
    await seedTransaction(original);

    final context = buildContext();
    final executionContext = const ExecutionContext(
      idempotencyKey: 'delete-transfer-test',
    );

    final result = await context.engine.execute(
      buildDeleteOperation(original, executionContext),
      executionContext,
    );

    expect(result, isA<OperationSucceeded>());
    expect(transactionBox.get(original.id), isNotNull);
    expect(invalidationBox.length, 1);

    final entries = ledgerBox.values
        .where((e) => e.transactionId == 'invalidation-delete-transfer-test')
        .toList();
    expect(entries, hasLength(2));
    expect(
      entries.where((e) => e.accountId == 'wallet-from'),
      hasLength(1),
    );
    expect(
      entries.where((e) => e.accountId == 'wallet-to'),
      hasLength(1),
    );
  });

  test('deletion is idempotent and does not duplicate invalidation projection', () async {
    await seedAccount('wallet-idempotent');
    await transactionBox.put(
      'opening-delete-idempotent',
      Transaction(
        id: 'opening-delete-idempotent',
        amount: 1000,
        type: TransactionType.initialBalance,
        toAccountId: 'wallet-idempotent',
        date: DateTime(2026, 1, 1),
        paymentMethod: 'cash',
        currencyCode: 'EGP',
      ),
    );

    final original = Transaction(
      id: 'delete-idempotent-original',
      amount: 100,
      type: TransactionType.expense,
      fromAccountId: 'wallet-idempotent',
      categoryId: 'dailyTransport',
      date: DateTime(2026, 1, 2),
      paymentMethod: 'cash',
      currencyCode: 'EGP',
    );
    await seedTransaction(original);

    final context = buildContext();
    final executionContext = const ExecutionContext(
      idempotencyKey: 'delete-idempotency-test',
    );

    final first = await context.engine.execute(
      buildDeleteOperation(original, executionContext),
      executionContext,
    );
    final second = await context.engine.execute(
      buildDeleteOperation(original, executionContext),
      executionContext,
    );

    expect(first, isA<OperationSucceeded>());
    expect(second, isA<OperationSucceeded>());
    expect(invalidationBox.length, 1);
    expect(
      ledgerBox.values
          .where((e) => e.transactionId == 'invalidation-delete-idempotency-test'),
      hasLength(2),
    );
  });

  test('deletion failure rolls back invalidation and leaves original truth untouched', () async {
    await seedAccount('wallet-rollback');
    await transactionBox.put(
      'opening-delete-rollback',
      Transaction(
        id: 'opening-delete-rollback',
        amount: 1000,
        type: TransactionType.initialBalance,
        toAccountId: 'wallet-rollback',
        date: DateTime(2026, 1, 1),
        paymentMethod: 'cash',
        currencyCode: 'EGP',
      ),
    );

    final original = Transaction(
      id: 'delete-rollback-original',
      amount: 100,
      type: TransactionType.expense,
      fromAccountId: 'wallet-rollback',
      categoryId: 'notMapped',
      date: DateTime(2026, 1, 2),
      paymentMethod: 'cash',
      currencyCode: 'EGP',
    );
    await transactionBox.put(original.id, original);

    final context = buildContext();
    final executionContext = const ExecutionContext(
      idempotencyKey: 'delete-rollback-test',
    );

    final result = await context.engine.execute(
      buildDeleteOperation(original, executionContext),
      executionContext,
    );

    expect(result, isA<OperationFailed>());
    expect(transactionBox.get(original.id), isNotNull);
    expect(invalidationBox.length, 0);
    expect(
      ledgerBox.values
          .where((e) => e.transactionId == 'invalidation-delete-rollback-test'),
      isEmpty,
    );
  });
}

DeleteOperation buildDeleteOperation(
  Transaction transaction,
  ExecutionContext executionContext,
) {
  return DeleteOperation(
    intent: DeleteTransactionIntent(transaction: transaction),
    metadata: TransactionMetadata(
      occurredAt: transaction.date,
      note: transaction.note,
      paymentMethod: transaction.paymentMethod,
      currencyCode: transaction.currencyCode,
    ),
    context: executionContext,
  );
}
