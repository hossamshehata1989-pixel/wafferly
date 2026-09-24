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
  late Box<Map> traceabilityBox;

  setUpAll(() async {
    testDirectory = await Directory.systemTemp.createTemp(
      'wafferly_traceability_test_',
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
    accountsBox = await Hive.openBox<Account>('accounts');
    ledgerBox = await Hive.openBox<LedgerEntry>('ledger_entries');
    ledgerAccountsBox = await Hive.openBox<LedgerAccount>('ledger_accounts');
    traceabilityBox = await Hive.openBox<Map>('financial_traceability_test');
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
    await traceabilityBox.clear();

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
        type: 'initial_balance',
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
      intent: const ExpenseIntent(
        sourceAccountId: 'wallet',
        categoryId: 'dailyTransport',
        amount: 100,
        isExceptional: false,
        actorMemberId: 'member-42',
      ),
      metadata: TransactionMetadata(
        occurredAt: DateTime(2026, 1, 1),
        paymentMethod: 'cash',
        currencyCode: 'EGP',
      ),
      context: ExecutionContext(
        idempotencyKey: key,
        actorMemberId: 'member-42',
        source: 'manual',
        commandType: 'ExpenseCommand',
      ),
    );
  }

  test('successful execution creates durable trace with financial links', () async {
    final context = FinancialEngineBootstrap.create(
      balanceService: buildBalanceService(),
      transactionBox: transactionBox,
      traceabilityBox: traceabilityBox,
    );

    const key = 'trace-success-key';
    final executionContext = ExecutionContext(
      idempotencyKey: key,
      actorMemberId: 'member-42',
      source: 'manual',
      commandType: 'ExpenseCommand',
    );

    final result = await context.engine.execute(
      buildOperation(key),
      executionContext,
    );

    expect(result, isA<OperationSucceeded>());
    expect(traceabilityBox, hasLength(1));

    final trace = context.traceabilityPort;
    final records = await trace.findByIdempotencyKey(key);
    expect(records, hasLength(1));
    expect(records.single.status, 'succeeded');
    expect(records.single.operationType, 'ExpenseCommand');
    expect(records.single.actorMemberId, 'member-42');
    expect(records.single.source, 'manual');
    expect(records.single.transactionIds, hasLength(1));
    expect(records.single.mutationIds, isNotEmpty);
  });

  test('failed execution is traced without becoming financial truth', () async {
    final context = FinancialEngineBootstrap.create(
      balanceService: buildBalanceService(),
      transactionBox: transactionBox,
      traceabilityBox: traceabilityBox,
    );

    const key = 'trace-failure-key';
    final executionContext = ExecutionContext(
      idempotencyKey: key,
      source: 'manual',
      commandType: 'ExpenseCommand',
    );

    final operation = ExpenseOperation(
      intent: const ExpenseIntent(
        sourceAccountId: 'wallet',
        categoryId: 'dailyTransport',
        amount: -100,
        isExceptional: false,
      ),
      metadata: TransactionMetadata(
        occurredAt: DateTime(2026, 1, 1),
        paymentMethod: 'cash',
        currencyCode: 'EGP',
      ),
      context: executionContext,
    );

    final result = await context.engine.execute(operation, executionContext);

    expect(result, isA<OperationFailed>());
    expect(transactionBox.values.where((t) => t.type == 'expense'), isEmpty);

    final records = await context.traceabilityPort.findByIdempotencyKey(key);
    expect(records, hasLength(1));
    expect(records.single.status, 'failed');
    expect(records.single.error, isNotNull);
    expect(records.single.transactionIds, isEmpty);
  });

  test('trace survives Hive adapter recreation', () async {
    final firstContext = FinancialEngineBootstrap.create(
      balanceService: buildBalanceService(),
      transactionBox: transactionBox,
      traceabilityBox: traceabilityBox,
    );

    const key = 'trace-restart-key';
    final executionContext = ExecutionContext(
      idempotencyKey: key,
      actorMemberId: 'member-42',
      source: 'manual',
      commandType: 'ExpenseCommand',
    );

    final result = await firstContext.engine.execute(
      buildOperation(key),
      executionContext,
    );
    expect(result, isA<OperationSucceeded>());

    await traceabilityBox.close();
    traceabilityBox = await Hive.openBox<Map>('financial_traceability_test');

    final secondContext = FinancialEngineBootstrap.create(
      balanceService: buildBalanceService(),
      transactionBox: transactionBox,
      traceabilityBox: traceabilityBox,
    );

    final records = await secondContext.traceabilityPort
        .findByIdempotencyKey(key);
    expect(records, hasLength(1));
    expect(records.single.status, 'succeeded');
  });
}
