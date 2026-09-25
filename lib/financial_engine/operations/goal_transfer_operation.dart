import '../../core/money/money.dart';
import '../domain_guard/financial_constraint.dart';
import '../interpretation/normalized_intent.dart';
import '../planning/planning_context.dart';
import '../commands/shared/transaction_metadata.dart';
import '../execution_context/execution_context.dart';
import '../resolution/resolution.dart';
import 'financial_operation.dart';

/// Financial operation for moving real money from an account into
/// a savings account in the context of a Goal.
///
/// The operation itself carries the command metadata/context needed by the
/// Financial Command Model. Planning and execution decisions remain outside
/// this value object.
final class GoalTransferOperation extends FinancialOperation {
  final String sourceAccountId;
  final String savingsAccountId;
  final String goalId;
  final Money amount;
  final TransactionMetadata metadata;
  final ExecutionContext context;

  const GoalTransferOperation({
    required this.sourceAccountId,
    required this.savingsAccountId,
    required this.goalId,
    required this.amount,
    required this.metadata,
    required this.context,
    super.resolution,
  });

  @override
  GoalTransferOperation resolve(Resolution resolution) {
    return GoalTransferOperation(
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
