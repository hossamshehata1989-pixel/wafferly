import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:wafferly/constants/transaction_constants.dart';
import 'package:wafferly/core/money/money.dart';
import 'package:wafferly/financing/domain/credit_card_financing_conversion.dart';
import 'package:wafferly/models/account.dart';
import 'package:wafferly/adapters/account_migration_adapter.dart';
import 'package:wafferly/models/enums/account_enums.dart';
import 'package:wafferly/models/financing/financing_contract.dart';
import 'package:wafferly/models/financing/financing_conversion_event.dart';
import 'package:wafferly/models/financing/financing_installment.dart';
import 'package:wafferly/models/financing/financing_schedule.dart';
import 'package:wafferly/models/schedule_rule.dart';
import 'package:wafferly/models/enums/frequency.dart';
import 'package:wafferly/models/transaction.dart';

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
    directory = await Directory.systemTemp.createTemp('wafferly_conversion_');
    Hive.init(directory.path);
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(AccountMigrationAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(AccountNatureAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(AccountGroupAdapter());
    if (!Hive.isAdapterRegistered(10)) Hive.registerAdapter(TransactionAdapter());
    if (!Hive.isAdapterRegistered(95)) Hive.registerAdapter(ScheduleRuleAdapter());
    if (!Hive.isAdapterRegistered(94)) Hive.registerAdapter(FrequencyAdapter());
    if (!Hive.isAdapterRegistered(110)) Hive.registerAdapter(FinancingContractAdapter());
    if (!Hive.isAdapterRegistered(111)) Hive.registerAdapter(FinancingScheduleAdapter());
    if (!Hive.isAdapterRegistered(112)) Hive.registerAdapter(FinancingInstallmentAdapter());
    if (!Hive.isAdapterRegistered(114)) Hive.registerAdapter(FinancingConversionEventAdapter());

    accounts = await Hive.openBox<Account>('accounts_test');
    transactions = await Hive.openBox<Transaction>('transactions_test');
    contracts = await Hive.openBox<FinancingContract>('financing_contracts_test');
    schedules = await Hive.openBox<FinancingSchedule>('financing_schedules_test');
    installments = await Hive.openBox<FinancingInstallment>('financing_installments_test');
    events = await Hive.openBox<FinancingConversionEvent>('financing_conversion_events_test');
    rules = await Hive.openBox<ScheduleRule>('schedule_rules_test');

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
  });

  tearDownAll(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  Future<void> seedCharge() async {
    await accounts.put(
      'card-1',
      Account(
        id: 'card-1',
        bookId: 'default',
        memberId: 'owner',
        name: 'Test Card',
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
  }

  CreditCardFinancingConversionRequest request({String id = 'conv-1'}) {
    return CreditCardFinancingConversionRequest(
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
          principal: Money.parse('3333.33'),
          interest: Money.zero,
          fees: Money.zero,
        ),
        FinancingInstallmentDraft(
          dueDate: DateTime(2026, 11, 26),
          principal: Money.parse('3333.33'),
          interest: Money.zero,
          fees: Money.zero,
        ),
        FinancingInstallmentDraft(
          dueDate: DateTime(2026, 12, 26),
          principal: Money.parse('3333.34'),
          interest: Money.zero,
          fees: Money.zero,
        ),
      ],
      effectiveDate: DateTime(2026, 9, 27),
      createdAt: DateTime(2026, 9, 27),
    );
  }

  test('conversion creates contractual state without creating a financial transaction', () async {
    await seedCharge();
    final before = transactions.length;

    final result = await operation.execute(request());

    expect(transactions.length, before);
    expect(transactions.get('charge-1')!.amount, 10000);
    expect(result.contract.originReference, 'charge-1');
    expect(result.contract.principal, Money.parse('10000'));
    expect(result.schedule.contractId, 'contract-1');
    expect(result.installments, hasLength(3));
    expect(events.get('conv-1')!.status, financingConversionCompleted);
  });

  test('same conversion request is idempotent and creates one plan', () async {
    await seedCharge();

    final first = await operation.execute(request());
    final second = await operation.execute(request());

    expect(second.alreadyCompleted, isTrue);
    expect(second.contract.contractId, first.contract.contractId);
    expect(contracts.values, hasLength(1));
    expect(schedules.values, hasLength(1));
    expect(installments.values, hasLength(3));
    expect(events.values, hasLength(1));
    expect(transactions.values, hasLength(1));
  });

  test('a charge already converted cannot create another financing plan', () async {
    await seedCharge();
    await operation.execute(request());

    final duplicate = request(id: 'conv-2');
    await expectLater(
      operation.execute(duplicate),
      throwsA(isA<StateError>()),
    );
    expect(contracts.values, hasLength(1));
    expect(schedules.values, hasLength(1));
    expect(installments.values, hasLength(3));
  });

  test('conversion rejects principal schedules that do not equal the charge', () async {
    await seedCharge();
    final invalid = request().copyWithForTest();
    await expectLater(
      operation.execute(invalid),
      throwsA(isA<ArgumentError>()),
    );
    expect(contracts.values, isEmpty);
    expect(schedules.values, isEmpty);
    expect(installments.values, isEmpty);
  });
}

extension on CreditCardFinancingConversionRequest {
  CreditCardFinancingConversionRequest copyWithForTest() {
    return CreditCardFinancingConversionRequest(
      conversionId: conversionId,
      originChargeId: originChargeId,
      contractId: contractId,
      scheduleId: scheduleId,
      scheduleRuleId: scheduleRuleId,
      liabilityAccountId: liabilityAccountId,
      paymentFrequency: paymentFrequency,
      firstDueDate: firstDueDate,
      installments: [
        FinancingInstallmentDraft(
          dueDate: DateTime(2026, 10, 26),
          principal: Money.parse('9999'),
        ),
      ],
      effectiveDate: effectiveDate,
      createdAt: createdAt,
    );
  }
}
