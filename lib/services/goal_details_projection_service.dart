import '../models/goal.dart';
import '../models/goal_details_projection.dart';
import '../models/enums/goal_status.dart';

class GoalDetailsProjectionService {
  GoalDetailsProjection build({
    required Goal goal,
    required double progress,
    required bool hasFundingSources,
  }) {
    final isCompleted = goal.status == GoalStatus.completed;

    final isCancelled = goal.status == GoalStatus.cancelled;

    final isReserveGoal = goal.reserveMoney;
    final isSavingGoal = !goal.reserveMoney;

    return GoalDetailsProjection(
      showReserveActions:
          isReserveGoal && !isCompleted && !isCancelled && progress < 1.0,

      showSavingActions:
          isSavingGoal && !isCompleted && !isCancelled && progress < 1.0,

      showFundingSources: isReserveGoal && hasFundingSources,

      showCompleteGoalButton:
          isReserveGoal && !isCompleted && !isCancelled && progress >= 1.0,

      showArchiveButton:
          isSavingGoal && !isCompleted && !isCancelled && progress >= 1.0,
    );
  }
}
