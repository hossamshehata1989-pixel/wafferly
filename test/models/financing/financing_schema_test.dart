import 'package:flutter_test/flutter_test.dart';
import 'package:wafferly/core/money/money.dart';
import 'package:wafferly/models/financing/financing_contract.dart';
import 'package:wafferly/models/financing/financing_installment.dart';
import 'package:wafferly/models/financing/financing_schedule.dart';
import 'package:wafferly/models/financing/statement_installment_contribution.dart';

void main() {
  test('financing contract keeps Money-native principal semantics', () {
    final contract = FinancingContract(
      contractId: 'contract-1',
      liabilityAccountId: 'card-1',
      originReference: 'charge-1',
      principalValue: '10000.25',
      installmentCount: 5,
      paymentFrequency: 'monthly',
      firstDueDate: DateTime(2026, 10, 26),
      lifecycleState: 'active',
      effectiveDate: DateTime(2026, 9, 27),
      createdAt: DateTime(2026, 9, 27),
    );

    expect(contract.principal, Money.parse('10000.25'));
    expect(contract.originReference, 'charge-1');
  });

  test('installment amount is exactly principal + interest + fees', () {
    final installment = FinancingInstallment(
      installmentId: 'i-1',
      contractId: 'contract-1',
      scheduleId: 'schedule-1',
      sequence: 1,
      dueDate: DateTime(2026, 10, 26),
      openingPrincipalValue: '10000',
      principalComponentValue: '1800',
      interestComponentValue: '200',
      feesValue: '50',
      amountValue: '2050',
      status: 'scheduled',
    );

    expect(installment.calculatedComponentTotal, Money.parse('2050'));
    expect(installment.amount, Money.parse('2050'));
  });

  test('statement contribution identity is statement + installment', () {
    expect(
      StatementInstallmentContribution.idFor(
        statementId: 'statement-1',
        installmentId: 'installment-1',
      ),
      'statement-1|installment-1',
    );
  });

  test('schedule links one financing contract to existing schedule rule', () {
    final schedule = FinancingSchedule(
      scheduleId: 'schedule-1',
      contractId: 'contract-1',
      scheduleRuleId: 'rule-1',
      installmentCount: 12,
      status: 'active',
      createdAt: DateTime(2026, 9, 27),
    );

    expect(schedule.contractId, 'contract-1');
    expect(schedule.scheduleRuleId, 'rule-1');
  });
}
