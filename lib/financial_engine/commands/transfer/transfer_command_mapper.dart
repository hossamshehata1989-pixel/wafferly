import '../../operations/income_operation.dart';
import 'transfer_command.dart';

final class TransferCommandMapper {
  const TransferCommandMapper();

  IncomeOperation map(TransferCommand command) {
    return IncomeOperation(
      intent: command.intent,
      metadata: command.metadata,
      context: command.context,
    );
  }
}
