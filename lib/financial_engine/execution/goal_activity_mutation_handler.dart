import '../../models/goal_activity.dart';
import '../../services/goal_activity_service.dart';
import '../planning/goal_activity_mutation.dart';
import 'financial_mutation_handler.dart';

final class GoalActivityMutationHandler
    implements FinancialMutationHandler<GoalActivityMutation> {
  final GoalActivityService _service;

  const GoalActivityMutationHandler({required GoalActivityService service})
    : _service = service;

  @override
  Future<void> execute(GoalActivityMutation mutation) async {
    await _service.addActivity(
      GoalActivity.create(
        goalId: mutation.goalId,
        type: mutation.activityType,
        amount: mutation.amount,
        sourceAccountId: mutation.sourceAccountId,
        destinationAccountId: mutation.destinationAccountId,
      ),
    );
  }
}
