import '../resolution/resolution.dart';
import 'financial_operation.dart';

class GoalTransferOperation extends FinancialOperation {
  final String sourceAccountId;

  final String goalId;

  final double amount;

  final DateTime occurredAt;

  const GoalTransferOperation({
    required this.sourceAccountId,
    required this.goalId,
    required this.amount,
    required this.occurredAt,
    super.resolution,
  });

  @override
  GoalTransferOperation resolve(Resolution resolution) {
    return GoalTransferOperation(
      sourceAccountId: sourceAccountId,
      goalId: goalId,
      amount: amount,
      occurredAt: occurredAt,
      resolution: resolution,
    );
  }
}
