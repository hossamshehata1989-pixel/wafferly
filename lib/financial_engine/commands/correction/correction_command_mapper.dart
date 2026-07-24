import '../../operations/correction_financial_operation.dart';
import 'correction_command.dart';

class CorrectionCommandMapper {
  const CorrectionCommandMapper();

  CorrectionOperation map(CorrectionCommand command) {
    return CorrectionOperation(
      intent: command.intent,
      metadata: command.metadata,
      context: command.context,
    );
  }
}
