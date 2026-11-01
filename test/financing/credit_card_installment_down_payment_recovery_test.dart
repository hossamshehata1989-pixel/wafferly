import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:wafferly/adapters/account_migration_adapter.dart';
import 'package:wafferly/bootstrap/financial_engine_bootstrap.dart';
import 'package:wafferly/constants/transaction_constants.dart';
import 'package:wafferly/controllers/transaction_entry_controller.dart';
import 'package:wafferly/core/money/money.dart';
import 'package:wafferly/core/planning/infrastructure/repositories/memory_allocation_repository.dart';
import 'package:wafferly/core/planning/services/available_balance_projection_service.dart';
import 'package:wafferly/credit_card/domain/credit_card_profile.dart';
import 'package:wafferly/credit_card/infrastructure/hive_credit_card_profile_repository.dart';
import 'package:wafferly/features/analysis/registry/category_registry.dart';
import 'package:wafferly/financial_engine/results/operation_result.dart';
import 'package:wafferly/models/account.dart';
import 'package:wafferly/models/enums/account_enums.dart';
import 'package:wafferly/models/enums/entry_type.dart';
import 'package:wafferly/models/enums/frequency.dart';
import 'package:wafferly/models/enums/ledger_account_type.dart';
import 'package:wafferly/models/enums/ledger_purpose.dart';
import 'package:wafferly/models/financing/financing_contract.dart';
import 'package:wafferly/models/financing/financing_conversion_event.dart';
import 'package:wafferly/models/financing/financing_installment.dart';
import 'package:wafferly/models/financing/financing_schedule.dart';
import 'package:wafferly/models/ledger_account.dart';
import 'package:wafferly/models/ledger_entry.dart';
import 'package:wafferly/models/schedule_rule.dart';
import 'package:wafferly/models/transaction.dart';
import 'package:wafferly/services/balance_service.dart';
import 'package:wafferly/services/ledger_account_seeder.dart';
import 'package:wafferly/services/transaction_application_service.dart';
import 'package:wafferly/services/transaction_query_service.dart';

/// Fails only the first down-payment expense. All card charges and the retry
/// are delegated to the real Financial Engine.
class _FailOnceDownPaymentService extends TransactionApplicationService {
  _FailOnceDownPaymentService({
    required super.engine,
    required super.transactionQueryService,
    this.failCreditCardDownPaymentAccountId,
  });

  final String? failCreditCardDownPaymentAccountId;
  final List<String> chargeKeys = <String>[];
  final List<String> chargeAccountIds = <String>[];
  final List<String> expenseKeys = <String>[];
  bool _failNextCreditCardDownPayment = true;
  bool _failNextExpense = true;

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
    chargeKeys.add(idempotencyKey);
    chargeAccountIds.add(creditCardAccountId);

    if (creditCardAccountId == failCreditCardDownPaymentAccountId &&
        _failNextCreditCardDownPayment) {
      _failNextCreditCardDownPayment = false;
      return const OperationFailed(error: 'Injected down-payment card failure');
    }

