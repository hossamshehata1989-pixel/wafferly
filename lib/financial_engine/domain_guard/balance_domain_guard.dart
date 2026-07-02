import '../interpretation/normalized_intent.dart';
import '../providers/balance_provider.dart';
import 'domain_guard.dart';
import 'domain_guard_result.dart';

final class BalanceDomainGuard implements DomainGuard {
  final BalanceProvider _balanceProvider;

  const BalanceDomainGuard({required BalanceProvider balanceProvider})
    : _balanceProvider = balanceProvider;

  @override
  Future<DomainGuardResult> validate(NormalizedIntent intent) async {
    final available = await _balanceProvider.getAvailableBalance(
      intent.sourceAccountId,
    );
    if (available < intent.amount) {
      return DomainViolation(reason: 'Insufficient balance');
    }

    return const DomainGuardPassed();
  }
}
