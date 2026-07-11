import '../domain/financial_transaction_record.dart';
import '../planning/financial_mutation.dart';

/// Mutation responsible for creating a persisted financial transaction.
///
/// This mutation is produced by the Financial Planner and executed
/// by the Executor through a TransactionPort.
///
/// ADR-0012:
/// Every observable financial write must be represented as a Mutation.
///
/// ADR-0013:
/// This mutation carries a Domain Value Object
/// (FinancialTransactionRecord), not a persistence entity.
final class CreateTransactionMutation extends FinancialMutation {
  final FinancialTransactionRecord record;

  const CreateTransactionMutation({required this.record});
}
