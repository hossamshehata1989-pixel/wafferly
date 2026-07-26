import 'delete_transaction_command.dart';
import '../../operations/delete_operation.dart';

final class DeleteTransactionCommandMapper {
  const DeleteTransactionCommandMapper();

  DeleteOperation map(DeleteTransactionCommand command) {
    return DeleteOperation(
      intent: command.intent,
      metadata: command.metadata,
      context: command.context,
    );
  }
}
