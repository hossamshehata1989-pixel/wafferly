import '../domain_guard/financial_constraint.dart';
import '../interpretation/normalized_intent.dart';
import '../resolution/resolution.dart';
import 'financial_policy.dart';
import 'policy_result.dart';

final class BalancePolicy implements FinancialPolicy {
  const BalancePolicy();

  @override
  Future<PolicyResult> evaluate(
    NormalizedIntent intent,
    List<FinancialConstraint> constraints,
  ) async {
    final constraint = constraints
        .whereType<InsufficientBalanceConstraint>()
        .firstOrNull;

    if (constraint == null) {
      return const PolicyPassed();
    }

    switch (intent.resolution) {
      case Resolution.execute:
        return const PolicyRequiresConfirmation(
          options: [
            Resolution.tempDebt,
            Resolution.addBalance,
            Resolution.cancel,
          ],
        );

      case Resolution.tempDebt:
        return const PolicyPassed();

      case Resolution.addBalance:
        return const PolicyRequiresConfirmation(
          options: [Resolution.addBalance, Resolution.cancel],
        );

      case Resolution.cancel:
        return const PolicyRejected(reason: 'Operation cancelled');
    }
  }
}
