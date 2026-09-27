import 'package:flutter_test/flutter_test.dart';
import 'package:wafferly/core/money/money.dart';
import 'package:wafferly/financing/domain/financing_payment_allocation.dart';
import 'package:wafferly/models/financing/financing_installment.dart';

void main() {
  const calculator = FinancingPaymentAllocationCalculator();

  FinancingInstallment installment({
    required String id,
    required DateTime dueDate,
    String status = 'scheduled',
  }) {
    return FinancingInstallment(
      installmentId: id,
      contractId: 'contract-1',
      scheduleId: 'schedule-1',
      sequence: 1,
      dueDate: dueDate,
      openingPrincipalValue: '1000',
      principalComponentValue: '900',
      interestComponentValue: '100',
      feesValue: '0',
      amountValue: '1000',
      status: status,
    );
  }

  FinancingInstallmentPaymentTarget target({
    required String id,
    required DateTime dueDate,
    String status = 'scheduled',
    String fees = '0',
    String interest = '100',
    String principal = '900',
  }) {
    return FinancingInstallmentPaymentTarget(
      installment: installment(id: id, dueDate: dueDate, status: status),
      outstandingFees: Money.parse(fees),
      outstandingInterest: Money.parse(interest),
      outstandingPrincipal: Money.parse(principal),
    );
  }

  test('allocates one installment in Fees -> Interest -> Principal order', () {
    final result = calculator.allocateToInstallment(
      payment: Money.parse('250'),
      target: target(
        id: 'i-1',
        dueDate: DateTime(2026, 9, 10),
        fees: '30',
        interest: '100',
        principal: '900',
      ),
    );

    expect(result.fees, Money.parse('30'));
    expect(result.interest, Money.parse('100'));
    expect(result.principal, Money.parse('120'));
    expect(result.allocatedAmount, Money.parse('250'));
    expect(result.unallocatedAmount, Money.zero);
  });

  test('supports partial allocation within a component', () {
    final result = calculator.allocateToInstallment(
      payment: Money.parse('40'),
      target: target(
        id: 'i-1',
        dueDate: DateTime(2026, 9, 10),
        fees: '60',
        interest: '100',
        principal: '900',
      ),
    );

    expect(result.fees, Money.parse('40'));
    expect(result.interest, Money.zero);
    expect(result.principal, Money.zero);
    expect(result.unallocatedAmount, Money.zero);
  });

  test('allocates across installments oldest eligible first', () {
    final result = calculator.allocateAcrossInstallments(
      payment: Money.parse('1500'),
      allocationDate: DateTime(2026, 9, 20),
      targets: [
        target(id: 'i-3', dueDate: DateTime(2026, 10, 20)),
        target(id: 'i-1', dueDate: DateTime(2026, 9, 10)),
        target(id: 'i-2', dueDate: DateTime(2026, 9, 20)),
      ],
    );

    expect(result.allocations.map((e) => e.installmentId), ['i-1', 'i-2']);
    expect(result.allocations.first.allocatedAmount, Money.parse('1000'));
    expect(result.allocations[1].allocatedAmount, Money.parse('500'));
    expect(result.unallocatedAmount, Money.zero);
  });

  test('orders overdue before due today before future', () {
    final result = calculator.allocateAcrossInstallments(
      payment: Money.parse('3000'),
      allocationDate: DateTime(2026, 9, 20),
      targets: [
        target(id: 'future', dueDate: DateTime(2026, 10, 1)),
        target(id: 'today', dueDate: DateTime(2026, 9, 20)),
        target(id: 'overdue', dueDate: DateTime(2026, 9, 1)),
      ],
    );

    expect(result.allocations.map((e) => e.installmentId), [
      'overdue',
      'today',
      'future',
    ]);
  });

  test('uses installment id as stable tie-breaker for same due date', () {
    final result = calculator.allocateAcrossInstallments(
      payment: Money.parse('2000'),
      allocationDate: DateTime(2026, 9, 20),
      targets: [
        target(id: 'b', dueDate: DateTime(2026, 9, 10)),
        target(id: 'a', dueDate: DateTime(2026, 9, 10)),
      ],
    );

    expect(result.allocations.map((e) => e.installmentId), ['a', 'b']);
  });

  test('excludes settled, cancelled, and superseded installments', () {
    final result = calculator.allocateAcrossInstallments(
      payment: Money.parse('1000'),
      allocationDate: DateTime(2026, 9, 20),
      targets: [
        target(id: 'settled', dueDate: DateTime(2026, 9, 1), status: 'settled'),
        target(id: 'cancelled', dueDate: DateTime(2026, 9, 2), status: 'cancelled'),
        target(id: 'superseded', dueDate: DateTime(2026, 9, 3), status: 'superseded'),
        target(id: 'eligible', dueDate: DateTime(2026, 9, 4)),
      ],
    );

    expect(result.allocations.map((e) => e.installmentId), ['eligible']);
  });

  test('returns unallocated remainder for overpayment without mutation', () {
    final result = calculator.allocateAcrossInstallments(
      payment: Money.parse('1200'),
      allocationDate: DateTime(2026, 9, 20),
      targets: [
        target(id: 'i-1', dueDate: DateTime(2026, 9, 10), interest: '100', principal: '900'),
      ],
    );

    expect(result.allocatedAmount, Money.parse('1000'));
    expect(result.unallocatedAmount, Money.parse('200'));
    expect(result.isFullyAllocated, isFalse);
  });

  test('strict boundary rejects non-zero unallocated amount', () {
    final result = calculator.allocateAcrossInstallments(
      payment: Money.parse('1200'),
      allocationDate: DateTime(2026, 9, 20),
      targets: [
        target(id: 'i-1', dueDate: DateTime(2026, 9, 10), interest: '100', principal: '900'),
      ],
    );

    expect(
      () => calculator.requireFullyAllocated(result),
      throwsArgumentError,
    );
  });

  test('rejects zero and negative payments', () {
    expect(
      () => calculator.allocateAcrossInstallments(
        payment: Money.zero,
        allocationDate: DateTime(2026, 9, 20),
        targets: const [],
      ),
      throwsArgumentError,
    );
    expect(
      () => calculator.allocateAcrossInstallments(
        payment: Money.parse('-1'),
        allocationDate: DateTime(2026, 9, 20),
        targets: const [],
      ),
      throwsArgumentError,
    );
  });
}
