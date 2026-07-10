import '../shared/transaction_metadata.dart';
import '../../execution_context/execution_context.dart';
import 'expense_intent.dart';

/// Command entering the Financial Engine.
///
/// Groups together:
/// - Financial Intent
/// - Transaction Metadata
/// - Execution Context
///
/// ADR-0011.
final class ExpenseCommand {
  final ExpenseIntent intent;

  final TransactionMetadata metadata;

  final ExecutionContext context;

  const ExpenseCommand({
    required this.intent,
    required this.metadata,
    required this.context,
  });
}
