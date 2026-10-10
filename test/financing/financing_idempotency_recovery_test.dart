import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:wafferly/models/account.dart';
import 'package:wafferly/models/enums/account_enums.dart';
import 'package:wafferly/models/enums/frequency.dart';
import 'package:wafferly/models/transaction.dart';
import 'package:wafferly/models/schedule_rule.dart';
import 'package:wafferly/models/financing/financing_contract.dart';
import 'package:wafferly/models/financing/financing_conversion_event.dart';
import 'package:wafferly/models/financing/financing_installment.dart';
import 'package:wafferly/models/financing/financing_schedule.dart';
import 'package:wafferly/constants/transaction_constants.dart';
import 'package:wafferly/financing/domain/credit_card_financing_conversion.dart';
import 'package:wafferly/core/money/money.dart';

void main() {
  late Directory directory;
  late Box<Account> accounts;
  late Box<Transaction> transactions;
  late Box<FinancingContract> contracts;
  late Box<FinancingSchedule> schedules;
  late Box<FinancingInstallment> installments;
  late Box<FinancingConversionEvent> events;
  late Box<ScheduleRule> rules;
  late CreditCardFinancingConversionOperation operation;

  setUpAll(() async {
    directory = await Directory.systemTemp.createTemp('wafferly_financing_recovery_');
    Hive.init(directory.path);
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(AccountAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(AccountNatureAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(AccountGroupAdapter());
    if (!Hive.isAdapterRegistered(10)) Hive.registerAdapter(TransactionAdapter());
    if (!Hive.isAdapterRegistered(95)) Hive.registerAdapter(ScheduleRuleAdapter());
    if (!Hive.isAdapterRegistered(94)) Hive.registerAdapter(FrequencyAdapter());
    if (!Hive.isAdapterRegistered(110)) Hive.registerAdapter(FinancingContractAdapter());
    if (!Hive.isAdapterRegistered(111)) Hive.registerAdapter(FinancingScheduleAdapter());
    if (!Hive.isAdapterRegistered(112)) Hive.registerAdapter(FinancingInstallmentAdapter());
    if (!Hive.isAdapterRegistered(114)) Hive.registerAdapter(FinancingConversionEventAdapter());

    accounts = await Hive.openBox<Account>('financing_recovery_accounts');
    transactions = await Hive.openBox<Transaction>('financing_recovery_transactions');
    contracts = await Hive.openBox<FinancingContract>('financing_recovery_contracts');
    schedules = await Hive.openBox<FinancingSchedule>('financing_recovery_schedules');
    installments = await Hive.openBox<FinancingInstallment>('financing_recovery_installments');
    events = await Hive.openBox<FinancingConversionEvent>('financing_recovery_events');
    rules = await Hive.openBox<ScheduleRule>('financing_recovery_rules');

    operation = CreditCardFinancingConversionOperation(
      accounts: accounts,
      transactions: transactions,
      contracts: contracts,
      schedules: schedules,
      installments: installments,
      conversionEvents: events,
      scheduleRules: rules,
    );
  });

  setUp(() async {
    await accounts.clear();
    await transactions.clear();
    await contracts.clear();
    await schedules.clear();
    await installments.clear();
    await events.clear();
    await rules.clear();

    await accounts.put(
      'card-1',
      Account(
        id: 'card-1',
        bookId: 'default',
        memberId: 'owner',
        name: 'Recovery Card',
        type: 'creditCard',
        currency: 'EGP',
        createdAt: DateTime(2026, 1, 1),
        group: AccountGroup.liabilities,
        nature: AccountNature.liability,
      ),
    );
    await rules.put(
      'rule-1',
      ScheduleRule(
        id: 'rule-1',
        frequency: Frequency.monthly,
        startDate: DateTime(2026, 10, 26),
        nextDueDate: DateTime(2026, 10, 26),
      ),
    );
    await transactions.put(
      'charge-1',
      Transaction(
        id: 'charge-1',
        amount: 10000,
        type: TransactionType.creditCardCharge,
        toAccountId: 'card-1',
        date: DateTime(2026, 9, 27),
        paymentMethod: 'credit_card',
        currencyCode: 'EGP',
        source: TransactionSource.creditCardCharge,
      ),
    );
  });

  tearDownAll(() async {
    await Hive.close();
    if (await directory.exists()) await directory.delete(recursive: true);
  });

  CreditCardFinancingConversionRequest request({String id = 'conv-1'}) =>
      CreditCardFinancingConversionRequest(
        conversionId: id,
        originChargeId: 'charge-1',
        contractId: 'contract-1',
        scheduleId: 'schedule-1',
        scheduleRuleId: 'rule-1',
        liabilityAccountId: 'card-1',
        paymentFrequency: 'monthly',
        firstDueDate: DateTime(2026, 10, 26),
        installments: [
          FinancingInstallmentDraft(
            dueDate: DateTime(2026, 10, 26),
            principal: Money.parse('5000'),
          ),
          FinancingInstallmentDraft(
            dueDate: DateTime(2026, 11, 26),
            principal: Money.parse('5000'),
          ),
        ],
        effectiveDate: DateTime(2026, 9, 27),
        createdAt: DateTime(2026, 9, 27),
      );

  test('retry after completed conversion returns durable prior outcome', () async {
    final first = await operation.execute(request());
    final second = await operation.execute(request());

    expect(first.alreadyCompleted, isFalse);
    expect(second.alreadyCompleted, isTrue);
    expect(events.get('conv-1')!.status, financingConversionCompleted);
    expect(contracts.values, hasLength(1));
    expect(schedules.values, hasLength(1));
    expect(installments.values, hasLength(2));
  });

  test('recovery resumes a conversion left in started state', () async {
    await events.put(
      'conv-1',
      FinancingConversionEvent(
        conversionId: 'conv-1',
        originChargeId: 'charge-1',
        contractId: 'contract-1',
        scheduleId: 'schedule-1',
        scheduleRuleId: 'rule-1',
        status: financingConversionStarted,
        createdAt: DateTime(2026, 9, 27),
        updatedAt: DateTime(2026, 9, 27),
      ),
    );

    final result = await operation.execute(request());

    expect(result.alreadyCompleted, isFalse);
    expect(events.get('conv-1')!.status, financingConversionCompleted);
    expect(contracts.values, hasLength(1));
    expect(schedules.values, hasLength(1));
    expect(installments.values, hasLength(2));
  });

  test('retry after a partial contractual write converges without duplicates', () async {
    await contracts.put(
      'contract-1',
      FinancingContract(
        contractId: 'contract-1',
        liabilityAccountId: 'card-1',
        originReference: 'charge-1',
        principalValue: '10000',
        installmentCount: 2,
        paymentFrequency: 'monthly',
        firstDueDate: DateTime(2026, 10, 26),
        lifecycleState: 'active',
        effectiveDate: DateTime(2026, 9, 27),
        createdAt: DateTime(2026, 9, 27),
      ),
    );

    final result = await operation.execute(request());

    expect(result.contract.contractId, 'contract-1');
    expect(contracts.values, hasLength(1));
    expect(schedules.values, hasLength(1));
    expect(installments.values, hasLength(2));
    expect(events.get('conv-1')!.status, financingConversionCompleted);
  });

  test('different conversion cannot start while the same origin is already started', () async {
    await events.put(
      'conv-existing',
      FinancingConversionEvent(
        conversionId: 'conv-existing',
        originChargeId: 'charge-1',
        contractId: 'contract-existing',
        scheduleId: 'schedule-existing',
        scheduleRuleId: 'rule-1',
        status: financingConversionStarted,
        createdAt: DateTime(2026, 9, 27),
        updatedAt: DateTime(2026, 9, 27),
      ),
    );

    await expectLater(
      operation.execute(request(id: 'conv-new')),
      throwsA(isA<StateError>()),
    );

    expect(events.get('conv-existing')!.status, financingConversionStarted);
    expect(events.get('conv-new'), isNull);
    expect(contracts.values, isEmpty);
    expect(schedules.values, isEmpty);
    expect(installments.values, isEmpty);
  });

  test('different logical operation cannot reuse an existing conversion identity', () async {
    await operation.execute(request());

    final conflicting = request(id: 'conv-1').copyWithForRecoveryTest(
      contractId: 'different-contract',
      scheduleId: 'different-schedule',
    );

    await expectLater(operation.execute(conflicting), throwsA(isA<StateError>()));
    expect(contracts.values, hasLength(1));
    expect(schedules.values, hasLength(1));
    expect(installments.values, hasLength(2));
  });
}

extension on CreditCardFinancingConversionRequest {
  CreditCardFinancingConversionRequest copyWithForRecoveryTest({
    String? contractId,
    String? scheduleId,
  }) {
    return CreditCardFinancingConversionRequest(
      conversionId: conversionId,
      originChargeId: originChargeId,
      contractId: contractId ?? this.contractId,
      scheduleId: scheduleId ?? this.scheduleId,
      scheduleRuleId: scheduleRuleId,
      liabilityAccountId: liabilityAccountId,
      paymentFrequency: paymentFrequency,
      firstDueDate: firstDueDate,
      installments: installments,
      interestPolicyId: interestPolicyId,
      effectiveDate: effectiveDate,
      createdAt: createdAt,
    );
  }
}
