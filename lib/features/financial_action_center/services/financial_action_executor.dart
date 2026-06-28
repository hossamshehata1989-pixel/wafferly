import '../../../models/scheduled_action_execution_context.dart';
import '../../../models/enums/scheduled_action_kind.dart';
import 'package:flutter/material.dart';

class FinancialActionExecutor {
  const FinancialActionExecutor();

  Future<bool> execute(
    BuildContext context,
    ScheduledActionExecutionContext action,
  ) async {
    switch (action.action.kind) {
      case ScheduledActionKind.expense:
        debugPrint('Execute Expense');
        return true;

      case ScheduledActionKind.income:
        debugPrint('Execute Income');
        return true;

      case ScheduledActionKind.transfer:
        debugPrint('Execute Transfer');
        return true;

      case ScheduledActionKind.goalContribution:
        debugPrint('Execute Goal Contribution');
        return true;

      case ScheduledActionKind.liabilityPayment:
        debugPrint('Execute Liability Payment');
        return true;

      case ScheduledActionKind.budgetReset:
        debugPrint('Execute Budget Reset');
        return true;

      case ScheduledActionKind.investment:
        debugPrint('Execute Investment');
        return true;
    }
  }
}
