import '../resolution/resolution.dart';
import 'financial_operation.dart';
import '../domain_guard/financial_constraint.dart';
import '../interpretation/normalized_intent.dart';
import '../planning/planning_context.dart';

final class GoalTransferOperation extends FinancialOperation {
  final String sourceAccountId;
  final String savingsAccountId;
  final String goalId;
  final double amount;
  final DateTime occurredAt;
  final String? note;

  const GoalTransferOperation({
    required this.sourceAccountId,
    required this.savingsAccountId,
    required this.goalId,
    required this.amount,
    required this.occurredAt,
    this.note,
    super.resolution,
  });

  @override
  GoalTransferOperation resolve(Resolution resolution) {
    return GoalTransferOperation(
      sourceAccountId: sourceAccountId,
      savingsAccountId: savingsAccountId,
      goalId: goalId,
      amount: amount,
      occurredAt: occurredAt,
      note: note,
      resolution: resolution,
    );
  }

  @override
  PlanningContext createPlanningContext({
    required NormalizedIntent intent,
    required List<FinancialConstraint> constraints,
  }) {
    throw UnimplementedError(
      'GoalTransferOperation has not been migrated to the Financial Command Model yet.',
    );
  }
}
