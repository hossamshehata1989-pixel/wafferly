import '../models/goal.dart';
import '../models/enums/goal_status.dart';
import 'goal_service.dart';

class GoalScheduleService {
  final GoalService _goalService = GoalService();

  List<Goal> getDueGoals() {
    final now = DateTime.now();

    return _goalService
        .getAll()
        .where(
          (goal) =>
              goal.status == GoalStatus.active &&
              goal.nextDueDate != null &&
              !goal.nextDueDate!.isAfter(now),
        )
        .toList();
  }
}
