import '../shared/transaction_metadata.dart';
import '../../execution_context/execution_context.dart';
import 'income_intent.dart';

/// Command entering the Financial Engine.
///
/// Groups together:
/// - Financial Intent
/// - Transaction Metadata
/// - Execution Context
///
/// ADR-0011.
final class IncomeCommand {
  final IncomeIntent intent;

  final TransactionMetadata metadata;

  final ExecutionContext context;

  const IncomeCommand({
    required this.intent,
    required this.metadata,
    required this.context,
  });
}
