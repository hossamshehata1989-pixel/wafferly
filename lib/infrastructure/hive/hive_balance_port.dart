import '../../core/money/money.dart';
import '../../financial_engine/ports/balance_port.dart';
import '../../services/balance_service.dart';

final class HiveBalancePort implements BalancePort {
  final BalanceService _balanceService;

  const HiveBalancePort({required BalanceService balanceService})
    : _balanceService = balanceService;

  @override
  Future<Money> availableBalance(String accountId) async {
    final available =
        await _balanceService.getAvailableBalanceFromPlanning(accountId);
    return Money.fromDouble(available);
  }

  @override
  Future<Money> currentBalance(String accountId) async {
    return Money.fromDouble(_balanceService.getBalance(accountId));
  }
}
