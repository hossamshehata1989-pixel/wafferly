import '../interpretation/normalized_intent.dart';
import '../ports/balance_port.dart';
import 'domain_guard.dart';
import 'domain_guard_result.dart';
import 'financial_constraint.dart';
import 'package:flutter/foundation.dart';
import '../interpretation/financial_action_type.dart';

final class BalanceDomainGuard implements DomainGuard {
  final BalancePort _balancePort;

  const BalanceDomainGuard({required BalancePort balancePort})
    : _balancePort = balancePort;

  @override
  Future<DomainGuardResult> validate(NormalizedIntent intent) async {
    if (intent.action == FinancialActionType.openingBalance) {
      if (intent.amount < 0) {
        return const DomainViolation(
          reason: 'Opening balance amount must not be negative.',
        );
      }

      return const DomainGuardPassed();
    }

    if (intent.action == FinancialActionType.income) {
      return const DomainGuardPassed();
    }

    final available = await _balancePort.availableBalance(
      intent.sourceAccountId,
    );

    debugPrint("========== BALANCE ==========");
    debugPrint("Account   = ${intent.sourceAccountId}");
    debugPrint("Available = $available");
    debugPrint("Requested = ${intent.amount}");
    debugPrint("============================");

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
