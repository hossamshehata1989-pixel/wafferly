import '../domain/financial_transaction_record.dart';

final class DeletionContext {
  final String transactionId;
  final FinancialTransactionRecord before;

  const DeletionContext({
    required this.transactionId,
    required this.before,
  });
}
