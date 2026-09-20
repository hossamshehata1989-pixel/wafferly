import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:wafferly/bootstrap/financial_engine_bootstrap.dart';
import 'package:wafferly/core/planning/bootstrap/planning_engine_bootstrap.dart';
import 'package:wafferly/core/planning/infrastructure/repositories/memory_allocation_repository.dart';
import 'package:wafferly/core/planning/operations/reserve_operation.dart';
import 'package:wafferly/core/planning/value_objects/planning_source_type.dart';
import 'package:wafferly/core/planning/value_objects/allocation_status.dart';
import 'package:wafferly/core/planning/services/available_balance_projection_service.dart';
import 'package:wafferly/financial_engine/commands/shared/transaction_metadata.dart';
import 'package:wafferly/financial_engine/execution_context/execution_context.dart';
import 'package:wafferly/financial_engine/operations/goal_transfer_operation.dart';
import 'package:wafferly/financial_engine/resolution/resolution.dart';
import 'package:wafferly/financial_engine/results/operation_result.dart';
import 'package:wafferly/models/account.dart';
import 'package:wafferly/models/enums/account_enums.dart';
import 'package:wafferly/models/enums/entry_type.dart';
import 'package:wafferly/models/enums/ledger_purpose.dart';
import 'package:wafferly/models/enums/ledger_account_type.dart';
import 'package:wafferly/models/goal_activity.dart';
import 'package:wafferly/models/ledger_account.dart';
import 'package:wafferly/models/ledger_entry.dart';
import 'package:wafferly/models/transaction.dart';
import 'package:wafferly/constants/transaction_constants.dart';
import 'package:wafferly/services/balance_service.dart';
import 'package:wafferly/services/ledger_account_seeder.dart';
import 'package:wafferly/core/money/money.dart';
void main() {
  late Directory testDirectory;
  late Box<Transaction> transactionBox;
  late Box<Account> accountsBox;
  late Box<LedgerEntry> ledgerBox;
  late Box<GoalActivity> goalActivitiesBox;

  setUpAll(() async {
    testDirectory = await Directory.systemTemp.createTemp(
      'wafferly_goal_transfer_pipeline_test_',
    );

    Hive.init(testDirectory.path);

    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(AccountAdapter());
    }
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
    if (!Hive.isAdapterRegistered(90)) {
      Hive.registerAdapter(GoalActivityAdapter());
    }

    transactionBox = await Hive.openBox<Transaction>('transactions');
    accountsBox = await Hive.openBox<Account>('accounts');
    ledgerBox = await Hive.openBox<LedgerEntry>('ledger_entries');
    await Hive.openBox<LedgerAccount>('ledger_accounts');
    goalActivitiesBox = await Hive.openBox<GoalActivity>('goal_activities');

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
    await goalActivitiesBox.clear();
    await Hive.box<LedgerAccount>('ledger_accounts').clear();

    await accountsBox.put(
      'cash',
      Account(
        id: 'cash',
        bookId: 'default',
        memberId: 'owner',
        name: 'Cash',
        type: 'wallet',
        nature: AccountNature.asset,
        currency: 'EGP',
        createdAt: DateTime(2026, 1, 1),
        group: AccountGroup.values.first,
      ),
    );

    await accountsBox.put(
      'saving',
      Account(
        id: 'saving',
        bookId: 'default',
        memberId: 'owner',
        name: 'Savings',
        type: 'savings',
        nature: AccountNature.asset,
        currency: 'EGP',
        createdAt: DateTime(2026, 1, 1),
        group: AccountGroup.values.first,
      ),
    );

    await transactionBox.put(
      'initial-cash-balance',
      Transaction(
        id: 'initial-cash-balance',
        amount: 1000,
        type: TransactionType.initialBalance,
        toAccountId: 'cash',
        date: DateTime(2026, 1, 1),
        paymentMethod: 'cash',
        currencyCode: 'EGP',
      ),
    );
  });

  test(
    'Goal transfer reaches the Financial Engine pipeline',
    () async {
      final planningAllocationRepository = MemoryAllocationRepository();

      final availableBalanceProjectionService =
          AvailableBalanceProjectionService(
        allocationRepository: planningAllocationRepository,
      );

      final balanceService = BalanceService(
        availableBalanceProjectionService: availableBalanceProjectionService,
      );

      final context = FinancialEngineBootstrap.create(
        balanceService: balanceService,
        transactionBox: transactionBox,
        allocationRepository: planningAllocationRepository,
      );

      // Create the reservation in the same Planning repository that the
      // Financial Engine will later use for ReleaseAllocationMutation.
      final planningEngine = PlanningEngineBootstrap.create(
        allocationRepository: planningAllocationRepository,
      );

      await planningEngine.execute(
        ReserveOperation(
          id: 'reserve-goal-1',
          createdAt: DateTime(2026, 1, 1),
          sourceId: 'goal-1',
          sourceType: PlanningSourceType.goal,
          accountId: 'cash',
amount: Money.fromDouble(500),        ),
      );

      const executionContext = ExecutionContext(
        idempotencyKey: 'goal-transfer-test',
      );

      final occurredAt = DateTime(2026, 1, 2);

      final operation = GoalTransferOperation(
        sourceAccountId: 'cash',
        savingsAccountId: 'saving',
        goalId: 'goal-1',
        amount: 500,
        metadata: TransactionMetadata(
          occurredAt: occurredAt,
          paymentMethod: 'cash',
          currencyCode: 'EGP',
          note: 'Transfer to goal savings',
        ),
        context: executionContext,
        resolution: Resolution.execute,
      );

      final result = await context.engine.execute(
        operation,
        executionContext,
      );

      expect(result, isA<OperationSucceeded>());

      final allocation =
          await planningAllocationRepository.findActiveBySource('goal-1');
      expect(allocation, isNull);

      final allocations =
          await planningAllocationRepository.findBySource('goal-1');
      expect(allocations, hasLength(1));
      expect(allocations.single.status, AllocationStatus.released);

      final transactions = transactionBox.values.toList();
      expect(
        transactions.where((tx) => tx.id != 'initial-cash-balance').length,
        1,
      );

      final transfer = transactions.firstWhere(
        (tx) => tx.id != 'initial-cash-balance',
      );
      expect(transfer.type, TransactionType.transfer);
      expect(transfer.fromAccountId, 'cash');
      expect(transfer.toAccountId, 'saving');
      expect(transfer.amount, 500);

      expect(context.repository.entries.length, 1);
      final journal = context.repository.entries.single;
      expect(journal.lines.length, 2);
      expect(journal.lines.first.debit, 500);
      expect(journal.lines.last.credit, 500);

      expect(goalActivitiesBox.values.length, 1);
      final activity = goalActivitiesBox.values.single;
      expect(activity.goalId, 'goal-1');
      expect(activity.type, GoalActivityType.transferToSaving);
      expect(activity.amount, 500);
    },
  );
}

