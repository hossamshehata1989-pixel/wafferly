import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:wafferly/bootstrap/financial_engine_bootstrap.dart';
import 'package:wafferly/bootstrap/financial_engine_context.dart';
import 'package:wafferly/core/money/money.dart';
import 'package:wafferly/core/planning/infrastructure/repositories/memory_allocation_repository.dart';
import 'package:wafferly/credit_card/domain/credit_card_profile.dart';
import 'package:wafferly/credit_card/infrastructure/hive_credit_card_profile_repository.dart';
import 'package:wafferly/financial_engine/commands/credit_card/credit_card_charge_intent.dart';
import 'package:wafferly/financial_engine/commands/shared/transaction_metadata.dart';
import 'package:wafferly/financial_engine/execution_context/execution_context.dart';
import 'package:wafferly/financial_engine/operations/credit_card_charge_operation.dart';
import 'package:wafferly/financial_engine/results/operation_result.dart';
import 'package:wafferly/models/account.dart';
import 'package:wafferly/models/enums/account_enums.dart';
import 'package:wafferly/models/enums/entry_type.dart';
import 'package:wafferly/models/enums/ledger_account_type.dart';
import 'package:wafferly/models/enums/ledger_purpose.dart';
import 'package:wafferly/models/ledger_account.dart';
import 'package:wafferly/models/ledger_entry.dart';
import 'package:wafferly/models/transaction.dart';
import 'package:wafferly/constants/transaction_constants.dart';
import 'package:wafferly/services/balance_service.dart';
import 'package:wafferly/services/ledger_account_seeder.dart';

