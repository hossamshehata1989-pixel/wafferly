// lib/services/goal_activity_service.dart

import 'package:hive/hive.dart';
import '../models/goal_activity.dart';

class GoalActivityService {
  static const _boxName = 'goal_activities';

  Box<GoalActivity> get _box => Hive.box<GoalActivity>(_boxName);

  Future<void> addActivity(GoalActivity activity) async {
    await _box.put(activity.id, activity);
  }

  /// Delete an activity by ID (used for rollback)
  Future<void> deleteActivity(String id) async {
    await _box.delete(id);
  }

  List<GoalActivity> getGoalActivities(String goalId) {
    final items = _box.values.where((e) => e.goalId == goalId).toList();

    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return items;
  }

  /// Returns true if the goal has ever been involved
  /// in any financial operation.
  ///
  /// Important:
  /// Once financial history exists, the goal can no longer
  /// be cancelled, even if its current reserved amount is zero.
  bool hasFinancialHistory(String goalId) {
    final activities = getGoalActivities(goalId);

    return activities.any(
      (activity) =>
          activity.type == GoalActivityType.reserve ||
          activity.type == GoalActivityType.release ||
          activity.type == GoalActivityType.transferToSaving ||
          activity.type == GoalActivityType.completedReserved ||
          activity.type == GoalActivityType.completedRelease,
    );
  }
}