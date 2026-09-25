import '../../core/money/money.dart';

abstract interface class BalancePort {
  /// Available balance used by spendability guards.
  Future<Money> availableBalance(String accountId);

  /// Derived financial balance before planning reservations.
  Future<Money> currentBalance(String accountId);
}
