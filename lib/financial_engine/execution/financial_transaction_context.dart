abstract interface class FinancialTransactionContext {
  void registerRollback(
    Future<void> Function() rollback,
  );
}