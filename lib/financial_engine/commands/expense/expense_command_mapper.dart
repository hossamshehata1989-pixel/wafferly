import '../../operations/expense_operation.dart';
import 'expense_command.dart';

final class ExpenseCommandMapper {
  const ExpenseCommandMapper();

  ExpenseOperation map(ExpenseCommand command) {
    return ExpenseOperation(
      sourceAccountId: command.intent.sourceAccountId,
      amount: command.intent.amount,
      categoryId: command.intent.categoryId,
      occurredAt: command.metadata.occurredAt,
      note: command.metadata.note,
    );
  }
}
