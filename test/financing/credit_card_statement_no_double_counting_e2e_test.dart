import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:wafferly/adapters/account_migration_adapter.dart';
import 'package:wafferly/constants/transaction_constants.dart';
import 'package:wafferly/core/money/money.dart';
import 'package:wafferly/financing/domain/credit_card_financing_conversion.dart';
import 'package:wafferly/financing/domain/credit_card_statement_installment_service.dart';
import 'package:wafferly/financing/domain/credit_card_statement_projection.dart';
import 'package:wafferly/financing/domain/statement_installment_contribution_repository.dart';
import 'package:wafferly/financing/infrastructure/hive_statement_installment_contribution_repository.dart';
import 'package:wafferly/models/account.dart';
import 'package:wafferly/models/enums/account_enums.dart';
import 'package:wafferly/models/enums/frequency.dart';
import 'package:wafferly/models/financing/financing_contract.dart';
import 'package:wafferly/models/financing/financing_conversion_event.dart';
import 'package:wafferly/models/financing/financing_installment.dart';
import 'package:wafferly/models/financing/financing_schedule.dart';
import 'package:wafferly/models/financing/statement_installment_contribution.dart';
import 'package:wafferly/models/schedule_rule.dart';
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
  late Box<StatementInstallmentContribution> contributionBox;
  late StatementInstallmentContributionRepository contributionRepository;
  late CreditCardFinancingConversionOperation conversionOperation;
  late CreditCardStatementInstallmentService installmentService;

  setUpAll(() async {
    directory = await Directory.systemTemp.createTemp('wafferly_statement_e2e_');
    Hive.init(directory.path);
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(AccountMigrationAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(AccountNatureAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(AccountGroupAdapter());
    if (!Hive.isAdapterRegistered(10)) Hive.registerAdapter(TransactionAdapter());
    if (!Hive.isAdapterRegistered(94)) Hive.registerAdapter(FrequencyAdapter());
    if (!Hive.isAdapterRegistered(95)) Hive.registerAdapter(ScheduleRuleAdapter());
    if (!Hive.isAdapterRegistered(110)) Hive.registerAdapter(FinancingContractAdapter());
    if (!Hive.isAdapterRegistered(111)) Hive.registerAdapter(FinancingScheduleAdapter());
    if (!Hive.isAdapterRegistered(112)) Hive.registerAdapter(FinancingInstallmentAdapter());
    if (!Hive.isAdapterRegistered(113)) Hive.registerAdapter(StatementInstallmentContributionAdapter());
    if (!Hive.isAdapterRegistered(114)) Hive.registerAdapter(FinancingConversionEventAdapter());

    accounts = await Hive.openBox<Account>('statement_e2e_accounts');
    transactions = await Hive.openBox<Transaction>('statement_e2e_transactions');
    contracts = await Hive.openBox<FinancingContract>('statement_e2e_contracts');
    schedules = await Hive.openBox<FinancingSchedule>('statement_e2e_schedules');
    installments = await Hive.openBox<FinancingInstallment>('statement_e2e_installments');
    events = await Hive.openBox<FinancingConversionEvent>('statement_e2e_events');
    rules = await Hive.openBox<ScheduleRule>('statement_e2e_rules');
    contributionBox = await Hive.openBox<StatementInstallmentContribution>('statement_e2e_contributions');

    contributionRepository = HiveStatementInstallmentContributionRepository(contributionBox);
    conversionOperation = CreditCardFinancingConversionOperation(
      accounts: accounts,
      transactions: transactions,
      contracts: contracts,
      schedules: schedules,
      installments: installments,
      conversionEvents: events,
      scheduleRules: rules,
    );
    installmentService = CreditCardStatementInstallmentService(
      contracts: contracts,
      installments: installments,
      contributions: contributionRepository,
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
    await contributionBox.clear();
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

  CreditCardFinancingConversionRequest request({required DateTime effectiveDate}) {
    return CreditCardFinancingConversionRequest(
      conversionId: 'conv-1',
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
        ),
        FinancingInstallmentDraft(
          dueDate: DateTime(2026, 11, 26),
          principal: Money.parse('3333.33'),
        ),
        FinancingInstallmentDraft(
          dueDate: DateTime(2026, 12, 26),
          principal: Money.parse('3333.34'),
        ),
      ],
      effectiveDate: effectiveDate,
      createdAt: effectiveDate,
    );
  }

  Future<CreditCardStatementProjection> buildProjection() async {
    return CreditCardStatementProjection(
      transactions: transactions.values,
      conversionEvents: events.values,
      contracts: contracts.values,
      contributions: contributionBox.values,
    );
  }

  test('conversion before statement close replaces the full charge with one eligible installment contribution', () async {
    await seedCharge();
    await conversionOperation.execute(
      request(effectiveDate: DateTime(2026, 9, 27)),
    );

    await installmentService.generateForCycle(
      statementId: 'statement-oct',
      liabilityAccountId: 'card-1',
      cycleStartInclusive: DateTime(2026, 10, 1),
      cycleEndExclusive: DateTime(2026, 11, 1),
      createdAt: DateTime(2026, 10, 31),
    );

    final projection = await buildProjection();
    final lines = projection.project(
      statementId: 'statement-oct',
      liabilityAccountId: 'card-1',
      cycleStartInclusive: DateTime(2026, 9, 1),
      cycleEndExclusive: DateTime(2026, 11, 1),
    );

    expect(lines, hasLength(1));
    expect(lines.single.kind, 'installment_contribution');
    expect(lines.single.originChargeId, 'charge-1');
    expect(lines.single.amount, Money.parse('3333.33'));
    expect(projection.totalFor(
      statementId: 'statement-oct',
      liabilityAccountId: 'card-1',
      cycleStartInclusive: DateTime(2026, 9, 1),
      cycleEndExclusive: DateTime(2026, 11, 1),
    ), Money.parse('3333.33'));
    expect(lines.where((line) => line.kind == 'originating_charge'), isEmpty);
  });

  test('repeated contribution generation still produces one statement line', () async {
    await seedCharge();
    await conversionOperation.execute(
      request(effectiveDate: DateTime(2026, 9, 27)),
    );

    await installmentService.generateForCycle(
      statementId: 'statement-oct',
      liabilityAccountId: 'card-1',
      cycleStartInclusive: DateTime(2026, 10, 1),
      cycleEndExclusive: DateTime(2026, 11, 1),
      createdAt: DateTime(2026, 10, 31),
    );
    await installmentService.generateForCycle(
      statementId: 'statement-oct',
      liabilityAccountId: 'card-1',
      cycleStartInclusive: DateTime(2026, 10, 1),
      cycleEndExclusive: DateTime(2026, 11, 1),
      createdAt: DateTime(2026, 10, 31),
    );

    expect(contributionBox.values, hasLength(1));

    final projection = await buildProjection();
    final lines = projection.project(
      statementId: 'statement-oct',
      liabilityAccountId: 'card-1',
      cycleStartInclusive: DateTime(2026, 9, 1),
      cycleEndExclusive: DateTime(2026, 11, 1),
    );
    expect(lines, hasLength(1));
    expect(lines.single.amount, Money.parse('3333.33'));
  });

  test('future installments are excluded from an earlier statement cycle', () async {
    await seedCharge();
    await conversionOperation.execute(
      request(effectiveDate: DateTime(2026, 9, 27)),
    );

    await installmentService.generateForCycle(
      statementId: 'statement-oct',
      liabilityAccountId: 'card-1',
      cycleStartInclusive: DateTime(2026, 10, 1),
      cycleEndExclusive: DateTime(2026, 11, 1),
      createdAt: DateTime(2026, 10, 31),
    );

    final october = await buildProjection();
    final octoberLines = october.project(
      statementId: 'statement-oct',
      liabilityAccountId: 'card-1',
      cycleStartInclusive: DateTime(2026, 10, 1),
      cycleEndExclusive: DateTime(2026, 11, 1),
    );

    expect(octoberLines, hasLength(1));
    expect(octoberLines.single.installmentId, 'schedule-1|1');

    await installmentService.generateForCycle(
      statementId: 'statement-nov',
      liabilityAccountId: 'card-1',
      cycleStartInclusive: DateTime(2026, 11, 1),
      cycleEndExclusive: DateTime(2026, 12, 1),
      createdAt: DateTime(2026, 11, 30),
    );

    final november = await buildProjection();
    final novemberLines = november.project(
      statementId: 'statement-nov',
      liabilityAccountId: 'card-1',
      cycleStartInclusive: DateTime(2026, 11, 1),
      cycleEndExclusive: DateTime(2026, 12, 1),
    );

    expect(novemberLines, hasLength(1));
    expect(novemberLines.single.installmentId, 'schedule-1|2');
    expect(novemberLines.single.amount, Money.parse('3333.33'));
  });

  test('statement contribution preserves principal interest and financing fees', () async {
    await seedCharge();
    await conversionOperation.execute(
      request(effectiveDate: DateTime(2026, 9, 27)),
    );

    await installments.clear();
    await installments.put(
      'i-interest-fee',
      FinancingInstallment(
        installmentId: 'i-interest-fee',
        contractId: 'contract-1',
        scheduleId: 'schedule-1',
        sequence: 1,
        dueDate: DateTime(2026, 10, 26),
        openingPrincipalValue: '3000',
        principalComponentValue: '3000',
        interestComponentValue: '100',
        feesValue: '25',
        amountValue: '3125',
        status: 'scheduled',
      ),
    );

    await installmentService.generateForCycle(
      statementId: 'statement-oct',
      liabilityAccountId: 'card-1',
      cycleStartInclusive: DateTime(2026, 10, 1),
      cycleEndExclusive: DateTime(2026, 11, 1),
      createdAt: DateTime(2026, 10, 31),
    );

    final contribution = contributionBox.values.single;
    expect(contribution.principal, Money.parse('3000'));
    expect(contribution.interest, Money.parse('100'));
    expect(contribution.fees, Money.parse('25'));
    expect(contribution.contribution, Money.parse('3125'));

    final projection = await buildProjection();
    final lines = projection.project(
      statementId: 'statement-oct',
      liabilityAccountId: 'card-1',
      cycleStartInclusive: DateTime(2026, 10, 1),
      cycleEndExclusive: DateTime(2026, 11, 1),
    );
    expect(lines, hasLength(1));
    expect(lines.single.amount, Money.parse('3125'));
  });

  test('payment transactions are not statement installment contributions', () async {
    await seedCharge();
    await transactions.put(
      'payment-1',
      Transaction(
        id: 'payment-1',
        amount: 500,
        type: TransactionType.transfer,
        fromAccountId: 'cash',
        toAccountId: 'card-1',
        date: DateTime(2026, 10, 15),
        paymentMethod: 'cash',
        currencyCode: 'EGP',
        source: TransactionSource.manual,
      ),
    );

    final projection = await buildProjection();
    final lines = projection.project(
      statementId: 'statement-oct',
      liabilityAccountId: 'card-1',
      cycleStartInclusive: DateTime(2026, 10, 1),
      cycleEndExclusive: DateTime(2026, 11, 1),
    );

    expect(lines, isEmpty);
  });

  test('conversion after statement close does not rewrite the historical statement period', () async {
    await seedCharge();
    await conversionOperation.execute(
      request(effectiveDate: DateTime(2026, 11, 2)),
    );

    expect(contracts.get('contract-1')!.effectiveDate, DateTime(2026, 11, 2));

    final projection = await buildProjection();
    final lines = projection.project(
      statementId: 'statement-sept',
      liabilityAccountId: 'card-1',
      cycleStartInclusive: DateTime(2026, 9, 1),
      cycleEndExclusive: DateTime(2026, 10, 1),
    );

    expect(lines, hasLength(1));
    expect(lines.single.kind, 'originating_charge');
    expect(lines.single.amount, Money.parse('10000'));
    expect(lines.single.installmentId, isNull);
  });
}
