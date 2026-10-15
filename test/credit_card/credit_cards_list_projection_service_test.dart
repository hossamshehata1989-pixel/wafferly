import 'package:flutter_test/flutter_test.dart';
import 'package:wafferly/application/credit_card/credit_cards_list_projection_service.dart';
import 'package:wafferly/core/money/money.dart';
import 'package:wafferly/models/financing/financing_contract.dart';
import 'package:wafferly/models/financing/financing_installment.dart';

void main() {
  group('CreditCardsListProjectionService installment currencies', () {
    final now = DateTime(2026, 10, 14);

    FinancingContract contract({
      required String id,
      required String accountId,
    }) => FinancingContract(
          contractId: id,
          liabilityAccountId: accountId,
          originReference: 'charge-$id',
          principalValue: '1000',
          installmentCount: 2,
          paymentFrequency: 'monthly',
          firstDueDate: DateTime(2026, 10, 20),
          lifecycleState: 'active',
          effectiveDate: DateTime(2026, 9, 1),
          createdAt: DateTime(2026, 9, 1),
        );

    FinancingInstallment installment({
      required String id,
      required String contractId,
      required String amount,
    }) => FinancingInstallment(
          installmentId: id,
          contractId: contractId,
          scheduleId: 'schedule-$contractId',
          sequence: 1,
          dueDate: DateTime(2026, 10, 20),
          openingPrincipalValue: amount,
          principalComponentValue: amount,
          interestComponentValue: '0',
          feesValue: '0',
          amountValue: amount,
          status: 'due',
        );

    test('keeps exact totals when all installments have one currency', () {
      final projection =
          CreditCardsListProjectionService.projectInstallmentOverviewFromData(
        accountIds: const {'card-egp'},
        currencyByAccountId: const {'card-egp': 'EGP'},
        installments: [
          installment(
            id: 'inst-1', contractId: 'contract-egp', amount: '125.50',
          ),
          installment(
            id: 'inst-2', contractId: 'contract-egp', amount: '75.25',
          ),
        ],
        contracts: [contract(id: 'contract-egp', accountId: 'card-egp')],
        now: now,
      );

      expect(projection.hasMixedCurrencies, isFalse);
      expect(projection.currencyLabel, equals('EGP'));
      expect(projection.currentTotal, Money.parse('200.75'));
      expect(projection.remainingTotal, Money.parse('200.75'));
    });

    test('does not aggregate amounts across different currencies', () {
      final projection =
          CreditCardsListProjectionService.projectInstallmentOverviewFromData(
        accountIds: const {'card-egp', 'card-usd'},
        currencyByAccountId: const {
          'card-egp': 'EGP',
          'card-usd': 'USD',
        },
        installments: [
          installment(
            id: 'inst-egp', contractId: 'contract-egp', amount: '200',
          ),
          installment(
            id: 'inst-usd', contractId: 'contract-usd', amount: '100',
          ),
        ],
        contracts: [
          contract(id: 'contract-egp', accountId: 'card-egp'),
          contract(id: 'contract-usd', accountId: 'card-usd'),
        ],
        now: now,
      );

      expect(projection.hasMixedCurrencies, isTrue);
      expect(projection.currencyLabel, isNull);
      expect(projection.currentTotal, Money.zero);
      expect(projection.remainingTotal, Money.zero);
      expect(
        projection.periods.every((period) => period.amount == Money.zero),
        isTrue,
      );
    });
  });
}
