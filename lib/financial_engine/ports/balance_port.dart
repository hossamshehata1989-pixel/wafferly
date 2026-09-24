abstract interface class BalancePort {
  /// Available balance used by spendability guards.
  Future<double> availableBalance(String accountId);

  /// Derived financial balance before planning reservations.
  Future<double> currentBalance(String accountId);
}
