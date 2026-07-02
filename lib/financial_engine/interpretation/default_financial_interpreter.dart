import '../operations/expense_operation.dart';
import '../operations/financial_operation.dart';
import 'financial_action_type.dart';
import 'financial_interpreter.dart';
import 'normalized_intent.dart';

final class DefaultFinancialInterpreter implements FinancialInterpreter {
  const DefaultFinancialInterpreter();

  @override
  NormalizedIntent interpret(FinancialOperation operation) {
    switch (operation) {
      case ExpenseOperation():
        return NormalizedIntent(
          action: FinancialActionType.expense,
          amount: operation.amount,
          sourceAccountId: operation.sourceAccountId,
        );

      default:
        throw UnimplementedError(
          'Interpreter not implemented for ${operation.runtimeType}',
        );
    }
  }
}
