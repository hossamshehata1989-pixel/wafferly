import '../../core/money/money.dart';
import '../domain_guard/financial_constraint.dart';
import '../interpretation/normalized_intent.dart';
import '../planning/planning_context.dart';
import '../commands/shared/transaction_metadata.dart';
import '../execution_context/execution_context.dart';
import '../resolution/resolution.dart';
import 'financial_operation.dart';

/// Moves real money from a source account to a savings account for a Goal
/// when there is no existing Goal allocation that must be released.
///
/// Unlike GoalTransferOperation, this operation does not mutate planning
/// allocations. It records the financial transfer and the Goal activity.
final class GoalSavingTransferOperation extends FinancialOperation {
  final String sourceAccountId;
  final String savingsAccountId;
  final String goalId;
  final Money amount;
  final TransactionMetadata metadata;
  final ExecutionContext context;

  const GoalSavingTransferOperation({
    required this.sourceAccountId,
    required this.savingsAccountId,
    required this.goalId,
    required this.amount,
    required this.metadata,
    required this.context,
    super.resolution,
  });

  @override
  GoalSavingTransferOperation resolve(Resolution resolution) {
    return GoalSavingTransferOperation(
      sourceAccountId: sourceAccountId,
      savingsAccountId: savingsAccountId,
      goalId: goalId,
      amount: amount,
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
    );
  }
}
