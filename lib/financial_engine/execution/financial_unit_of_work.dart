abstract interface class FinancialUnitOfWork {
  Future<void> execute(Future<void> Function() action);
}
