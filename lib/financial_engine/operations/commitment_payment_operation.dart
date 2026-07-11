import '../resolution/resolution.dart';
import 'financial_operation.dart';
import '../domain_guard/financial_constraint.dart';
import '../interpretation/normalized_intent.dart';
import '../planning/planning_context.dart';

class CommitmentPaymentOperation extends FinancialOperation {
  final String sourceAccountId;

  final String commitmentId;

  final double amount;

  final DateTime occurredAt;

  const CommitmentPaymentOperation({
    required this.sourceAccountId,
    required this.commitmentId,
    required this.amount,
    required this.occurredAt,
    super.resolution,
  });

  @override
  CommitmentPaymentOperation resolve(Resolution resolution) {
    return CommitmentPaymentOperation(
      sourceAccountId: sourceAccountId,
      commitmentId: commitmentId,
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
      'CommitmentPaymentOperation has not been migrated to the Financial Command Model yet.',
    );
  }
}
