abstract interface class BalanceProvider {
  Future<double> getBalance(String accountId);
}
