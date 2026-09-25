import '../../core/money/money.dart';
import '../../financial_engine/ports/balance_port.dart';

final class MemoryBalancePort implements BalancePort {
  final Map<String, Money> balances;

  const MemoryBalancePort({required this.balances});

  @override
  Future<Money> availableBalance(String accountId) async {
    return balances[accountId] ?? Money.zero;
  }

  @override
  Future<Money> currentBalance(String accountId) async {
    return balances[accountId] ?? Money.zero;
  }
}
