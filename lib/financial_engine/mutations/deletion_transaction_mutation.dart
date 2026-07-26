import '../domain/financial_transaction_record.dart';
import '../planning/financial_mutation.dart';

final class DeleteTransactionMutation extends FinancialMutation {
  final FinancialTransactionRecord record;

  const DeleteTransactionMutation({required this.record});
}
