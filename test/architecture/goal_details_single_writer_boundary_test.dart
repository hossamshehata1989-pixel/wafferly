import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'reserved goal transfers do not write transactions directly from the UI',
    () {
      final source = File(
        'lib/screens/planning/goal_details_screen.dart',
      ).readAsStringSync();
      final reservedGoalTransferFlow = source.substring(
        source.indexOf('Future<void> _executeTransfer'),
        source.indexOf('Future<bool> _transferAllToSaving'),
      );

      expect(
        reservedGoalTransferFlow,
        isNot(contains('TransactionService.instance.addTransaction')),
      );
      expect(reservedGoalTransferFlow, contains('GoalTransferOperation('));
      expect(reservedGoalTransferFlow, contains('FinancialOperationEngine'));
    },
  );
}
