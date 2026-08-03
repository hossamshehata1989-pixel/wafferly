import '../shared/transaction_metadata.dart';
import '../../execution_context/execution_context.dart';
import 'correction_intent.dart';

class CorrectionCommand {
  final CorrectionIntent intent;
  final TransactionMetadata metadata;
  final ExecutionContext context;

  const CorrectionCommand({
    required this.intent,
    required this.metadata,
    required this.context,
  });
}
