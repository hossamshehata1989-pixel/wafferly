import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:wafferly/bootstrap/financial_engine_bootstrap.dart';
import 'package:wafferly/constants/transaction_constants.dart';
import 'package:wafferly/core/planning/services/available_balance_projection_service.dart';
import 'package:wafferly/core/planning/infrastructure/repositories/memory_allocation_repository.dart';
import 'package:wafferly/financial_engine/commands/expense/expense_intent.dart';
import 'package:wafferly/financial_engine/commands/shared/transaction_metadata.dart';
import 'package:wafferly/financial_engine/execution_context/execution_context.dart';
import 'package:wafferly/financial_engine/operations/expense_operation.dart';
import 'package:wafferly/financial_engine/results/operation_result.dart';
import 'package:wafferly/models/account.dart';
import 'package:wafferly/models/enums/account_enums.dart';
import 'package:wafferly/models/transaction.dart';
import 'package:wafferly/services/balance_service.dart';

void main() {
  late Directory testDirectory;
  late Box<Transaction> transactionBox;

  setUpAll(() async {
    testDirectory = await Directory.systemTemp.createTemp(
      'wafferly_financial_engine_test_',
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

    transactionBox = await Hive.openBox<Transaction>('transactions');

    // AccountService is constructed by FinancialEngineBootstrap.
    // Its Hive account box must therefore exist as Box<Account>.
    await Hive.openBox<Account>('accounts');
  });

  tearDownAll(() async {
    await Hive.close();
    await testDirectory.delete(recursive: true);
  });

  setUp(() async {
    await transactionBox.clear();
  });

  test('Expense operation creates one journal entry', () async {
    final allocationRepository = MemoryAllocationRepository();

    final availableBalanceProjectionService =
        AvailableBalanceProjectionService(
      allocationRepository: allocationRepository,
    );

    final balanceService = BalanceService(
      availableBalanceProjectionService: availableBalanceProjectionService,
    );

    // Seed the source account with an opening balance so the
    // BalanceDomainGuard can validate the expense.
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

    final context = FinancialEngineBootstrap.create(
      balanceService: balanceService,
      transactionBox: transactionBox,
    );

    const executionContext = ExecutionContext(
      idempotencyKey: 'expense-test',
    );

    final operation = ExpenseOperation(
      intent: const ExpenseIntent(
        sourceAccountId: 'wallet',
        categoryId: 'transport',
        amount: 50,
        isExceptional: false,
      ),
      metadata: TransactionMetadata(
        occurredAt: DateTime.now(),
        paymentMethod: 'cash',
        currencyCode: 'EGP',
      ),
      context: executionContext,
    );

    final result = await context.engine.execute(
      operation,
      executionContext,
    );

    expect(result, isA<OperationSucceeded>());

    expect(context.repository.entries.length, 1);

    final entry = context.repository.entries.single;

    expect(entry.lines.length, 2);

    final debit = entry.lines.first;
    final credit = entry.lines.last;

    expect(debit.debit, 50);
    expect(credit.credit, 50);
  });
}