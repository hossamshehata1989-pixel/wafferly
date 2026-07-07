import '../interpretation/normalized_intent.dart';
import '../ports/balance_port.dart';
import 'domain_guard.dart';
import 'domain_guard_result.dart';
import 'financial_constraint.dart';

final class BalanceDomainGuard implements DomainGuard {
  final BalancePort _balancePort;

  const BalanceDomainGuard({required BalancePort balancePort})
    : _balancePort = balancePort;

  @override
  Future<DomainGuardResult> validate(NormalizedIntent intent) async {
    final available = await _balancePort.availableBalance(
      intent.sourceAccountId,
    );

    if (available < intent.amount) {
      return DomainConstraint(
        constraint: InsufficientBalanceConstraint(
          available: available,
          required: intent.amount,
        ),
      );
    }

    return const DomainGuardPassed();
  }
}
