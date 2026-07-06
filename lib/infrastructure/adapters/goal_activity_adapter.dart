import '../../financial_engine/planning/goal_activity_mutation.dart';
import '../../financial_engine/ports/goal_activity_port.dart';
import '../../models/goal_activity.dart';
import '../../services/goal_activity_service.dart';

final class GoalActivityAdapter implements GoalActivityPort {
  final GoalActivityService service;

  const GoalActivityAdapter({required this.service});

  @override
  Future<void> recordActivity(GoalActivityMutation mutation) {
    return service.addActivity(
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
