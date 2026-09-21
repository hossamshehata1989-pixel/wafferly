import 'financial_transaction_context.dart';

abstract interface class FinancialMutationHandler<T> {
  Future<void> execute(
    T mutation,
    FinancialTransactionContext context,
  );
}