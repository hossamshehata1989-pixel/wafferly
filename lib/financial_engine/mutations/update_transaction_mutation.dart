import '../domain/financial_transaction_record.dart';
import '../planning/financial_mutation.dart';

final class UpdateTransactionMutation extends AccountingMutation {
  const UpdateTransactionMutation({required this.before, required this.after});

  final FinancialTransactionRecord before;
  final FinancialTransactionRecord after;
}