void main() {
  late Directory testDirectory;
  late Box<Transaction> transactionBox;
  late Box<Account> accountsBox;
  late Box<LedgerEntry> ledgerBox;
  late Box<LedgerAccount> ledgerAccountsBox;
  late Box<CreditCardProfile> profileBox;

  setUpAll(() async {
    testDirectory = await Directory.systemTemp.createTemp(
      'wafferly_credit_card_charge_test_',
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
    if (!Hive.isAdapterRegistered(100)) {
      Hive.registerAdapter(CreditCardProfileAdapter());
    }

    transactionBox = await Hive.openBox<Transaction>('transactions');
    accountsBox = await Hive.openBox<Account>('accounts');
    ledgerBox = await Hive.openBox<LedgerEntry>('ledger_entries');
    ledgerAccountsBox = await Hive.openBox<LedgerAccount>('ledger_accounts');
    profileBox = await Hive.openBox<CreditCardProfile>('credit_card_profiles');
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
    await profileBox.clear();
  });

  Future<void> seedCard({
    required double outstanding,
    double limit = 10000,
  }) async {
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

    await profileBox.put(
      'profile-card',
      CreditCardProfile.fromMoney(
        id: 'profile-card',
        accountId: 'card',
        creditLimit: Money.fromDouble(limit),
      ),
    );

    if (outstanding > 0) {
      await transactionBox.put(
        'opening-card',
        Transaction(
          id: 'opening-card',
          amount: outstanding,
          type: TransactionType.initialBalance,
          fromAccountId: 'card',
          toAccountId: null,
          date: DateTime(2026, 1, 1),
          paymentMethod: 'opening',
          currencyCode: 'EGP',
        ),
      );
    }
  }

  Future<FinancialEngineContext> buildContext() async {
    final allocationRepository = MemoryAllocationRepository();
    final balanceService = BalanceService();

    return FinancialEngineBootstrap.create(
      balanceService: balanceService,
      transactionBox: transactionBox,
      allocationRepository: allocationRepository,
      creditCardProfileRepository: HiveCreditCardProfileRepository(profileBox),
    );
  }

  CreditCardChargeOperation operation({
    required double amount,
    required String idempotencyKey,
  }) {
    return CreditCardChargeOperation(
      intent: CreditCardChargeIntent(
        creditCardAccountId: 'card',
        categoryId: 'dailyTransport',
        amount: Money.fromDouble(amount),
      ),
      metadata: TransactionMetadata(
        occurredAt: DateTime(2026, 9, 26, 10),
        paymentMethod: 'credit_card',
        currencyCode: 'EGP',
        note: 'Card purchase',
      ),
      context: ExecutionContext(idempotencyKey: idempotencyKey),
    );
  }

  test('credit card charge succeeds without cash liquidity', () async {
    await seedCard(outstanding: 7000);
    final context = await buildContext();

    final result = await context.engine.execute(
      operation(amount: 3000, idempotencyKey: 'charge-success'),
      const ExecutionContext(idempotencyKey: 'charge-success'),
    );

    expect(result, isA<OperationSucceeded>());

    final transaction = transactionBox.values.singleWhere(
      (tx) => tx.type == TransactionType.creditCardCharge,
    );
    expect(transaction.fromAccountId, isNull);
    expect(transaction.toAccountId, 'card');
    expect(transaction.amount, 3000);
    expect(transaction.source, TransactionSource.creditCardCharge);

    final balance = BalanceService().getBalance('card');
    expect(balance, -10000);

    final ledgerEntries = ledgerBox.values
        .where((entry) => entry.transactionId == transaction.id)
        .toList();
    expect(ledgerEntries, hasLength(2));
    expect(
      ledgerEntries.any(
        (entry) =>
            entry.accountId == 'card' &&
            entry.entryType == EntryType.credit &&
            entry.purpose == LedgerPurpose.debt,
      ),
      isTrue,
    );
  });

  test('credit card charge rejects when exposure exceeds limit', () async {
    await seedCard(outstanding: 7000);
    final context = await buildContext();

    final result = await context.engine.execute(
      operation(amount: 3001, idempotencyKey: 'charge-over-limit'),
      const ExecutionContext(idempotencyKey: 'charge-over-limit'),
    );

    expect(result, isA<DomainViolationResult>());
    expect(
      transactionBox.values.where(
        (tx) => tx.type == TransactionType.creditCardCharge,
      ),
      isEmpty,
    );
    expect(BalanceService().getBalance('card'), -7000);
  });

  test('credit card charge exactly at remaining limit succeeds', () async {
    await seedCard(outstanding: 7000);
    final context = await buildContext();

    final result = await context.engine.execute(
      operation(amount: 3000, idempotencyKey: 'charge-exact-limit'),
      const ExecutionContext(idempotencyKey: 'charge-exact-limit'),
    );

    expect(result, isA<OperationSucceeded>());
    expect(BalanceService().getBalance('card'), -10000);
  });

  test('zero and negative credit card charges are rejected', () async {
    await seedCard(outstanding: 0);
    final context = await buildContext();

    final zero = await context.engine.execute(
      operation(amount: 0, idempotencyKey: 'charge-zero'),
      const ExecutionContext(idempotencyKey: 'charge-zero'),
    );
    final negative = await context.engine.execute(
      operation(amount: -1, idempotencyKey: 'charge-negative'),
      const ExecutionContext(idempotencyKey: 'charge-negative'),
    );

    expect(zero, isA<DomainViolationResult>());
    expect(negative, isA<DomainViolationResult>());
    expect(transactionBox.values, isEmpty);
  });

  test('same credit card charge is idempotent', () async {
    await seedCard(outstanding: 7000);
    final context = await buildContext();
    final op = operation(amount: 1000, idempotencyKey: 'charge-retry');
    const executionContext = ExecutionContext(idempotencyKey: 'charge-retry');

    final first = await context.engine.execute(op, executionContext);
    final second = await context.engine.execute(op, executionContext);

    expect(first, isA<OperationSucceeded>());
    expect(identical(first, second), isTrue);
    expect(
      transactionBox.values
          .where((tx) => tx.type == TransactionType.creditCardCharge)
          .length,
      1,
    );
    expect(BalanceService().getBalance('card'), -8000);
  });
}
