import '../models/scheduled_action.dart';
import '../models/enums/scheduled_action_kind.dart';

class ScheduledActionExecutor {
  const ScheduledActionExecutor();

  Future<void> execute(ScheduledAction action) async {
    switch (action.kind) {
      case ScheduledActionKind.income:
        await _executeIncome(action);
        break;

      case ScheduledActionKind.expense:
        await _executeExpense(action);
        break;

      case ScheduledActionKind.transfer:
        await _executeTransfer(action);
        break;

      case ScheduledActionKind.liabilityPayment:
        await _executeLiabilityPayment(action);
        break;

      case ScheduledActionKind.goalContribution:
        await _executeGoalContribution(action);
        break;

      case ScheduledActionKind.budgetReset:
        await _executeBudgetReset(action);
        break;

      case ScheduledActionKind.investment:
        await _executeInvestment(action);
        break;
    }
  }

  // Future:
  // Execution Policy will determine
  // whether this action may execute automatically.

  Future<void> executeAll(List<ScheduledAction> actions) async {
    for (final action in actions) {
      await execute(action);
    }
  }

  Future<void> _executeIncome(ScheduledAction action) async {}

  Future<void> _executeExpense(ScheduledAction action) async {}

  Future<void> _executeTransfer(ScheduledAction action) async {}

  Future<void> _executeLiabilityPayment(ScheduledAction action) async {}

  Future<void> _executeGoalContribution(ScheduledAction action) async {}

  Future<void> _executeBudgetReset(ScheduledAction action) async {}

  Future<void> _executeInvestment(ScheduledAction action) async {}
}