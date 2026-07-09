import '../../financial_engine/ports/balance_port.dart';
import '../../services/balance_service.dart';

final class HiveBalancePort implements BalancePort {
  final BalanceService _balanceService;

  const HiveBalancePort({required BalanceService balanceService})
    : _balanceService = balanceService;

  @override
  Future<double> availableBalance(String accountId) async {
    return _balanceService.getAvailableBalance(accountId);
  }
}
