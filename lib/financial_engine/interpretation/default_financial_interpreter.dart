import '../operations/expense_operation.dart';
import '../operations/financial_operation.dart';
import '../operations/income_operation.dart';
import '../operations/transfer_operation.dart';
import 'financial_action_type.dart';
import 'financial_interpreter.dart';
import 'normalized_intent.dart';
import '../operations/goal_transfer_operation.dart';

final class DefaultFinancialInterpreter implements FinancialInterpreter {
  const DefaultFinancialInterpreter();

  @override
  NormalizedIntent interpret(FinancialOperation operation) {
    switch (operation) {
      case ExpenseOperation():
        return NormalizedIntent(
          action: FinancialActionType.expense,
          sourceAccountId: operation.sourceAccountId,
          amount: operation.amount,
          categoryId: operation.categoryId,
        );

      case IncomeOperation operation:
        return NormalizedIntent(
          action: FinancialActionType.income,
          sourceAccountId: operation.destinationAccountId,
          amount: operation.amount,
          categoryId: operation.categoryId,
        );

      case TransferOperation operation:
        return NormalizedIntent(
          action: FinancialActionType.transfer,
          sourceAccountId: operation.sourceAccountId,
          destinationAccountId: operation.destinationAccountId,
          amount: operation.amount,
        );

      case GoalTransferOperation operation:
        return NormalizedIntent(
          action: FinancialActionType.goalTransfer,
          sourceAccountId: operation.sourceAccountId,
          destinationAccountId: operation.savingsAccountId,
          amount: operation.amount,
        );

      default:
        throw UnimplementedError(
          'Interpreter not implemented for ${operation.runtimeType}',
        );
    }
  }
}
