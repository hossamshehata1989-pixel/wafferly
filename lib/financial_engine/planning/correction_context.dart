import '../domain/financial_transaction_record.dart';

final class CorrectionContext {
  final String transactionId;
  final FinancialTransactionRecord after;

  const CorrectionContext({required this.transactionId, required this.after});
}
