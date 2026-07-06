import '../resolution/resolution.dart';
import 'financial_operation.dart';

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
}
