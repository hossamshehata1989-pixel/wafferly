import '../commands/shared/transaction_metadata.dart';
import '../domain_guard/financial_constraint.dart';
import '../execution_context/execution_context.dart';
import '../interpretation/normalized_intent.dart';
import '../planning/planning_context.dart';
import '../resolution/resolution.dart';
import 'financial_operation.dart';

final class CreateGoalAllocationOperation extends FinancialOperation {
  final String accountId;
  final String goalId;
  final double amount;
  final DateTime occurredAt;

  final TransactionMetadata metadata;
  final ExecutionContext context;

  const CreateGoalAllocationOperation({
    required this.accountId,
    required this.goalId,
    required this.amount,
    required this.occurredAt,
    required this.metadata,
    required this.context,
    super.resolution,
  });

  @override
  CreateGoalAllocationOperation resolve(Resolution resolution) {
    return CreateGoalAllocationOperation(
      accountId: accountId,
      goalId: goalId,
      amount: amount,
      occurredAt: occurredAt,
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