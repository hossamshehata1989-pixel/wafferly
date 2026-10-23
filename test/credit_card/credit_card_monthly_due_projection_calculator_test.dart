import 'package:flutter_test/flutter_test.dart';
import 'package:wafferly/application/credit_card/credit_card_monthly_due_projection_calculator.dart';
import 'package:wafferly/application/credit_card/credit_card_due_date_policy.dart';
import 'package:wafferly/constants/transaction_constants.dart';
import 'package:wafferly/core/money/money.dart';
import 'package:wafferly/models/financing/financing_contract.dart';
import 'package:wafferly/models/financing/financing_installment.dart';
import 'package:wafferly/models/transaction.dart';

void main() {
  const calculator = CreditCardMonthlyDueProjectionCalculator();
  final now = DateTime(2026, 10, 11, 12);

  Transaction charge({
    required String id,
    required double amount,
    DateTime? date,
  }) => Transaction(
        id: id,
        amount: amount,
        type: TransactionType.creditCardCharge,
        toAccountId: 'card-1',
        categoryId: 'supermarket',
        date: date ?? DateTime(2026, 10, 11),
        currencyCode: 'EGP',
        source: TransactionSource.creditCardCharge,
      );

  FinancingContract contract() => FinancingContract(
        contractId: 'contract-1',
        liabilityAccountId: 'card-1',
        originReference: 'charge-installment',
        principalValue: '500',
        installmentCount: 2,
        paymentFrequency: 'monthly',
        firstDueDate: DateTime(2026, 10, 11),
        lifecycleState: 'active',
        effectiveDate: DateTime(2026, 10, 11),
        createdAt: DateTime(2026, 10, 11),
      );

  FinancingInstallment installment({
    required String id,
    required DateTime dueDate,
    required double amount,
    required int sequence,
  }) => FinancingInstallment(
        installmentId: id,
        contractId: 'contract-1',
        scheduleId: 'schedule-1',
        sequence: sequence,
        dueDate: dueDate,
        openingPrincipalValue: amount.toString(),
        principalComponentValue: amount.toString(),
        interestComponentValue: '0',
        feesValue: '0',
        amountValue: amount.toString(),
        status: 'scheduled',
      );

  test('unconverted purchases without statement settings belong to next month', () {
    final result = calculator.calculate(
      liabilityAccountId: 'card-1',
      charges: [
        charge(id: 'charge-1', amount: 200),
        charge(id: 'charge-2', amount: 3500),
      ],
      payments: const [],
      contracts: const [],
      installments: const [],
      statementDay: null,
      paymentDueDay: null,
      currentOutstanding: Money.fromDouble(3700),
      now: now,
    );

    expect(result.thisMonthTotal, Money.zero);
    expect(result.nextMonthExpenses, Money.fromDouble(3700));
  });

  test('installment due today is counted in this month', () {
    final result = calculator.calculate(
      liabilityAccountId: 'card-1',
      charges: [charge(id: 'charge-installment', amount: 500)],
      payments: const [],
      contracts: [contract()],
      installments: [
        installment(
          id: 'installment-1',
          dueDate: DateTime(2026, 10, 11),
          amount: 250,
          sequence: 1,
        ),
        installment(
          id: 'installment-2',
          dueDate: DateTime(2026, 11, 11),
          amount: 250,
          sequence: 2,
        ),
      ],
      statementDay: null,
      paymentDueDay: null,
      currentOutstanding: Money.fromDouble(500),
      now: now,
    );

    expect(result.thisMonthInstallments, Money.fromDouble(250));
    expect(result.nextMonthInstallments, Money.fromDouble(250));
    expect(result.thisMonthExpenses, Money.zero);
  });

  test('payment excess reduces the next scheduled installment', () {
    final result = calculator.calculate(
      liabilityAccountId: 'card-1',
      charges: [charge(id: 'charge-installment', amount: 500)],
      payments: [
        Transaction(
          id: 'payment-1',
          amount: 400,
          type: TransactionType.transfer,
          fromAccountId: 'bank-1',
          toAccountId: 'card-1',
          date: DateTime(2026, 10, 11, 13),
          currencyCode: 'EGP',
          source: TransactionSource.creditCardPayment,
        ),
      ],
      contracts: [contract()],
      installments: [
        installment(
          id: 'installment-1',
          dueDate: DateTime(2026, 10, 11),
          amount: 250,
          sequence: 1,
        ),
        installment(
          id: 'installment-2',
          dueDate: DateTime(2026, 11, 11),
          amount: 250,
          sequence: 2,
        ),
      ],
      statementDay: null,
      paymentDueDay: null,
      currentOutstanding: Money.fromDouble(100),
      now: DateTime(2026, 10, 12),
    );

    expect(result.thisMonthInstallments, Money.zero);
    expect(result.nextMonthInstallments, Money.fromDouble(100));
  });
  test('installment due on the card payment day stays in next month', () {
    final result = calculator.calculate(
      liabilityAccountId: 'card-1',
      charges: [
        charge(
          id: 'charge-installment',
          amount: 500,
          date: DateTime(2026, 10, 11),
        ),
      ],
      payments: const [],
      contracts: [contract()],
      installments: [
        installment(
          id: 'installment-nov',
          dueDate: DateTime(2026, 11, 15),
          amount: 250,
          sequence: 1,
        ),
        installment(
          id: 'installment-dec',
          dueDate: DateTime(2026, 12, 15),
          amount: 250,
          sequence: 2,
        ),
      ],
      statementDay: 14,
      paymentDueDay: 15,
      currentOutstanding: Money.fromDouble(500),
      now: DateTime(2026, 10, 11, 12),
    );

    // Nov 15 is already the contractual installment due date. It must not be
    // reinterpreted as a purchase made after the Nov 14 statement close.
    expect(result.thisMonthInstallments, Money.zero);
    expect(result.nextMonthInstallments, Money.fromDouble(250));
    expect(result.nextMonthTotal, Money.fromDouble(250));
  });

  test('installment due today remains due this month with configured cycle', () {
    final result = calculator.calculate(
      liabilityAccountId: 'card-1',
      charges: [
        charge(
          id: 'charge-installment',
          amount: 500,
          date: DateTime(2026, 10, 11),
        ),
      ],
      payments: const [],
      contracts: [contract()],
      installments: [
        installment(
          id: 'installment-today',
          dueDate: DateTime(2026, 10, 11),
          amount: 250,
          sequence: 1,
        ),
        installment(
          id: 'installment-next',
          dueDate: DateTime(2026, 11, 11),
          amount: 250,
          sequence: 2,
        ),
      ],
      statementDay: 14,
      paymentDueDay: 15,
      currentOutstanding: Money.fromDouble(500),
      now: DateTime(2026, 10, 11, 12),
    );

    expect(result.thisMonthInstallments, Money.fromDouble(250));
    expect(result.nextMonthInstallments, Money.fromDouble(250));
  });

  test('ordinary purchase maps to the next payment month with configured cycle', () {
    final result = calculator.calculate(
      liabilityAccountId: 'card-1',
      charges: [
        charge(
          id: 'regular-purchase',
          amount: 500,
          date: DateTime(2026, 10, 12),
        ),
      ],
      payments: const [],
      contracts: const [],
      installments: const [],
      statementDay: 14,
      paymentDueDay: 15,
      currentOutstanding: Money.fromDouble(500),
      now: DateTime(2026, 10, 12, 12),
    );

    expect(result.thisMonthTotal, Money.zero);
    expect(result.nextMonthExpenses, Money.fromDouble(500));
  });


  test('offset due date keeps October purchase visible in December forecast', () {
    final result = calculator.calculate(
      liabilityAccountId: 'card-1',
      charges: [
        charge(
          id: 'october-purchase',
          amount: 250,
          date: DateTime(2026, 10, 22),
        ),
      ],
      payments: const [],
      contracts: const [],
      installments: const [],
      statementDay: 7,
      paymentDueDay: null,
      dueDateCalculationMethod: CreditCardDueDatePolicy.fixedOffsetDays,
      dueDaysAfterStatement: 25,
      weekendHolidayPolicy: CreditCardDueDatePolicy.noAdjustment,
      currentOutstanding: Money.fromDouble(250),
      now: DateTime(2026, 10, 23, 12),
      monthsToProject: 12,
    );

    expect(result.thisMonthTotal, Money.zero);
    expect(result.nextMonthTotal, Money.zero);
    expect(result.months[2].monthStart, DateTime(2026, 12, 1));
    expect(result.months[2].expenses, Money.fromDouble(250));
    expect(result.months[2].total, Money.fromDouble(250));
  });

}
