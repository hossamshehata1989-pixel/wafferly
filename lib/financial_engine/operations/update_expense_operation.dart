import '../commands/expense/expense_intent.dart';
import '../commands/shared/transaction_metadata.dart';
import '../execution_context/execution_context.dart';

/// Represents replacing an existing expense with a new financial truth.
final class UpdateExpenseOperation {
  /// Existing transaction to replace.
  final String transactionId;

  /// New financial intent.
  final ExpenseIntent intent;

  /// New metadata.
  final TransactionMetadata metadata;

  /// Execution context.
  final ExecutionContext context;

  const UpdateExpenseOperation({
    required this.transactionId,
    required this.intent,
    required this.metadata,
    required this.context,
  });
}
