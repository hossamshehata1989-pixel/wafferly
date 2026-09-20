import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:wafferly/bootstrap/financial_engine_bootstrap.dart';
import 'package:wafferly/core/planning/infrastructure/repositories/memory_allocation_repository.dart';
import 'package:wafferly/core/planning/services/available_balance_projection_service.dart';
import 'package:wafferly/financial_engine/commands/opening_balance/opening_balance_intent.dart';
import 'package:wafferly/financial_engine/commands/shared/transaction_metadata.dart';
import 'package:wafferly/financial_engine/execution_context/execution_context.dart';
import 'package:wafferly/financial_engine/operations/create_goal_allocation_operation.dart';
import 'package:wafferly/financial_engine/operations/opening_balance_operation.dart';
import 'package:wafferly/financial_engine/resolution/resolution.dart';
import 'package:wafferly/financial_engine/results/operation_result.dart';
import 'package:wafferly/models/account.dart';
import 'package:wafferly/models/enums/account_enums.dart';
import 'package:wafferly/models/transaction.dart';
import 'package:wafferly/models/ledger_entry.dart';
import 'package:wafferly/services/balance_service.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'wafferly_goal_allocation_test_',
    );

    Hive.init(tempDir.path);

    Hive.registerAdapter(AccountAdapter());
    Hive.registerAdapter(AccountNatureAdapter());
    Hive.registerAdapter(AccountGroupAdapter());
    Hive.registerAdapter(TransactionAdapter());
Hive.registerAdapter(LedgerEntryAdapter());
    await Hive.openBox<Account>('accounts');
      await Hive.openBox<Transaction>('transactions');

    await Hive.openBox<LedgerEntry>('ledger_entries');
  });

  tearDown(() async {
    await Hive.close();

    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('CreateGoalAllocationOperation executes successfully', () async {
    final transactionBox = Hive.box<Transaction>('transactions');

    // Planning allocation repository used by the available-balance projection.
    final planningAllocationRepository = MemoryAllocationRepository();

    final availableBalanceProjectionService =
        AvailableBalanceProjectionService(
      allocationRepository: planningAllocationRepository,
    );

    final balanceService = BalanceService(
      availableBalanceProjectionService: availableBalanceProjectionService,
    );

    // The FinancialEngineBootstrap creates and owns its own execution
    // allocation repository.
    final context = FinancialEngineBootstrap.create(
      balanceService: balanceService,
      transactionBox: transactionBox,
    );

    // ------------------------------------------------------------
    // Opening Balance
    // ------------------------------------------------------------

    final openingBalanceContext = const ExecutionContext(
      idempotencyKey: 'opening-balance-test-1',
    );

    final openingBalanceOperation = OpeningBalanceOperation(
      intent: const OpeningBalanceIntent(
        accountId: 'cash',
        amount: 1000,
        isLiability: false,
      ),
      metadata: TransactionMetadata(
        occurredAt: DateTime.now(),
        paymentMethod: 'cash',
        currencyCode: 'EGP',
      ),
      context: openingBalanceContext,
      resolution: Resolution.execute,
    );

    final openingBalanceResult = await context.engine.execute(
      openingBalanceOperation,
      openingBalanceContext,
    );

    expect(
      openingBalanceResult,
      isA<OperationSucceeded>(),
    );

    // ------------------------------------------------------------
    // Goal Allocation
    // ------------------------------------------------------------

    final occurredAt = DateTime.now();

    final executionContext = const ExecutionContext(
      idempotencyKey: 'allocation-test-1',
    );

    final operation = CreateGoalAllocationOperation(
      accountId: 'cash',
      goalId: 'goal-1',
      amount: 500,
      occurredAt: occurredAt,
      metadata: TransactionMetadata(
        occurredAt: occurredAt,
        paymentMethod: 'cash',
        currencyCode: 'EGP',
      ),
      context: executionContext,
      resolution: Resolution.execute,
    );

    final result = await context.engine.execute(
      operation,
      executionContext,
    );

    expect(
      result,
      isA<OperationSucceeded>(),
    );

    // The bootstrap-owned allocation repository contains the executed
    // CreateAllocationMutation.
    final allocations =
    await context.allocationRepository.findBySource('goal-1');

expect(allocations, hasLength(1));

final allocation = allocations.single;
    expect(
      allocation.accountId,
      'cash',
    );

   expect(
  allocation.sourceId,
  'goal-1',
);

    expect(
  allocation.amount.toDouble(),
  500,
);
  });
}