    return super.addCreditCardCharge(
      creditCardAccountId: creditCardAccountId,
      amount: amount,
      categoryId: categoryId,
      subCategoryId: subCategoryId,
      occurredAt: occurredAt,
      currencyCode: currencyCode,
      note: note,
      actorMemberId: actorMemberId,
      idempotencyKey: idempotencyKey,
      isExceptional: isExceptional,
    );
  }

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
    expenseKeys.add(idempotencyKey);
    if (_failNextExpense) {
      _failNextExpense = false;
      return const OperationFailed(error: 'Injected down-payment failure');
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

void main() {
  late Directory testDirectory;
  late Box<Account> accountsBox;
  late Box<Transaction> transactionsBox;
  late Box<LedgerEntry> ledgerBox;
  late Box<LedgerAccount> ledgerAccountsBox;
  late Box<CreditCardProfile> profileBox;
  late Box<Map> idempotencyBox;
  late Box<FinancingContract> contractsBox;
  late Box<FinancingSchedule> schedulesBox;
  late Box<FinancingInstallment> installmentsBox;
  late Box<FinancingConversionEvent> conversionEventsBox;
  late Box<ScheduleRule> scheduleRulesBox;

  setUpAll(() async {
    testDirectory = await Directory.systemTemp.createTemp(
      'wafferly_b5_down_payment_recovery_',
    );
    Hive.init(testDirectory.path);

    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(AccountMigrationAdapter());
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
    if (!Hive.isAdapterRegistered(94)) {
      Hive.registerAdapter(FrequencyAdapter());
    }
    if (!Hive.isAdapterRegistered(95)) {
      Hive.registerAdapter(ScheduleRuleAdapter());
    }
    if (!Hive.isAdapterRegistered(100)) {
      Hive.registerAdapter(CreditCardProfileAdapter());
    }
    if (!Hive.isAdapterRegistered(110)) {
      Hive.registerAdapter(FinancingContractAdapter());
    }
    if (!Hive.isAdapterRegistered(111)) {
      Hive.registerAdapter(FinancingScheduleAdapter());
    }
    if (!Hive.isAdapterRegistered(112)) {
      Hive.registerAdapter(FinancingInstallmentAdapter());
    }
    if (!Hive.isAdapterRegistered(114)) {
      Hive.registerAdapter(FinancingConversionEventAdapter());
    }

    // The controller and financing application service resolve these canonical
    // names directly, so the test intentionally opens production box names.
    accountsBox = await Hive.openBox<Account>('accounts');
    transactionsBox = await Hive.openBox<Transaction>('transactions');
    ledgerBox = await Hive.openBox<LedgerEntry>('ledger_entries');
    ledgerAccountsBox = await Hive.openBox<LedgerAccount>('ledger_accounts');
    profileBox = await Hive.openBox<CreditCardProfile>('credit_card_profiles');
    idempotencyBox = await Hive.openBox<Map>('financial_idempotency');
    contractsBox = await Hive.openBox<FinancingContract>('financing_contracts');
    schedulesBox = await Hive.openBox<FinancingSchedule>('financing_schedules');
    installmentsBox = await Hive.openBox<FinancingInstallment>(
      'financing_installments',
    );
    conversionEventsBox = await Hive.openBox<FinancingConversionEvent>(
      'financing_conversion_events',
    );
    scheduleRulesBox = await Hive.openBox<ScheduleRule>('schedule_rules');

    CategoryRegistry.initialize();
  });

  tearDownAll(() async {
    await Hive.close();
    if (await testDirectory.exists()) {
      await testDirectory.delete(recursive: true);
    }
  });

  setUp(() async {
    await accountsBox.clear();
    await transactionsBox.clear();
    await ledgerBox.clear();
    await ledgerAccountsBox.clear();
    await profileBox.clear();
    await idempotencyBox.clear();
    await contractsBox.clear();
    await schedulesBox.clear();
    await installmentsBox.clear();
    await conversionEventsBox.clear();
    await scheduleRulesBox.clear();

    await LedgerAccountSeeder().seedIfNeeded();

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
        creditLimit: Money.fromDouble(10000),
      ),
    );
    await transactionsBox.put(
      'wallet-opening-balance',
      Transaction(
        id: 'wallet-opening-balance',
        amount: 1000,
        type: TransactionType.initialBalance,
        toAccountId: 'wallet',
        date: DateTime(2026, 1, 1),
        paymentMethod: 'cash',
        currencyCode: 'EGP',
      ),
    );
  });

  test(
    'down-payment retry reuses the charge and financing plan without duplicate financial effects',
    () async {
      final allocationRepository = MemoryAllocationRepository();
      final balanceService = BalanceService(
        availableBalanceProjectionService: AvailableBalanceProjectionService(
          allocationRepository: allocationRepository,
        ),
      );
      final engineContext = FinancialEngineBootstrap.create(
        balanceService: balanceService,
        transactionBox: transactionsBox,
        idempotencyBox: idempotencyBox,
        allocationRepository: allocationRepository,
        creditCardProfileRepository: HiveCreditCardProfileRepository(
          profileBox,
        ),
      );
      final service = _FailOnceDownPaymentService(
        engine: engineContext.engine,
        transactionQueryService: const TransactionQueryService(),
      );
      final controller = TransactionEntryController(
        transactionService: service,
      );
      addTearDown(controller.dispose);

      controller.setAmount('3000');
      controller.selectCategory('dailyTransport');

      Future<SaveResult> saveInstallment() {
        return controller.saveCreditCardInstallment(
          creditCardAccountId: 'card',
          installmentCount: 6,
          firstDueDate: DateTime(2026, 12, 1),
          downPayment: 500,
          downPaymentAccountId: 'wallet',
        );
      }

      // Attempt 1: real card charge and conversion succeed; the injected
      // transient failure prevents the down-payment expense from being posted.
      final first = await saveInstallment();
      expect(first.success, isFalse);
      expect(first.errorMessage, contains('down payment is pending'));

      final firstCharge = transactionsBox.values.singleWhere(
        (tx) => tx.type == TransactionType.creditCardCharge,
      );
      expect(firstCharge.amount, 2500);
      expect(
        transactionsBox.values.where(
          (tx) => tx.type == TransactionType.expense,
        ),
        isEmpty,
      );
      expect(contractsBox.values, hasLength(1));
      expect(schedulesBox.values, hasLength(1));
      expect(scheduleRulesBox.values, hasLength(1));
      expect(installmentsBox.values, hasLength(6));
      expect(conversionEventsBox.values, hasLength(1));

      // Attempt 2: the same controller and unchanged draft must replay the
      // existing charge/conversion, then post the down payment successfully.
      final retry = await saveInstallment();
      expect(retry.success, isTrue);

      expect(service.chargeKeys, hasLength(2));
      expect(service.chargeKeys[1], service.chargeKeys[0]);
      expect(service.expenseKeys, hasLength(2));
      expect(service.expenseKeys[1], service.expenseKeys[0]);

      final chargeTransactions = transactionsBox.values
          .where((tx) => tx.type == TransactionType.creditCardCharge)
          .toList();
      final downPaymentTransactions = transactionsBox.values
          .where((tx) => tx.type == TransactionType.expense)
          .toList();

      expect(chargeTransactions, hasLength(1));
      expect(chargeTransactions.single.id, firstCharge.id);
      expect(chargeTransactions.single.amount, 2500);
      expect(downPaymentTransactions, hasLength(1));
      expect(downPaymentTransactions.single.amount, 500);
      expect(downPaymentTransactions.single.fromAccountId, 'wallet');

      expect(contractsBox.values, hasLength(1));
      expect(schedulesBox.values, hasLength(1));
      expect(scheduleRulesBox.values, hasLength(1));
      expect(installmentsBox.values, hasLength(6));
      expect(conversionEventsBox.values, hasLength(1));
      expect(idempotencyBox.length, 2);

      expect(
        ledgerBox.values.where(
          (entry) => entry.transactionId == firstCharge.id,
        ),
        hasLength(2),
      );
      expect(
        ledgerBox.values.where(
          (entry) => entry.transactionId == downPaymentTransactions.single.id,
        ),
        hasLength(2),
      );
      expect(BalanceService().getBalance('wallet'), 500);
    },
  );

  test('credit-card down-payment retry reuses its charge key '
      'without duplicate financial effects', () async {
    await accountsBox.put(
      'down-payment-card',
      Account(
        id: 'down-payment-card',
        bookId: 'default',
        memberId: 'owner',
        name: 'Down Payment Card',
        type: 'creditCard',
        nature: AccountNature.liability,
        currency: 'EGP',
        createdAt: DateTime(2026, 1, 1),
        group: AccountGroup.liabilities,
      ),
    );
    await profileBox.put(
      'profile-down-payment-card',
      CreditCardProfile.fromMoney(
        id: 'profile-down-payment-card',
        accountId: 'down-payment-card',
        creditLimit: Money.fromDouble(10000),
      ),
    );

    final allocationRepository = MemoryAllocationRepository();
    final balanceService = BalanceService(
      availableBalanceProjectionService: AvailableBalanceProjectionService(
        allocationRepository: allocationRepository,
      ),
    );
    final engineContext = FinancialEngineBootstrap.create(
      balanceService: balanceService,
      transactionBox: transactionsBox,
      idempotencyBox: idempotencyBox,
      allocationRepository: allocationRepository,
      creditCardProfileRepository: HiveCreditCardProfileRepository(profileBox),
    );
    final service = _FailOnceDownPaymentService(
      engine: engineContext.engine,
      transactionQueryService: const TransactionQueryService(),
      failCreditCardDownPaymentAccountId: 'down-payment-card',
    );
    final controller = TransactionEntryController(transactionService: service);
    addTearDown(controller.dispose);

    controller.setAmount('3000');
    controller.selectCategory('dailyTransport');

    Future<SaveResult> saveInstallment() {
      return controller.saveCreditCardInstallment(
        creditCardAccountId: 'card',
        installmentCount: 6,
        firstDueDate: DateTime(2026, 12, 1),
        downPayment: 500,
        downPaymentAccountId: 'down-payment-card',
      );
    }

    // Attempt 1: the financed charge and conversion succeed. Only the
    // separate credit-card down-payment charge is injected to fail.
    final first = await saveInstallment();
    expect(first.success, isFalse);
    expect(first.errorMessage, contains('down payment is pending'));

    final initialCharges = transactionsBox.values
        .where((tx) => tx.type == TransactionType.creditCardCharge)
        .toList();
    expect(initialCharges, hasLength(1));
    expect(initialCharges.single.toAccountId, 'card');
    expect(initialCharges.single.amount, 2500);
    expect(contractsBox.values, hasLength(1));
    expect(schedulesBox.values, hasLength(1));
    expect(scheduleRulesBox.values, hasLength(1));
    expect(installmentsBox.values, hasLength(6));
    expect(conversionEventsBox.values, hasLength(1));

    // Attempt 2: the financed charge and conversion are replayed safely;
    // the down-payment card charge now reaches the real Financial Engine.
    final retry = await saveInstallment();
    expect(retry.success, isTrue);

    expect(service.chargeKeys, hasLength(4));
    expect(service.chargeAccountIds, <String>[
      'card',
      'down-payment-card',
      'card',
      'down-payment-card',
    ]);
    expect(service.chargeKeys[2], service.chargeKeys[0]);
    expect(service.chargeKeys[3], service.chargeKeys[1]);
    expect(service.expenseKeys, isEmpty);

    final finalCharges = transactionsBox.values
        .where((tx) => tx.type == TransactionType.creditCardCharge)
        .toList();
    expect(finalCharges, hasLength(2));

    final financedCharge = finalCharges.singleWhere(
      (tx) => tx.toAccountId == 'card',
    );
    final downPaymentCharge = finalCharges.singleWhere(
      (tx) => tx.toAccountId == 'down-payment-card',
    );
    expect(financedCharge.id, initialCharges.single.id);
    expect(financedCharge.amount, 2500);
    expect(downPaymentCharge.amount, 500);

    expect(contractsBox.values, hasLength(1));
    expect(schedulesBox.values, hasLength(1));
    expect(scheduleRulesBox.values, hasLength(1));
    expect(installmentsBox.values, hasLength(6));
    expect(conversionEventsBox.values, hasLength(1));
    expect(idempotencyBox.length, 2);

    expect(
      ledgerBox.values.where(
        (entry) => entry.transactionId == financedCharge.id,
      ),
      hasLength(2),
    );
    expect(
      ledgerBox.values.where(
        (entry) => entry.transactionId == downPaymentCharge.id,
      ),
      hasLength(2),
    );
    expect(BalanceService().getBalance('wallet'), 1000);
  });
}
