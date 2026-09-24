import '../domain/financial_transaction_record.dart';

final class CorrectionContext {
  final String transactionId;
  final FinancialTransactionRecord before;
  final FinancialTransactionRecord after;

  const CorrectionContext({
    required this.transactionId,
    required this.before,
    required this.after,
  });
}
