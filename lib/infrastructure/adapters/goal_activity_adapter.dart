import '../../financial_engine/execution/financial_transaction_context.dart';
import '../../financial_engine/mutations/goal_activity_mutation.dart';
import '../../financial_engine/ports/goal_activity_port.dart';
import '../../models/goal_activity.dart';
import '../../services/goal_activity_service.dart';

final class GoalActivityAdapter implements GoalActivityPort {
  final GoalActivityService service;

  const GoalActivityAdapter({
    required this.service,
  });

  @override
  Future<void> recordActivity(
    GoalActivityMutation mutation,
    FinancialTransactionContext context,
  ) async {
    final activity = GoalActivity.create(
      goalId: mutation.goalId,
      type: mutation.activityType,
      amount: mutation.amount,
      sourceAccountId: mutation.sourceAccountId,
      destinationAccountId: mutation.destinationAccountId,
    );

    await service.addActivity(activity);

    context.registerRollback(() {
      return service.deleteActivity(activity.id);
    });
  }
}