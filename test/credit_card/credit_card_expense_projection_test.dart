import 'package:flutter_test/flutter_test.dart';
import 'package:wafferly/application/credit_card/credit_card_expense_projection_service.dart';
import 'package:wafferly/constants/transaction_constants.dart';
import 'package:wafferly/credit_card/domain/credit_card_profile.dart';
import 'package:wafferly/models/account.dart';
import 'package:wafferly/models/enums/account_enums.dart';
import 'package:wafferly/models/financing/financing_contract.dart';
import 'package:wafferly/models/financing/financing_installment.dart';
import 'package:wafferly/models/transaction.dart';

void main() {
  Account card() => Account(
        id: 'card-1',
        bookId: 'default',
        memberId: 'owner',
        name: 'Test Card',
        type: 'creditCard',
        currency: 'EGP',
        createdAt: DateTime(2026, 1, 1),
        group: AccountGroup.liabilities,
        nature: AccountNature.liability,
      );

  CreditCardProfile profile({int? statementDay, int? paymentDueDay}) =>
      CreditCardProfile(
        id: 'profile-1',
        accountId: 'card-1',
        creditLimitValue: '15000',
        statementDay: statementDay,
        paymentDueDay: paymentDueDay,
      );

  Transaction charge({
    String id = 'charge-1',
    double amount = 3500,
    DateTime? date,
  }) => Transaction(
        id: id,
        amount: amount,
        type: TransactionType.creditCardCharge,
        toAccountId: 'card-1',
        categoryId: 'supermarket',
        subCategoryId: 'groceries',
        date: date ?? DateTime(2026, 10, 11),
        note: 'Supermarket purchase',
        paymentMethod: 'credit_card',
        currencyCode: 'EGP',
        source: TransactionSource.creditCardCharge,
      );

  FinancingContract contract({
    String contractId = 'contract-1',
    String originReference = 'charge-1',
    DateTime? effectiveDate,
    String state = 'active',
  }) => FinancingContract(
        contractId: contractId,
        liabilityAccountId: 'card-1',
        originReference: originReference,
        principalValue: '3000',
        installmentCount: 12,
        paymentFrequency: 'monthly',
        firstDueDate: DateTime(2026, 10, 11),
        lifecycleState: state,
        effectiveDate: effectiveDate ?? DateTime(2026, 10, 11),
        createdAt: effectiveDate ?? DateTime(2026, 10, 11),
      );

  FinancingInstallment installment({
    required String id,
    required DateTime dueDate,
    required double amount,
    int sequence = 1,
    String status = 'scheduled',
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
        status: status,
      );

  List<Transaction> project({
    required Iterable<Transaction> transactions,
    Iterable<CreditCardProfile> profiles = const <CreditCardProfile>[],
    Iterable<FinancingContract> contracts = const <FinancingContract>[],
    Iterable<FinancingInstallment> installments = const <FinancingInstallment>[],
    required DateTime startDate,
    required DateTime endDate,
    DateTime? asOf,
  }) => CreditCardExpenseProjectionService.projectFromData(
        transactions: transactions,
        accounts: [card()],
        profiles: profiles,
        contracts: contracts,
        installments: installments,
        startDate: startDate,
        endDate: endDate,
        asOf: asOf ?? DateTime(2026, 10, 11),
      );

  test('unconverted card purchases appear in next month even without cycle settings', () {
    final projected = project(
      transactions: [charge()],
      startDate: DateTime(2026, 11, 1),
      endDate: DateTime(2026, 11, 30),
    );

    expect(projected, hasLength(1));
    expect(projected.single.type, TransactionType.expense);
    expect(projected.single.amount, 3500);
    expect(projected.single.date, DateTime(2026, 11, 11));
    expect(projected.single.categoryId, 'supermarket');
  });

  test('installment due today appears in this month and full converted charge is not duplicated', () {
    final projected = project(
      transactions: [charge(amount: 3000)],
      profiles: [profile()],
      contracts: [contract()],
      installments: [
        installment(id: 'installment-1', dueDate: DateTime(2026, 10, 11), amount: 250),
        installment(id: 'installment-2', dueDate: DateTime(2026, 11, 11), amount: 250, sequence: 2),
      ],
      startDate: DateTime(2026, 10, 1),
      endDate: DateTime(2026, 10, 31),
    );

    expect(projected, hasLength(1));
    expect(projected.single.id, 'cc-expense-installment:installment-1');
    expect(projected.single.amount, 250);
    expect(projected.single.date, DateTime(2026, 10, 11));
  });

  test('configured billing cycle maps unconverted purchase to the due month', () {
    final projected = project(
      transactions: [charge(date: DateTime(2026, 10, 11))],
      profiles: [profile(statementDay: 5, paymentDueDay: 20)],
      startDate: DateTime(2026, 12, 1),
      endDate: DateTime(2026, 12, 31),
    );

    expect(projected, hasLength(1));
    expect(projected.single.date, DateTime(2026, 12, 20));
  });

  test('conversion after statement close keeps old purchase due separate from later installments', () {
    final projected = project(
      transactions: [charge(date: DateTime(2026, 9, 4))],
      profiles: [profile(statementDay: 5, paymentDueDay: 20)],
      contracts: [contract(effectiveDate: DateTime(2026, 9, 6))],
      installments: [
        installment(id: 'installment-next', dueDate: DateTime(2026, 11, 1), amount: 250),
      ],
      startDate: DateTime(2026, 10, 1),
      endDate: DateTime(2026, 10, 31),
    );

    expect(projected, hasLength(1));
    expect(projected.single.id, 'cc-expense-charge:charge-1');
    expect(projected.single.amount, 3500);
    expect(projected.single.date, DateTime(2026, 10, 20));
  });
}
