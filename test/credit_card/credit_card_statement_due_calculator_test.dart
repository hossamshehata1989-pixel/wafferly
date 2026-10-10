import 'package:flutter_test/flutter_test.dart';
import 'package:wafferly/application/credit_card/credit_card_statement_due_calculator.dart';
import 'package:wafferly/constants/transaction_constants.dart';
import 'package:wafferly/core/money/money.dart';
import 'package:wafferly/credit_card/domain/credit_card_profile.dart';
import 'package:wafferly/models/financing/financing_contract.dart';
import 'package:wafferly/models/financing/financing_installment.dart';
import 'package:wafferly/models/transaction.dart';

void main() {
  const calculator = CreditCardStatementDueCalculator();

  CreditCardProfile profile({int? closingDay = 5, int? dueDay = 20}) {
    return CreditCardProfile(
      id: 'profile-1',
      accountId: 'card-1',
      creditLimitValue: '10000',
      statementDay: closingDay,
      paymentDueDay: dueDay,
    );
  }

  Transaction charge(String id, double amount, DateTime date) => Transaction(
        id: id,
        amount: amount,
        type: TransactionType.creditCardCharge,
        toAccountId: 'card-1',
        date: date,
        currencyCode: 'EGP',
        source: TransactionSource.creditCardCharge,
      );

  Transaction payment(String id, double amount, DateTime date) => Transaction(
        id: id,
        amount: amount,
        type: TransactionType.transfer,
        fromAccountId: 'bank-1',
        toAccountId: 'card-1',
        date: date,
        currencyCode: 'EGP',
        source: TransactionSource.creditCardPayment,
      );

  FinancingInstallment installment({
    required String id,
    required String contractId,
    required double amount,
    required DateTime dueDate,
  }) => FinancingInstallment(
        installmentId: id,
        contractId: contractId,
        scheduleId: 'schedule-$contractId',
        sequence: 1,
        dueDate: dueDate,
        openingPrincipalValue: amount.toString(),
        principalComponentValue: amount.toString(),
        interestComponentValue: '0',
        feesValue: '0',
        amountValue: amount.toString(),
        status: 'scheduled',
      );

  FinancingContract contract({
    required String id,
    required String originReference,
    required DateTime effectiveDate,
  }) => FinancingContract(
        contractId: id,
        liabilityAccountId: 'card-1',
        originReference: originReference,
        principalValue: '1000',
        installmentCount: 1,
        paymentFrequency: 'monthly',
        firstDueDate: DateTime(2026, 9, 4),
        lifecycleState: 'active',
        effectiveDate: effectiveDate,
        createdAt: DateTime(2026, 9, 4),
      );

  test('calculates this month statement due and subtracts recorded payment', () {
    final result = calculator.calculate(
      liabilityAccountId: 'card-1',
      profile: profile(),
      currentOutstanding: Money.parse('5000'),
      charges: [charge('purchase-1', 1000, DateTime(2026, 9, 4))],
      payments: [payment('payment-1', 250, DateTime(2026, 10, 10))],
      installments: const [],
      contracts: const [],
      now: DateTime(2026, 10, 11),
    );

    expect(result.isConfigured, isTrue);
    expect(result.statementCloseDate, DateTime(2026, 9, 5));
    expect(result.paymentDueDate, DateTime(2026, 10, 20));
    expect(result.amountDue, Money.parse('750'));
  });

  test('allocates payments to older statements before current statement', () {
    final result = calculator.calculate(
      liabilityAccountId: 'card-1',
      profile: profile(),
      currentOutstanding: Money.parse('5000'),
      charges: [
        charge('old-purchase', 200, DateTime(2026, 8, 4)),
        charge('current-purchase', 1000, DateTime(2026, 9, 4)),
      ],
      payments: [payment('payment-1', 250, DateTime(2026, 9, 25))],
      installments: const [],
      contracts: const [],
      now: DateTime(2026, 10, 11),
    );

    expect(result.amountDue, Money.parse('950'));
  });

  test('clamps end-of-month statement and due dates without overflow', () {
    final result = calculator.calculate(
      liabilityAccountId: 'card-1',
      profile: profile(closingDay: 31, dueDay: 31),
      currentOutstanding: Money.parse('5000'),
      charges: [charge('feb-purchase', 500, DateTime(2026, 2, 15))],
      payments: const [],
      installments: const [],
      contracts: const [],
      now: DateTime(2026, 3, 10),
    );

    expect(result.statementCloseDate, DateTime(2026, 2, 28));
    expect(result.paymentDueDate, DateTime(2026, 3, 31));
    expect(result.amountDue, Money.parse('500'));
  });

  test('handles December-to-January statement and due-date rollover', () {
    final result = calculator.calculate(
      liabilityAccountId: 'card-1',
      profile: profile(closingDay: 31, dueDay: 31),
      currentOutstanding: Money.parse('1000'),
      charges: [charge('dec-purchase', 400, DateTime(2026, 12, 31))],
      payments: const [],
      installments: const [],
      contracts: const [],
      now: DateTime(2027, 1, 10),
    );

    expect(result.statementCloseDate, DateTime(2026, 12, 31));
    expect(result.paymentDueDate, DateTime(2027, 1, 31));
    expect(result.amountDue, Money.parse('400'));
  });

  test('statement due never exceeds current outstanding liability', () {
    final result = calculator.calculate(
      liabilityAccountId: 'card-1',
      profile: profile(),
      currentOutstanding: Money.parse('600'),
      charges: [charge('purchase-1', 1000, DateTime(2026, 9, 4))],
      payments: const [],
      installments: const [],
      contracts: const [],
      now: DateTime(2026, 10, 11),
    );

    expect(result.amountDue, Money.parse('600'));
  });

  test('converted charge is replaced by its scheduled installment', () {
    final result = calculator.calculate(
      liabilityAccountId: 'card-1',
      profile: profile(),
      currentOutstanding: Money.parse('1000'),
      charges: [charge('purchase-1', 1000, DateTime(2026, 9, 4))],
      payments: const [],
      installments: [
        installment(
          id: 'installment-1',
          contractId: 'contract-1',
          amount: 250,
          dueDate: DateTime(2026, 9, 4),
        ),
      ],
      contracts: [
        contract(
          id: 'contract-1',
          originReference: 'purchase-1',
          effectiveDate: DateTime(2026, 9, 4),
        ),
      ],
      now: DateTime(2026, 10, 11),
    );

    expect(result.amountDue, Money.parse('250'));
  });

  test('conversion after statement close does not rewrite that statement', () {
    final result = calculator.calculate(
      liabilityAccountId: 'card-1',
      profile: profile(),
      currentOutstanding: Money.parse('1000'),
      charges: [charge('purchase-1', 1000, DateTime(2026, 9, 4))],
      payments: const [],
      installments: const [],
      contracts: [
        contract(
          id: 'contract-1',
          originReference: 'purchase-1',
          effectiveDate: DateTime(2026, 9, 6),
        ),
      ],
      now: DateTime(2026, 10, 11),
    );

    expect(result.amountDue, Money.parse('1000'));
  });

  test('requires statement closing and due-day configuration', () {
    final result = calculator.calculate(
      liabilityAccountId: 'card-1',
      profile: profile(closingDay: null, dueDay: 20),
      currentOutstanding: Money.parse('1000'),
      charges: const [],
      payments: const [],
      installments: const [],
      contracts: const [],
      now: DateTime(2026, 10, 11),
    );

    expect(result.isConfigured, isFalse);
    expect(result.amountDue, Money.zero);
  });
}
