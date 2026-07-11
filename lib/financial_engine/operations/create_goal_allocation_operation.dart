import '../resolution/resolution.dart';
import 'financial_operation.dart';
import '../domain_guard/financial_constraint.dart';
import '../interpretation/normalized_intent.dart';
import '../planning/planning_context.dart';

final class CreateGoalAllocationOperation extends FinancialOperation {
  final String accountId;
  final String goalId;
  final double amount;
  final DateTime occurredAt;

  const CreateGoalAllocationOperation({
    required this.accountId,
    required this.goalId,
    required this.amount,
    required this.occurredAt,
    super.resolution,
  });

  @override
  CreateGoalAllocationOperation resolve(Resolution resolution) {
    return CreateGoalAllocationOperation(
      accountId: accountId,
      goalId: goalId,
      amount: amount,
      occurredAt: occurredAt,
      resolution: resolution,
    );
  }

  @override
  PlanningContext createPlanningContext({
    required NormalizedIntent intent,
    required List<FinancialConstraint> constraints,
  }) {
    throw UnimplementedError(
      'CreateGoalAllocationOperation has not been migrated to the Financial Command Model yet.',
    );
  }
}
