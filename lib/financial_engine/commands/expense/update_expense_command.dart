import '../../execution_context/execution_context.dart';
import '../shared/transaction_metadata.dart';
import 'expense_intent.dart';

/// Command representing an update to an existing expense.
///
/// Unlike ExpenseCommand, this command identifies the
/// existing Financial Transaction that should be replaced.
final class UpdateExpenseCommand {
  /// Existing transaction being updated.
  final String transactionId;

  /// New financial intent.
  final ExpenseIntent intent;

  /// New metadata.
  final TransactionMetadata metadata;

  /// Execution context.
  final ExecutionContext context;

  const UpdateExpenseCommand({
    required this.transactionId,
    required this.intent,
    required this.metadata,
    required this.context,
  });
}
