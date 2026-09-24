import '../commands/balance_reconciliation/balance_reconciliation_intent.dart';
import '../commands/shared/transaction_metadata.dart';
import '../domain_guard/financial_constraint.dart';
import '../execution_context/execution_context.dart';
import '../interpretation/normalized_intent.dart';
import '../planning/balance_reconciliation_context.dart';
import '../planning/planning_context.dart';
import '../resolution/resolution.dart';
import 'financial_operation.dart';

final class BalanceReconciliationOperation extends FinancialOperation {
  final BalanceReconciliationIntent intent;
  final TransactionMetadata metadata;
  final ExecutionContext context;

  const BalanceReconciliationOperation({
    required this.intent,
    required this.metadata,
    required this.context,
    super.resolution,
  });

  @override
  BalanceReconciliationOperation resolve(Resolution resolution) {
    return BalanceReconciliationOperation(
      intent: intent,
      metadata: metadata,
      context: context,
      resolution: resolution,
    );
  }

  @override
  PlanningContext createPlanningContext({
    required NormalizedIntent intent,
    required List<FinancialConstraint> constraints,
  }) {
    return PlanningContext(
      intent: intent,
      metadata: metadata,
      executionContext: context,
      constraints: constraints,
      balanceReconciliation: BalanceReconciliationContext(
        accountId: this.intent.accountId,
        systemBalance: this.intent.systemBalance,
        observedBalance: this.intent.observedBalance,
        isLiability: this.intent.isLiability,
        reason: this.intent.reason,
      ),
    );
  }
}
