import '../domain/financial_transaction_record.dart';

abstract interface class TransactionUpdatePort {
  Future<void> update(
    FinancialTransactionRecord before,
    FinancialTransactionRecord after,
  );
}
