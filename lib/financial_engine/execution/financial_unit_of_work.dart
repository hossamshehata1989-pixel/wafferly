import 'financial_transaction_context.dart';

abstract interface class FinancialUnitOfWork {
  Future<void> execute(
    Future<void> Function(
      FinancialTransactionContext context,
    ) action,
  );
}