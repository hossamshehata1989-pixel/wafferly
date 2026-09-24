import '../../domain/financial_transaction_record.dart';

final class CorrectionIntent {
  final String transactionId;
  final FinancialTransactionRecord before;
  final FinancialTransactionRecord after;

  const CorrectionIntent({
    required this.transactionId,
    required this.before,
    required this.after,
  });
}
