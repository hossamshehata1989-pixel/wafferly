abstract interface class BalanceProvider {
  const BalanceProvider();

  Future<double> getAvailableBalance(String accountId);
}
