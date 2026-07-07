abstract interface class BalancePort {
  Future<double> availableBalance(String accountId);
}
