import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:wafferly/adapters/account_migration_adapter.dart';
import 'package:wafferly/bootstrap/financial_engine_bootstrap.dart';
import 'package:wafferly/bootstrap/financial_engine_context.dart';
import 'package:wafferly/constants/transaction_constants.dart';
import 'package:wafferly/core/money/money.dart';
import 'package:wafferly/core/planning/infrastructure/repositories/memory_allocation_repository.dart';
import 'package:wafferly/core/planning/services/available_balance_projection_service.dart';
import 'package:wafferly/credit_card/domain/credit_card_profile.dart';
import 'package:wafferly/credit_card/infrastructure/hive_credit_card_profile_repository.dart';
import 'package:wafferly/financial_engine/commands/credit_card/credit_card_charge_intent.dart';
import 'package:wafferly/financial_engine/commands/shared/transaction_metadata.dart';
import 'package:wafferly/financial_engine/execution_context/execution_context.dart';
import 'package:wafferly/financial_engine/operations/credit_card_charge_operation.dart';
import 'package:wafferly/financial_engine/results/operation_result.dart';
import 'package:wafferly/financing/domain/credit_card_financing_conversion.dart';
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
import 'package:wafferly/application/credit_card/credit_card_financing_application_service.dart';

/// Regression test for the most dangerous installment failure window:
///
///   Credit Card Charge committed
///          ↓
///   app/process stops
///          ↓
///   app restarts
///          ↓
///   same logical operation is retried
///
/// The retry must reuse the committed Charge, then complete financing, with
/// exactly one Charge, one ledger movement set, one Contract, one Schedule,
/// one conversion event and one set of Installments.
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

  const workflowId = 'iw-test-crash-after-charge-001';
  const chargeIdempotencyKey = 'installment:$workflowId:credit-card-charge';
  const categoryId = 'dailyTransport';
  const cardId = 'card';
  const purchaseAmount = 3000.0;
  const installmentCount = 6;
  final purchaseDate = DateTime(2026, 10, 7, 16, 0);
  final firstDueDate = DateTime(2026, 11, 7);

  setUpAll(() async {
    testDirectory = await Directory.systemTemp.createTemp(
      'wafferly_financing_crash_recovery_',
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

    // Use canonical production box names because several query/projection
    // services resolve these names directly.
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
      cardId,
      Account(
        id: cardId,
        bookId: 'default',
        memberId: 'owner',
        name: 'Crash Recovery Card',
        type: 'creditCard',
        currency: 'EGP',
        createdAt: DateTime(2026, 1, 1),
        group: AccountGroup.liabilities,
        nature: AccountNature.liability,
      ),
    );

    await profileBox.put(
      'profile-card',
      CreditCardProfile.fromMoney(
        id: 'profile-card',
        accountId: cardId,
        creditLimit: Money.fromDouble(10000),
      ),
    );
  });

  tearDownAll(() async {
    await Hive.close();
    if (await testDirectory.exists()) {
      await testDirectory.delete(recursive: true);
    }
  });

  Future<FinancialEngineContext> buildEngineContext() async {
    final allocationRepository = MemoryAllocationRepository();
    final projectionService = AvailableBalanceProjectionService(
      allocationRepository: allocationRepository,
    );
    final balanceService = BalanceService(
      availableBalanceProjectionService: projectionService,
    );

    return FinancialEngineBootstrap.create(
      balanceService: balanceService,
      transactionBox: transactionsBox,
      idempotencyBox: idempotencyBox,
      allocationRepository: allocationRepository,
      creditCardProfileRepository: HiveCreditCardProfileRepository(profileBox),
    );
  }

  CreditCardChargeOperation chargeOperation(String idempotencyKey) {
    return CreditCardChargeOperation(
      intent: CreditCardChargeIntent(
        creditCardAccountId: cardId,
        categoryId: categoryId,
        amount: Money.fromDouble(purchaseAmount),
      ),
      metadata: TransactionMetadata(
        occurredAt: purchaseDate,
        paymentMethod: 'credit_card',
        currencyCode: 'EGP',
        note: 'Crash recovery installment test',
      ),
      context: ExecutionContext(idempotencyKey: idempotencyKey),
    );
  }

  CreditCardFinancingConversionRequest conversionRequest({
    required String originChargeId,
  }) {
    final totalCents = (purchaseAmount * 100).round();
    final baseCents = totalCents ~/ installmentCount;
    final remainder = totalCents % installmentCount;

    return CreditCardFinancingConversionRequest(
      conversionId: 'conversion-cc-charge-$originChargeId',
      originChargeId: originChargeId,
      contractId: 'contract-cc-charge-$originChargeId',
      scheduleId: 'schedule-cc-charge-$originChargeId',
      scheduleRuleId: 'rule-cc-charge-$originChargeId',
      liabilityAccountId: cardId,
      paymentFrequency: 'monthly',
      firstDueDate: firstDueDate,
      installments: List.generate(installmentCount, (index) {
        final cents = baseCents + (index == installmentCount - 1 ? remainder : 0);
        final value = (cents / 100).toStringAsFixed(2);
        return FinancingInstallmentDraft(
          dueDate: DateTime(
            firstDueDate.year,
            firstDueDate.month + index,
            firstDueDate.day,
          ),
          principal: Money.parse(value),
          interest: Money.zero,
          fees: Money.zero,
        );
      }),
      effectiveDate: purchaseDate,
      createdAt: purchaseDate,
    );
  }

  test(
    'crash after charge before conversion then restart and retry completes without duplicates',
    () async {
      // -------------------- Attempt #1 --------------------
      final firstContext = await buildEngineContext();
      final firstResult = await firstContext.engine.execute(
        chargeOperation(chargeIdempotencyKey),
        const ExecutionContext(idempotencyKey: chargeIdempotencyKey),
      );

      expect(firstResult, isA<OperationSucceeded>());
      final firstChargeId =
          (firstResult as OperationSucceeded).summary.createdTransactionIds.single;

      expect(
        transactionsBox.values.where(
          (tx) => tx.type == TransactionType.creditCardCharge,
        ),
        hasLength(1),
      );
      expect(ledgerBox.values, hasLength(2));
      expect(idempotencyBox.containsKey(chargeIdempotencyKey), isTrue);

      // -------------------- Simulated app crash --------------------
      // Intentionally stop here. There is NO conversion call.
      // The durable Charge is the exact state left behind by a real crash
      // between the financial write and the contractual conversion.

      // -------------------- Attempt #2 / app restart --------------------
      final restartedContext = await buildEngineContext();
      final retryResult = await restartedContext.engine.execute(
        chargeOperation(chargeIdempotencyKey),
        const ExecutionContext(idempotencyKey: chargeIdempotencyKey),
      );

      expect(retryResult, isA<OperationSucceeded>());
      final retrySummary = (retryResult as OperationSucceeded).summary;

      // Durable replay must return the exact authoritative transaction id.
      expect(retrySummary.createdTransactionIds, [firstChargeId]);

      // No second financial write occurred during retry.
      final chargeTransactions = transactionsBox.values
          .where((tx) => tx.type == TransactionType.creditCardCharge)
          .toList();
      expect(chargeTransactions, hasLength(1));
      expect(chargeTransactions.single.id, firstChargeId);
      expect(
        ledgerBox.values.where((entry) => entry.transactionId == firstChargeId),
        hasLength(2),
      );

      // -------------------- Recovery: finish conversion --------------------
      final charge = transactionsBox.get(firstChargeId);
      expect(charge, isNotNull);

      final financing = CreditCardFinancingApplicationService(
        accounts: accountsBox,
        transactions: transactionsBox,
        contracts: contractsBox,
        schedules: schedulesBox,
        installments: installmentsBox,
        conversionEvents: conversionEventsBox,
        scheduleRules: scheduleRulesBox,
      );

      final firstConversion = await financing.convertCharge(
        charge: charge!,
        installmentCount: installmentCount,
        firstDueDate: firstDueDate,
      );

      expect(firstConversion.alreadyCompleted, isFalse);
      expect(firstConversion.contract.originReference, firstChargeId);
      expect(firstConversion.installments, hasLength(installmentCount));

      // A second recovery attempt must converge to the same contractual state.
      final secondConversion = await financing.convertCharge(
        charge: charge,
        installmentCount: installmentCount,
        firstDueDate: firstDueDate,
      );

      expect(secondConversion.alreadyCompleted, isTrue);
      expect(secondConversion.contract.contractId, firstConversion.contract.contractId);
      expect(contractsBox.values, hasLength(1));
      expect(schedulesBox.values, hasLength(1));
      expect(scheduleRulesBox.values, hasLength(1));
      expect(installmentsBox.values, hasLength(installmentCount));
      expect(conversionEventsBox.values, hasLength(1));
      expect(
        conversionEventsBox.values.single.status,
        financingConversionCompleted,
      );

      // Final invariant: one purchase = one Charge = one ledger movement set
      // = one financing plan.
      expect(
        transactionsBox.values
            .where((tx) => tx.type == TransactionType.creditCardCharge),
        hasLength(1),
      );
      expect(
        ledgerBox.values.where((entry) => entry.transactionId == firstChargeId),
        hasLength(2),
      );
    },
  );
}
