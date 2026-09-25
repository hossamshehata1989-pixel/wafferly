import '../../core/money/money.dart';

abstract interface class BalanceProvider {
  Future<Money> getBalance(String accountId);
}
