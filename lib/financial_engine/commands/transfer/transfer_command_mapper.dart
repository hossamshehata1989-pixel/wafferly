import '../../operations/transfer_operation.dart';
import 'transfer_command.dart';

final class TransferCommandMapper {
  const TransferCommandMapper();

  TransferOperation map(TransferCommand command) {
    return TransferOperation(
      intent: command.intent,
      metadata: command.metadata,
      context: command.context,
    );
  }
}
