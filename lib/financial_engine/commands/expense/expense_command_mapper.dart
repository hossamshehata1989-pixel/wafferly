import '../../operations/expense_operation.dart';
import 'expense_command.dart';

final class ExpenseCommandMapper {
  const ExpenseCommandMapper();

  ExpenseOperation map(ExpenseCommand command) {
    return ExpenseOperation(
      intent: command.intent,
      metadata: command.metadata,
      context: command.context,
    );
  }
}
