import '../operations/expense_operation.dart';
import '../operations/financial_operation.dart';
import '../operations/income_operation.dart';
import '../operations/transfer_operation.dart';
import '../operations/goal_transfer_operation.dart';

import 'financial_action_type.dart';
import 'financial_interpreter.dart';
import 'normalized_intent.dart';
import '../resolution/resolution.dart';
import '../operations/create_goal_allocation_operation.dart';

final class DefaultFinancialInterpreter implements FinancialInterpreter {
  const DefaultFinancialInterpreter();

  @override
  NormalizedIntent interpret(FinancialOperation operation) {
    switch (operation) {
      case ExpenseOperation():
        return NormalizedIntent(
          action: FinancialActionType.expense,
          sourceAccountId: operation.intent.sourceAccountId,
          amount: operation.intent.amount,
          categoryId: operation.intent.categoryId,

          actorMemberId: operation.intent.actorMemberId,
          isExceptional: operation.intent.isExceptional,

          resolution: operation.resolution ?? Resolution.execute,
        );

      case IncomeOperation():
        return NormalizedIntent(
          action: FinancialActionType.income,
          sourceAccountId: operation.intent.sourceAccountId,
          amount: operation.intent.amount,
          categoryId: operation.intent.categoryId,
          actorMemberId: operation.intent.actorMemberId,
          isExceptional: operation.intent.isExceptional,
          resolution: operation.resolution ?? Resolution.execute,
        );

      case TransferOperation operation:
        return NormalizedIntent(
          action: FinancialActionType.transfer,
          sourceAccountId: operation.intent.fromAccountId,
          destinationAccountId: operation.intent.toAccountId,
          amount: operation.intent.amount,
          resolution: operation.resolution ?? Resolution.execute,
        );

      case GoalTransferOperation operation:
        return NormalizedIntent(
          action: FinancialActionType.goalTransfer,
          sourceAccountId: operation.sourceAccountId,
          destinationAccountId: operation.savingsAccountId,
          goalId: operation.goalId,
          amount: operation.amount,
          resolution: operation.resolution ?? Resolution.execute,
        );

      case CreateGoalAllocationOperation():
        return NormalizedIntent(
          action: FinancialActionType.createGoalAllocation,
          amount: operation.amount,
          sourceAccountId: operation.accountId,
          goalId: operation.goalId,
          resolution: operation.resolution ?? Resolution.execute,
        );

      default:
        throw UnimplementedError(
          'Interpreter not implemented for ${operation.runtimeType}',
        );
    }
  }
}
