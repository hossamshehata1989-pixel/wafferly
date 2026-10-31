import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:wafferly/bootstrap/financial_engine_bootstrap.dart';
import 'package:wafferly/constants/transaction_constants.dart';
import 'package:wafferly/controllers/transaction_entry_controller.dart';
import 'package:wafferly/core/planning/infrastructure/repositories/memory_allocation_repository.dart';
import 'package:wafferly/core/planning/services/available_balance_projection_service.dart';
import 'package:wafferly/financial_engine/execution/financial_execution_summary.dart';
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

/// Captures the idempotency key passed by the controller and injects one
/// transient failure before delegating subsequent attempts to the real engine.
class _FailOnceExpenseTransactionApplicationService
    extends TransactionApplicationService {
  _FailOnceExpenseTransactionApplicationService({
    required super.engine,
    required super.transactionQueryService,
  });

  final List<String> expenseIdempotencyKeys = <String>[];
  bool _failNextExpense = true;

  @override
  Future<OperationResult> addExpense({
    required String sourceAccountId,
    required double amount,
    required String categoryId,
    required DateTime occurredAt,
    required bool isExceptional,
    String? actorMemberId,
    String? note,
    required String idempotencyKey,
  }) async {
    expenseIdempotencyKeys.add(idempotencyKey);

    if (_failNextExpense) {
      _failNextExpense = false;
      return const OperationFailed(error: 'Injected transient failure');
    }

    return super.addExpense(
      sourceAccountId: sourceAccountId,
      amount: amount,
      categoryId: categoryId,
      occurredAt: occurredAt,
      isExceptional: isExceptional,
      actorMemberId: actorMemberId,
      note: note,
      idempotencyKey: idempotencyKey,
    );
  }
}

