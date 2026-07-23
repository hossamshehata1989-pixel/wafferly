import '../../operations/update_expense_operation.dart';
import 'update_expense_command.dart';

final class UpdateExpenseCommandMapper {
  const UpdateExpenseCommandMapper();

  UpdateExpenseOperation map(UpdateExpenseCommand command) {
    return UpdateExpenseOperation(
      transactionId: command.transactionId,
      intent: command.intent,
      metadata: command.metadata,
      context: command.context,
    );
  }
}
