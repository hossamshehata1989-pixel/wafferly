import 'package:flutter_test/flutter_test.dart';
import 'package:wafferly/application/credit_card/credit_card_transaction_timing_policy.dart';
import 'package:wafferly/models/financing/financing_contract.dart';
import 'package:wafferly/models/financing/financing_installment.dart';

void main() {
  group('CreditCardTransactionTimingPolicy', () {
    test('ordinary purchase uses the actual statement close cycle', () {
      final beforeClose =
          CreditCardTransactionTimingPolicy.statementDateForPurchase(
        purchaseDate: DateTime(2026, 10, 10),
        statementDay: 15,
      );
      final afterClose =
          CreditCardTransactionTimingPolicy.statementDateForPurchase(
        purchaseDate: DateTime(2026, 10, 16),
        statementDay: 15,
      );

      expect(beforeClose, DateTime(2026, 10, 15));
      expect(afterClose, DateTime(2026, 11, 15));
    });

    test('missing statement day uses the explicit fallback policy', () {
      final result =
          CreditCardTransactionTimingPolicy.statementDateForPurchase(
        purchaseDate: DateTime(2026, 12, 31),
        statementDay: null,
      );

      expect(result, DateTime(2027, 1, 31));
    });

    test('installment row uses first unsettled due date, not purchase date', () {
      final contract = _contract(
        id: 'contract-a',
        origin: 'charge-a',
        firstDueDate: DateTime(2026, 9, 15),
      );
      final installments = <FinancingInstallment>[
        _installment(
          id: 'one',
          contractId: 'contract-a',
          sequence: 1,
          dueDate: DateTime(2026, 9, 15),
          status: 'settled',
        ),
        _installment(
          id: 'two',
          contractId: 'contract-a',
          sequence: 2,
          dueDate: DateTime(2026, 10, 15),
          status: 'scheduled',
        ),
        _installment(
          id: 'three',
          contractId: 'contract-a',
          sequence: 3,
          dueDate: DateTime(2026, 11, 15),
          status: 'scheduled',
        ),
      ];

      final result =
          CreditCardTransactionTimingPolicy.firstOutstandingInstallmentDueDateForCharge(
        chargeId: 'charge-a',
        contracts: [contract],
        installments: installments,
      );

      expect(result, DateTime(2026, 10, 15));
    });

    test('never picks an installment from another charge or settled rows', () {
      final contract = _contract(
        id: 'contract-b',
        origin: 'charge-b',
        firstDueDate: DateTime(2026, 10, 15),
      );
      final result =
          CreditCardTransactionTimingPolicy.firstOutstandingInstallmentDueDateForCharge(
        chargeId: 'charge-a',
        contracts: [contract],
        installments: [
          _installment(
            id: 'row',
            contractId: 'contract-b',
            sequence: 1,
            dueDate: DateTime(2026, 10, 15),
            status: 'scheduled',
          ),
        ],
      );

      expect(result, isNull);
    });
  });
}

FinancingContract _contract({
  required String id,
  required String origin,
  required DateTime firstDueDate,
}) => FinancingContract(
      contractId: id,
      liabilityAccountId: 'card-1',
      originReference: origin,
      principalValue: '300.00',
      installmentCount: 3,
      paymentFrequency: 'monthly',
      firstDueDate: firstDueDate,
      lifecycleState: 'active',
      effectiveDate: DateTime(2026, 9, 1),
      createdAt: DateTime(2026, 9, 1),
    );

FinancingInstallment _installment({
  required String id,
  required String contractId,
  required int sequence,
  required DateTime dueDate,
  required String status,
}) => FinancingInstallment(
      installmentId: id,
      contractId: contractId,
      scheduleId: 'schedule-$contractId',
      sequence: sequence,
      dueDate: dueDate,
      openingPrincipalValue: '300.00',
      principalComponentValue: '100.00',
      interestComponentValue: '0.00',
      feesValue: '0.00',
      amountValue: '100.00',
      status: status,
    );
