import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:wafferly/bootstrap/financial_engine_bootstrap.dart';
import 'package:wafferly/bootstrap/financial_engine_context.dart';
import 'package:wafferly/core/money/money.dart';
import 'package:wafferly/core/planning/infrastructure/repositories/memory_allocation_repository.dart';
import 'package:wafferly/core/planning/services/available_balance_projection_service.dart';
import 'package:wafferly/credit_card/domain/credit_card_profile.dart';
import 'package:wafferly/credit_card/infrastructure/hive_credit_card_profile_repository.dart';
import 'package:wafferly/financial_engine/commands/shared/transaction_metadata.dart';
import 'package:wafferly/financial_engine/execution_context/execution_context.dart';
import 'package:wafferly/financial_engine/operations/credit_card_payment_operation.dart';
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
      'wafferly_credit_card_payment_test_',
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
    await ledgerAccountsBox.clear();
    await profileBox.clear();
    await LedgerAccountSeeder().seedIfNeeded();

    await accountsBox.put(
      'bank',
      Account(
        id: 'bank',
        bookId: 'default',
        memberId: 'owner',
        name: 'Linked Bank',
        type: 'bank',
        nature: AccountNature.asset,
        currency: 'EGP',
        createdAt: DateTime(2026, 1, 1),
        group: AccountGroup.liquidity,
      ),
    );
    await accountsBox.put(
      'card',
      Account(
        id: 'card',
        bookId: 'default',
        memberId: 'owner',
        name: 'Test Credit Card',
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
        creditLimit: Money.parse('10000'),
        linkedBankAccountId: 'bank',
      ),
    );
    await transactionBox.put(
      'opening-bank',
      Transaction(
        id: 'opening-bank',
        amount: 5000,
        type: TransactionType.initialBalance,
        toAccountId: 'bank',
        date: DateTime(2026, 1, 1),
        paymentMethod: 'opening',
        currencyCode: 'EGP',
      ),
    );
    await transactionBox.put(
      'opening-card',
      Transaction(
        id: 'opening-card',
        amount: 3000,
        type: TransactionType.initialBalance,
        fromAccountId: 'card',
        date: DateTime(2026, 1, 1),
        paymentMethod: 'opening',
        currencyCode: 'EGP',
      ),
    );
  });

  Future<FinancialEngineContext> buildContext() async {
    final allocationRepository = MemoryAllocationRepository();
    final projectionService = AvailableBalanceProjectionService(
      allocationRepository: allocationRepository,
    );
    final balanceService = BalanceService(
      availableBalanceProjectionService: projectionService,
    );
    return FinancialEngineBootstrap.create(
      balanceService: balanceService,
      transactionBox: transactionBox,
      allocationRepository: allocationRepository,
      creditCardProfileRepository: HiveCreditCardProfileRepository(profileBox),
    );
  }

  CreditCardPaymentOperation operation({
    required String sourceId,
    String targetId = 'card',
    required double amount,
    required String idempotencyKey,
    String sourceCurrency = 'EGP',
    String? metadataCurrency,
  }) {
    return CreditCardPaymentOperation(
      sourceAssetAccountId: sourceId,
      creditCardAccountId: targetId,
      amount: Money.fromDouble(amount),
      metadata: TransactionMetadata(
        occurredAt: DateTime(2026, 10, 10, 12),
        paymentMethod: 'account_transfer',
        currencyCode: metadataCurrency ?? sourceCurrency,
        note: 'Credit Card payment',
      ),
      context: ExecutionContext(
        idempotencyKey: idempotencyKey,
        source: 'manual',
        commandType: 'CreditCardPaymentOperation',
      ),
    );
  }

  test('partial payment reduces asset and card liability through the engine', () async {
    final context = await buildContext();
    const execution = ExecutionContext(idempotencyKey: 'cc-payment-partial');

    final result = await context.engine.execute(
      operation(
        sourceId: 'bank',
        amount: 1000,
        idempotencyKey: 'cc-payment-partial',
      ),
      execution,
    );

    expect(result, isA<OperationSucceeded>());
    expect(BalanceService().getBalance('bank'), 4000);
    expect(BalanceService().getBalance('card'), -2000);

    final transaction = transactionBox.values.singleWhere(
      (tx) => tx.source == TransactionSource.creditCardPayment,
    );
    expect(transaction.type, TransactionType.transfer);
    expect(transaction.fromAccountId, 'bank');
    expect(transaction.toAccountId, 'card');
    expect(transaction.amount, 1000);

    final entries = ledgerBox.values
        .where((entry) => entry.transactionId == transaction.id)
        .toList();
    expect(entries, hasLength(2));
    expect(
      entries.any(
        (entry) =>
            entry.accountId == 'card' &&
            entry.entryType == EntryType.debit &&
            entry.purpose == LedgerPurpose.transfer,
      ),
      isTrue,
    );
    expect(
      entries.any(
        (entry) =>
            entry.accountId == 'bank' &&
            entry.entryType == EntryType.credit &&
            entry.purpose == LedgerPurpose.transfer,
      ),
      isTrue,
    );
  });

  test('full payment settles outstanding liability to zero', () async {
    final context = await buildContext();

    final result = await context.engine.execute(
      operation(
        sourceId: 'bank',
        amount: 3000,
        idempotencyKey: 'cc-payment-full',
      ),
      const ExecutionContext(idempotencyKey: 'cc-payment-full'),
    );

    expect(result, isA<OperationSucceeded>());
    expect(BalanceService().getBalance('bank'), 2000);
    expect(BalanceService().getBalance('card'), 0);
  });

  test('payment greater than outstanding is rejected without mutation', () async {
    final context = await buildContext();

    final result = await context.engine.execute(
      operation(
        sourceId: 'bank',
        amount: 3000.01,
        idempotencyKey: 'cc-payment-overpay',
      ),
      const ExecutionContext(idempotencyKey: 'cc-payment-overpay'),
    );

    expect(result, isA<DomainViolationResult>());
    expect(transactionBox.values.where((tx) => tx.source == TransactionSource.creditCardPayment), isEmpty);
    expect(BalanceService().getBalance('bank'), 5000);
    expect(BalanceService().getBalance('card'), -3000);
  });

  test('zero and negative payment are rejected', () async {
    final context = await buildContext();
    final zero = await context.engine.execute(
      operation(sourceId: 'bank', amount: 0, idempotencyKey: 'cc-payment-zero'),
      const ExecutionContext(idempotencyKey: 'cc-payment-zero'),
    );
    final negative = await context.engine.execute(
      operation(sourceId: 'bank', amount: -1, idempotencyKey: 'cc-payment-negative'),
      const ExecutionContext(idempotencyKey: 'cc-payment-negative'),
    );

    expect(zero, isA<DomainViolationResult>());
    expect(negative, isA<DomainViolationResult>());
    expect(transactionBox.values.where((tx) => tx.source == TransactionSource.creditCardPayment), isEmpty);
  });

  test('cross-currency payment is rejected', () async {
    await accountsBox.put(
      'usd-bank',
      Account(
        id: 'usd-bank',
        bookId: 'default',
        memberId: 'owner',
        name: 'USD Bank',
        type: 'bank',
        nature: AccountNature.asset,
        currency: 'USD',
        createdAt: DateTime(2026, 1, 1),
        group: AccountGroup.liquidity,
      ),
    );
    await transactionBox.put(
      'opening-usd-bank',
      Transaction(
        id: 'opening-usd-bank',
        amount: 1000,
        type: TransactionType.initialBalance,
        toAccountId: 'usd-bank',
        date: DateTime(2026, 1, 1),
        paymentMethod: 'opening',
        currencyCode: 'USD',
      ),
    );
    final context = await buildContext();

    final result = await context.engine.execute(
      operation(
        sourceId: 'usd-bank',
        amount: 100,
        sourceCurrency: 'USD',
        idempotencyKey: 'cc-payment-fx',
      ),
      const ExecutionContext(idempotencyKey: 'cc-payment-fx'),
    );

    expect(result, isA<DomainViolationResult>());
    expect(transactionBox.values.where((tx) => tx.source == TransactionSource.creditCardPayment), isEmpty);
    expect(BalanceService().getBalance('usd-bank'), 1000);
    expect(BalanceService().getBalance('card'), -3000);
  });

  test('unknown payment source is rejected without mutation', () async {
    final context = await buildContext();

    final result = await context.engine.execute(
      operation(
        sourceId: 'missing-bank',
        amount: 100,
        idempotencyKey: 'cc-payment-missing-source',
      ),
      const ExecutionContext(idempotencyKey: 'cc-payment-missing-source'),
    );

    expect(result, isA<DomainViolationResult>());
    expect(transactionBox.values.where((tx) => tx.source == TransactionSource.creditCardPayment), isEmpty);
    expect(BalanceService().getBalance('bank'), 5000);
    expect(BalanceService().getBalance('card'), -3000);
  });

  test('payment requires a matching credit card profile', () async {
    await profileBox.delete('profile-card');
    final context = await buildContext();

    final result = await context.engine.execute(
      operation(
        sourceId: 'bank',
        amount: 100,
        idempotencyKey: 'cc-payment-missing-profile',
      ),
      const ExecutionContext(idempotencyKey: 'cc-payment-missing-profile'),
    );

    expect(result, isA<DomainViolationResult>());
    expect(transactionBox.values.where((tx) => tx.source == TransactionSource.creditCardPayment), isEmpty);
    expect(BalanceService().getBalance('bank'), 5000);
    expect(BalanceService().getBalance('card'), -3000);
  });

  test('target must be explicitly typed as a credit card liability', () async {
    await accountsBox.put(
      'card',
      Account(
        id: 'card',
        bookId: 'default',
        memberId: 'owner',
        name: 'Test Liability',
        type: 'loan',
        nature: AccountNature.liability,
        currency: 'EGP',
        createdAt: DateTime(2026, 1, 1),
        group: AccountGroup.liabilities,
      ),
    );
    final context = await buildContext();

    final result = await context.engine.execute(
      operation(
        sourceId: 'bank',
        amount: 100,
        idempotencyKey: 'cc-payment-invalid-target',
      ),
      const ExecutionContext(idempotencyKey: 'cc-payment-invalid-target'),
    );

    expect(result, isA<DomainViolationResult>());
    expect(transactionBox.values.where((tx) => tx.source == TransactionSource.creditCardPayment), isEmpty);
    expect(BalanceService().getBalance('bank'), 5000);
  });

  test('insufficient source balance is rejected without mutation', () async {
    await transactionBox.put(
      'opening-bank',
      Transaction(
        id: 'opening-bank',
        amount: 500,
        type: TransactionType.initialBalance,
        toAccountId: 'bank',
        date: DateTime(2026, 1, 1),
        paymentMethod: 'opening',
        currencyCode: 'EGP',
      ),
    );
    final context = await buildContext();

    final result = await context.engine.execute(
      operation(
        sourceId: 'bank',
        amount: 1000,
        idempotencyKey: 'cc-payment-insufficient',
      ),
      const ExecutionContext(idempotencyKey: 'cc-payment-insufficient'),
    );

    expect(result, isA<DomainViolationResult>());
    expect(transactionBox.values.where((tx) => tx.source == TransactionSource.creditCardPayment), isEmpty);
    expect(BalanceService().getBalance('bank'), 500);
    expect(BalanceService().getBalance('card'), -3000);
  });

  test('metadata currency must match both participating accounts', () async {
    final context = await buildContext();

    final result = await context.engine.execute(
      operation(
        sourceId: 'bank',
        amount: 100,
        metadataCurrency: 'USD',
        idempotencyKey: 'cc-payment-metadata-currency',
      ),
      const ExecutionContext(idempotencyKey: 'cc-payment-metadata-currency'),
    );

    expect(result, isA<DomainViolationResult>());
    expect(transactionBox.values.where((tx) => tx.source == TransactionSource.creditCardPayment), isEmpty);
    expect(BalanceService().getBalance('bank'), 5000);
    expect(BalanceService().getBalance('card'), -3000);
  });

  test('repeated operation with the same idempotency key writes one payment', () async {
    final context = await buildContext();
    final op = operation(
      sourceId: 'bank',
      amount: 500,
      idempotencyKey: 'cc-payment-idempotent',
    );
    const execution = ExecutionContext(idempotencyKey: 'cc-payment-idempotent');

    final first = await context.engine.execute(op, execution);
    final second = await context.engine.execute(op, execution);

    expect(first, isA<OperationSucceeded>());
    expect(second, isA<OperationSucceeded>());
    expect(identical(first, second), isTrue);
    expect(transactionBox.values.where((tx) => tx.source == TransactionSource.creditCardPayment), hasLength(1));
    expect(BalanceService().getBalance('bank'), 4500);
    expect(BalanceService().getBalance('card'), -2500);
  });
}
