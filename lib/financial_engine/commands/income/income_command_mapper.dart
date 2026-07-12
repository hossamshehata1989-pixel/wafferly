import '../../operations/income_operation.dart';
import 'income_command.dart';

final class IncomeCommandMapper {
  const IncomeCommandMapper();

  IncomeOperation map(IncomeCommand command) {
    return IncomeOperation(
      intent: command.intent,
      metadata: command.metadata,
      context: command.context,
    );
  }
}
