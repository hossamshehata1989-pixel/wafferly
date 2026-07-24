import '../domain/financial_transaction_record.dart';

abstract interface class TransactionLookupPort {
  Future<FinancialTransactionRecord?> findById(String transactionId);
}
