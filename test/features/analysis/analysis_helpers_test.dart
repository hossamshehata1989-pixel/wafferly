import 'package:flutter_test/flutter_test.dart';
import 'package:wafferly/constants/transaction_constants.dart';
import 'package:wafferly/features/analysis/helpers/analysis_helpers.dart';
import 'package:wafferly/models/transaction.dart';

Transaction _tx({
  required String id,
  required double amount,
  required String type,
  String? categoryId = 'food',
  bool isExceptional = false,
  String currencyCode = 'EGP',
}) {
  return Transaction(
    id: id,
    amount: amount,
    type: type,
    date: DateTime(2026, 10, 1),
    categoryId: categoryId,
    isExceptional: isExceptional,
    currencyCode: currencyCode,
  );
}

void main() {
  group('purchase-based analysis helpers', () {
    test('includes cash expenses and credit-card charges, not payments', () {
      final rows = <Transaction>[
        _tx(id: 'cash', amount: 80, type: TransactionType.expense),
        _tx(id: 'card', amount: 120, type: TransactionType.creditCardCharge),
        _tx(id: 'transfer', amount: 120, type: TransactionType.transfer),
        _tx(id: 'income', amount: 200, type: TransactionType.income),
      ];

      expect(
        filterExpenses(rows).map((tx) => tx.id).toSet(),
        <String>{'cash', 'card'},
      );
      expect(sumAmounts(filterExpenses(rows)), closeTo(200, 1e-10));
    });

    test('accumulates fractional monetary amounts without double drift', () {
      final rows = <Transaction>[
        _tx(id: 'a', amount: 0.1, type: TransactionType.expense),
        _tx(id: 'b', amount: 0.2, type: TransactionType.creditCardCharge),
      ];

      expect(sumAmounts(rows), closeTo(0.3, 1e-12));
      expect(groupByMainCategory(rows)['food'], closeTo(0.3, 1e-12));
    });

    test('keeps exceptional card purchases in the exceptional tab', () {
      final rows = <Transaction>[
        _tx(
          id: 'exceptional-card',
          amount: 50,
          type: TransactionType.creditCardCharge,
          isExceptional: true,
        ),
        _tx(id: 'normal-cash', amount: 20, type: TransactionType.expense),
      ];

      expect(filterExceptionalExpenses(rows).map((tx) => tx.id),
          <String>['exceptional-card']);
      expect(filterRealExpenses(rows).map((tx) => tx.id), <String>['normal-cash']);
    });
  });
}
