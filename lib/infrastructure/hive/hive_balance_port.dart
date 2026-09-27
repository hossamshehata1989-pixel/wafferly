import '../../core/money/money.dart';
import '../../financial_engine/ports/balance_port.dart';
import '../../services/balance_service.dart';
import '../../financial_engine/ports/credit_card_balance_reader.dart';

final class HiveBalancePort implements BalancePort, CreditCardBalanceReader {
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
