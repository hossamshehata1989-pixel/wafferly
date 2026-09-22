import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'goal transfer flows do not write financial reality directly from the UI',
    () {
      final source = File(
        'lib/screens/planning/goal_details_screen.dart',
      ).readAsStringSync();
      final reservedGoalTransferFlow = source.substring(
        source.indexOf('Future<void> _executeTransfer'),
        source.indexOf('Future<bool> _transferAllToSaving'),
      );
      final nonReservedGoalSavingFlow = source.substring(
        source.indexOf('Future<void> _transferSavingGoalFunding'),
        source.indexOf('Future<void> _transferFundingSource'),
      );

      expect(
        reservedGoalTransferFlow,
        isNot(contains('TransactionService.instance.addTransaction')),
      );
      expect(reservedGoalTransferFlow, contains('GoalTransferOperation('));
      expect(reservedGoalTransferFlow, contains('FinancialOperationEngine'));

      expect(
        nonReservedGoalSavingFlow,
        isNot(contains('TransactionService.instance.addTransaction')),
      );
      expect(nonReservedGoalSavingFlow, isNot(contains('GoalActivityService')));
      expect(
        nonReservedGoalSavingFlow,
        contains('GoalSavingTransferOperation('),
      );
      expect(nonReservedGoalSavingFlow, contains('FinancialOperationEngine'));
    },
  );
}
