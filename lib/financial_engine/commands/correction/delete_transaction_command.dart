import 'deletion_transaction_intent.dart';
import '../shared/transaction_metadata.dart';
import '../../execution_context/execution_context.dart';

final class DeleteTransactionCommand {
  final DeleteTransactionIntent intent;
  final TransactionMetadata metadata;
  final ExecutionContext context;

  const DeleteTransactionCommand({
    required this.intent,
    required this.metadata,
    required this.context,
  });
}
