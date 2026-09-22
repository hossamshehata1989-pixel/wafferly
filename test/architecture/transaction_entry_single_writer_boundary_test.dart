import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'transaction entry save flow does not fall back to the generic transaction writer',
    () {
      final source = File(
        'lib/controllers/transaction_entry_controller.dart',
      ).readAsStringSync();

      final saveStart = source.indexOf('Future<SaveResult> validateAndSave');
      final categoryHelpers = source.indexOf('String _getMainCategoryId');
      expect(saveStart, greaterThanOrEqualTo(0));
      expect(categoryHelpers, greaterThan(saveStart));

      final saveFlow = source.substring(saveStart, categoryHelpers);

      expect(saveFlow, isNot(contains('_saveTransactionLegacy')));
      expect(saveFlow, isNot(contains('addTransaction(')));
      expect(saveFlow, contains('addExpense('));
      expect(saveFlow, contains('addIncome('));
      expect(saveFlow, contains('SaveResult('));
      expect(saveFlow, contains('Unsupported transaction type'));
    },
  );
}
