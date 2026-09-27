import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:wafferly/core/money/money.dart';
import 'package:wafferly/financing/domain/credit_card_statement_installment_service.dart';
import 'package:wafferly/financing/domain/statement_installment_contribution_repository.dart';
import 'package:wafferly/financing/infrastructure/hive_statement_installment_contribution_repository.dart';
import 'package:wafferly/models/financing/financing_contract.dart';
import 'package:wafferly/models/financing/financing_installment.dart';
import 'package:wafferly/models/financing/statement_installment_contribution.dart';

void main() {
  late Directory directory;
  late Box<FinancingContract> contracts;
  late Box<FinancingInstallment> installments;
  late Box<StatementInstallmentContribution> contributionBox;
  late StatementInstallmentContributionRepository contributions;
  late CreditCardStatementInstallmentService service;

  setUpAll(() async {
    directory = await Directory.systemTemp.createTemp('wafferly_statement_installments_');
    Hive.init(directory.path);
    if (!Hive.isAdapterRegistered(110)) {
      Hive.registerAdapter(FinancingContractAdapter());
    }
    if (!Hive.isAdapterRegistered(112)) {
      Hive.registerAdapter(FinancingInstallmentAdapter());
    }
    if (!Hive.isAdapterRegistered(113)) {
      Hive.registerAdapter(StatementInstallmentContributionAdapter());
    }

    contracts = await Hive.openBox<FinancingContract>('statement_contracts_test');
    installments = await Hive.openBox<FinancingInstallment>('statement_installments_test');
    contributionBox = await Hive.openBox<StatementInstallmentContribution>('statement_contributions_test');
  });

  setUp(() async {
    await contracts.clear();
    await installments.clear();
    await contributionBox.clear();
    contributions = HiveStatementInstallmentContributionRepository(contributionBox);
    service = CreditCardStatementInstallmentService(
      contracts: contracts,
      installments: installments,
      contributions: contributions,
    );
  });

  tearDownAll(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  Future<void> seedPlan() async {
    await contracts.put(
      'contract-1',
      FinancingContract(
        contractId: 'contract-1',
        liabilityAccountId: 'card-1',
        originReference: 'charge-1',
        principalValue: '10000',
        installmentCount: 3,
        paymentFrequency: 'monthly',
        firstDueDate: DateTime(2026, 10, 26),
        lifecycleState: 'active',
        effectiveDate: DateTime(2026, 9, 27),
        createdAt: DateTime(2026, 9, 27),
      ),
    );

    await installments.putAll({
      'i-1': _installment(
        id: 'i-1',
        sequence: 1,
        dueDate: DateTime(2026, 10, 26),
        principal: '3333.33',
        interest: '100',
        fees: '25',
      ),
      'i-2': _installment(
        id: 'i-2',
        sequence: 2,
        dueDate: DateTime(2026, 11, 26),
        principal: '3333.33',
        interest: '90',
        fees: '20',
      ),
    });
  }

  test('only installments eligible for the statement cycle contribute once', () async {
    await seedPlan();

    final first = await service.generateForCycle(
      statementId: 'statement-2026-10',
      liabilityAccountId: 'card-1',
      cycleStartInclusive: DateTime(2026, 10, 1),
      cycleEndExclusive: DateTime(2026, 11, 1),
      createdAt: DateTime(2026, 11, 1, 12),
    );

    expect(first, hasLength(1));
    expect(first.single.installmentId, 'i-1');
    expect(first.single.principal, Money.parse('3333.33'));
    expect(first.single.interest, Money.parse('100'));
    expect(first.single.fees, Money.parse('25'));
    expect(first.single.contribution, Money.parse('3458.33'));
    expect(contributions.values, hasLength(1));

    final second = await service.generateForCycle(
      statementId: 'statement-2026-10',
      liabilityAccountId: 'card-1',
      cycleStartInclusive: DateTime(2026, 10, 1),
      cycleEndExclusive: DateTime(2026, 11, 1),
      createdAt: DateTime(2026, 11, 1, 12),
    );

    expect(second, hasLength(1));
    expect(contributions.values, hasLength(1));
  });

  test('future installment does not contribute to an earlier statement', () async {
    await seedPlan();

    final result = await service.generateForCycle(
      statementId: 'statement-2026-10',
      liabilityAccountId: 'card-1',
      cycleStartInclusive: DateTime(2026, 10, 1),
      cycleEndExclusive: DateTime(2026, 11, 1),
      createdAt: DateTime(2026, 11, 1, 12),
    );

    expect(result.map((item) => item.installmentId), contains('i-1'));
    expect(result.map((item) => item.installmentId), isNot(contains('i-2')));
  });

  test('installments from another card are excluded', () async {
    await seedPlan();
    await contracts.put(
      'contract-other',
      FinancingContract(
        contractId: 'contract-other',
        liabilityAccountId: 'card-2',
        originReference: 'charge-2',
        principalValue: '5000',
        installmentCount: 1,
        paymentFrequency: 'monthly',
        firstDueDate: DateTime(2026, 10, 26),
        lifecycleState: 'active',
        effectiveDate: DateTime(2026, 9, 27),
        createdAt: DateTime(2026, 9, 27),
      ),
    );
    await installments.put(
      'i-other',
      _installment(
        id: 'i-other',
        sequence: 1,
        dueDate: DateTime(2026, 10, 26),
        principal: '5000',
      ).copyWithContract('contract-other'),
    );

    final result = await service.generateForCycle(
      statementId: 'statement-2026-10',
      liabilityAccountId: 'card-1',
      cycleStartInclusive: DateTime(2026, 10, 1),
      cycleEndExclusive: DateTime(2026, 11, 1),
      createdAt: DateTime(2026, 11, 1, 12),
    );

    expect(result.map((item) => item.installmentId), ['i-1']);
  });

  test('contribution identity cannot be rebound to different values', () async {
    final contribution = StatementInstallmentContribution(
      contributionId: 'statement-1|i-1',
      statementId: 'statement-1',
      contractId: 'contract-1',
      installmentId: 'i-1',
      principalValue: '100',
      interestValue: '10',
      feesValue: '0',
      contributionValue: '110',
      createdAt: DateTime(2026, 10, 1),
    );

    await contributions.put(contribution);

    await expectLater(
      contributions.put(
        StatementInstallmentContribution(
          contributionId: 'statement-1|i-1',
          statementId: 'statement-1',
          contractId: 'contract-1',
          installmentId: 'i-1',
          principalValue: '101',
          interestValue: '10',
          feesValue: '0',
          contributionValue: '111',
          createdAt: DateTime(2026, 10, 1),
        ),
      ),
      throwsA(isA<StateError>()),
    );
  });
}

FinancingInstallment _installment({
  required String id,
  required int sequence,
  required DateTime dueDate,
  required String principal,
  String interest = '0',
  String fees = '0',
}) {
  final amount = Money.parse(principal) + Money.parse(interest) + Money.parse(fees);
  return FinancingInstallment(
    installmentId: id,
    contractId: 'contract-1',
    scheduleId: 'schedule-1',
    sequence: sequence,
    dueDate: dueDate,
    openingPrincipalValue: principal,
    principalComponentValue: principal,
    interestComponentValue: interest,
    feesValue: fees,
    amountValue: amount.toString(),
    status: 'scheduled',
  );
}

extension on FinancingInstallment {
  FinancingInstallment copyWithContract(String contractId) {
    return FinancingInstallment(
      installmentId: installmentId,
      contractId: contractId,
      scheduleId: scheduleId,
      occurrenceId: occurrenceId,
      sequence: sequence,
      dueDate: dueDate,
      openingPrincipalValue: openingPrincipalValue,
      principalComponentValue: principalComponentValue,
      interestComponentValue: interestComponentValue,
      feesValue: feesValue,
      amountValue: amountValue,
      status: status,
    );
  }
}
