import '../../financial_engine/ports/balance_port.dart';

final class MemoryBalancePort implements BalancePort {
  final Map<String, double> balances;

  const MemoryBalancePort({required this.balances});

  @override
  Future<double> availableBalance(String accountId) async {
    return balances[accountId] ?? 0;
  }
}
