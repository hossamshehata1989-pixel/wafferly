import '../domain/financial_transaction_record.dart';
import '../planning/financial_mutation.dart';

final class UpdateTransactionMutation extends FinancialMutation {
  final FinancialTransactionRecord record;

  const UpdateTransactionMutation({required this.record});
}
