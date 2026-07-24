import '../../domain/financial_transaction_record.dart';

class CorrectionIntent {
  final String transactionId;
  final FinancialTransactionRecord after;

  const CorrectionIntent({required this.transactionId, required this.after});
}