class _FailOnceCreditCardChargeTransactionApplicationService
    extends TransactionApplicationService {
  _FailOnceCreditCardChargeTransactionApplicationService({
    required super.engine,
    required super.transactionQueryService,
  });

  final List<String> creditCardChargeIdempotencyKeys = <String>[];
  bool _failNextCreditCardCharge = true;

  @override
  Future<OperationResult> addCreditCardCharge({
    required String creditCardAccountId,
    required double amount,
    required String categoryId,
    String? subCategoryId,
    required DateTime occurredAt,
    required String currencyCode,
    String? note,
    String? actorMemberId,
    required String idempotencyKey,
    bool isExceptional = false,
  }) async {
    creditCardChargeIdempotencyKeys.add(idempotencyKey);

    if (_failNextCreditCardCharge) {
      _failNextCreditCardCharge = false;
      return const OperationFailed(
        error: 'Injected transient card-charge failure',
      );
    }

    return const OperationSucceeded(
      summary: FinancialExecutionSummary(
        createdTransactionIds: <String>['credit-card-charge-test-id'],
        balanceChanges: <String, double>{},
        createdMutationIds: <String>[],
      ),
    );
  }
}

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
    await accountsBox.put(
      'savings',
      Account(
        id: 'savings',
        bookId: 'default',
        memberId: 'owner',
        name: 'Savings',
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

  TransactionApplicationService buildApplicationService() {
    final engineContext = FinancialEngineBootstrap.create(
      balanceService: buildBalanceService(),
      transactionBox: transactionBox,
      idempotencyBox: idempotencyBox,
    );
    return TransactionApplicationService(
      engine: engineContext.engine,
      transactionQueryService: const TransactionQueryService(),
    );
  }

  _FailOnceExpenseTransactionApplicationService
  buildFailOnceExpenseApplicationService() {
    final engineContext = FinancialEngineBootstrap.create(
      balanceService: buildBalanceService(),
      transactionBox: transactionBox,
      idempotencyBox: idempotencyBox,
    );
    return _FailOnceExpenseTransactionApplicationService(
      engine: engineContext.engine,
      transactionQueryService: const TransactionQueryService(),
    );
  }

  _FailOnceCreditCardChargeTransactionApplicationService
  buildFailOnceCreditCardChargeApplicationService() {
    final engineContext = FinancialEngineBootstrap.create(
      balanceService: buildBalanceService(),
      transactionBox: transactionBox,
      idempotencyBox: idempotencyBox,
    );
    return _FailOnceCreditCardChargeTransactionApplicationService(
      engine: engineContext.engine,
      transactionQueryService: const TransactionQueryService(),
    );
  }

  Future<void> seedCreditCardAccount() async {
    await accountsBox.put(
      'card',
      Account(
        id: 'card',
        bookId: 'default',
        memberId: 'owner',
        name: 'Test Card',
        type: 'creditCard',
        nature: AccountNature.liability,
        currency: 'EGP',
        createdAt: DateTime(2026, 1, 1),
        group: AccountGroup.liabilities,
      ),
    );
  }

  int transactionCount(String type) => transactionBox.values
      .where((transaction) => transaction.type == type)
      .length;

  Future<OperationResult> createExpense(
    TransactionApplicationService service, {
    required String key,
    double amount = 100,
  }) {
    return service.addExpense(
      sourceAccountId: 'wallet',
      amount: amount,
      categoryId: 'dailyTransport',
      occurredAt: DateTime(2026, 1, 2),
      isExceptional: false,
      idempotencyKey: key,
    );
  }

  test(
    'addExpense replays the same request with the same required key',
    () async {
      final service = buildApplicationService();

      final first = await createExpense(service, key: 'expense-retry-key');
      final retry = await createExpense(service, key: 'expense-retry-key');

      expect(first, isA<OperationSucceeded>());
      expect(retry, isA<OperationSucceeded>());
      expect(
        (retry as OperationSucceeded).summary.createdTransactionIds,
        (first as OperationSucceeded).summary.createdTransactionIds,
      );
      expect(transactionCount(TransactionType.expense), 1);
      expect(idempotencyBox.length, 1);
    },
  );

  test(
    'same Expense key with a changed amount is rejected without a second write',
    () async {
      final service = buildApplicationService();

      final first = await createExpense(service, key: 'expense-conflict-key');
      final changed = await createExpense(
        service,
        key: 'expense-conflict-key',
        amount: 101,
      );

      expect(first, isA<OperationSucceeded>());
      expect(changed, isA<OperationFailed>());
      expect(transactionCount(TransactionType.expense), 1);
      expect(idempotencyBox.length, 1);
    },
  );

  test(
    'a new Expense key permits an identical intentional second movement',
    () async {
      final service = buildApplicationService();

      final first = await createExpense(service, key: 'expense-intent-one');
      final second = await createExpense(service, key: 'expense-intent-two');

      expect(first, isA<OperationSucceeded>());
      expect(second, isA<OperationSucceeded>());
      expect(transactionCount(TransactionType.expense), 2);
      expect(idempotencyBox.length, 2);
    },
  );

  test(
    'addIncome replays the same request with the same required key',
    () async {
      final service = buildApplicationService();

      Future<OperationResult> addIncome() => service.addIncome(
        sourceAccountId: 'wallet',
        amount: 500,
        categoryId: 'salary',
        occurredAt: DateTime(2026, 1, 2),
        isExceptional: false,
        idempotencyKey: 'income-retry-key',
      );

      final first = await addIncome();
      final retry = await addIncome();

      expect(first, isA<OperationSucceeded>());
      expect(retry, isA<OperationSucceeded>());
      expect(transactionCount(TransactionType.income), 1);
      expect(idempotencyBox.length, 1);
    },
  );

  test(
    'addTransfer replays the same request with the same required key',
    () async {
      final service = buildApplicationService();

      Future<OperationResult> addTransfer() => service.addTransfer(
        fromAccountId: 'wallet',
        toAccountId: 'savings',
        amount: 100,
        occurredAt: DateTime(2026, 1, 2),
        idempotencyKey: 'transfer-retry-key',
      );

      final first = await addTransfer();
      final retry = await addTransfer();

      expect(first, isA<OperationSucceeded>());
      expect(retry, isA<OperationSucceeded>());
      expect(transactionCount(TransactionType.transfer), 1);
      expect(idempotencyBox.length, 1);
    },
  );

  test(
    'a failed expense save reuses the same key when retried unchanged',
    () async {
      final service = buildFailOnceExpenseApplicationService();
      final controller = TransactionEntryController(
        transactionService: service,
      );
      addTearDown(controller.dispose);

      controller.setTransactionType(TransactionType.expense);
      controller.setAmount('100');
      controller.selectAccount('wallet', 'Wallet');
      controller.selectCategory('dailyTransport');

      final failed = await controller.saveEntry();
      expect(failed.success, isFalse);
      expect(service.expenseIdempotencyKeys, hasLength(1));
      expect(
        service.expenseIdempotencyKeys.single,
        startsWith('transaction-entry-'),
      );
      expect(idempotencyBox.length, 0);

      final retry = await controller.saveEntry();

      expect(retry.success, isTrue);
      expect(service.expenseIdempotencyKeys, hasLength(2));
      expect(
        service.expenseIdempotencyKeys[1],
        service.expenseIdempotencyKeys[0],
      );
      expect(transactionCount(TransactionType.expense), 1);
      expect(idempotencyBox.length, 1);
    },
  );

  test('changing an expense draft after failure generates a new key', () async {
    final service = buildFailOnceExpenseApplicationService();
    final controller = TransactionEntryController(transactionService: service);
    addTearDown(controller.dispose);

    controller.setTransactionType(TransactionType.expense);
    controller.setAmount('100');
    controller.selectAccount('wallet', 'Wallet');
    controller.selectCategory('dailyTransport');

    final failed = await controller.saveEntry();
    expect(failed.success, isFalse);
    expect(service.expenseIdempotencyKeys, hasLength(1));

    controller.setAmount('125');
    final retryWithChangedDraft = await controller.saveEntry();

    expect(retryWithChangedDraft.success, isTrue);
    expect(service.expenseIdempotencyKeys, hasLength(2));
    expect(
      service.expenseIdempotencyKeys[1],
      isNot(service.expenseIdempotencyKeys[0]),
    );
    expect(transactionCount(TransactionType.expense), 1);
    expect(idempotencyBox.length, 1);
  });

  test(
    'a failed credit-card charge save reuses the same key when retried unchanged',
    () async {
      await seedCreditCardAccount();
      final service = buildFailOnceCreditCardChargeApplicationService();
      final controller = TransactionEntryController(
        transactionService: service,
      );
      addTearDown(controller.dispose);

      controller.selectAccount('card', 'Test Card');
      controller.setAmount('100');
      controller.selectCategory('dailyTransport');

      final failed = await controller.saveEntry();
      expect(failed.success, isFalse);
      expect(service.creditCardChargeIdempotencyKeys, hasLength(1));
      expect(
        service.creditCardChargeIdempotencyKeys.single,
        startsWith('transaction-credit-card-charge-'),
      );

      final retry = await controller.saveEntry();

      expect(retry.success, isTrue);
      expect(service.creditCardChargeIdempotencyKeys, hasLength(2));
      expect(
        service.creditCardChargeIdempotencyKeys[1],
        service.creditCardChargeIdempotencyKeys[0],
      );
    },
  );

  test(
    'changing a credit-card charge draft after failure generates a new key',
    () async {
      await seedCreditCardAccount();
      final service = buildFailOnceCreditCardChargeApplicationService();
      final controller = TransactionEntryController(
        transactionService: service,
      );
      addTearDown(controller.dispose);

      controller.selectAccount('card', 'Test Card');
      controller.setAmount('100');
      controller.selectCategory('dailyTransport');

      final failed = await controller.saveEntry();
      expect(failed.success, isFalse);
      expect(service.creditCardChargeIdempotencyKeys, hasLength(1));

      controller.setAmount('125');
      final retryWithChangedDraft = await controller.saveEntry();

      expect(retryWithChangedDraft.success, isTrue);
      expect(service.creditCardChargeIdempotencyKeys, hasLength(2));
      expect(
        service.creditCardChargeIdempotencyKeys[1],
        isNot(service.creditCardChargeIdempotencyKeys[0]),
      );
    },
  );

  test('a new entry after a successful save receives a new UUID key', () async {
    final controller = TransactionEntryController(
      transactionService: buildApplicationService(),
    );
    addTearDown(controller.dispose);

    Future<SaveResult> saveSameExpenseDraft() async {
      controller.setTransactionType(TransactionType.expense);
      controller.setAmount('100');
      controller.selectAccount('wallet', 'Wallet');
      controller.selectCategory('dailyTransport');
      return controller.saveEntry();
    }

    final first = await saveSameExpenseDraft();
    expect(first.success, isTrue);
    final firstKeys = idempotencyBox.keys.cast<String>().toList();
    expect(firstKeys, hasLength(1));
    expect(firstKeys.single, startsWith('transaction-entry-'));

    final second = await saveSameExpenseDraft();
    expect(second.success, isTrue);
    final keys = idempotencyBox.keys.cast<String>().toList();
    expect(keys, hasLength(2));
    expect(keys.toSet(), hasLength(2));
    expect(transactionCount(TransactionType.expense), 2);
  });
}
