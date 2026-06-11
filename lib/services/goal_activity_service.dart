import 'package:hive/hive.dart';

import '../models/goal_activity.dart';

class GoalActivityService {
  static const _boxName = 'goal_activities';

  Box<GoalActivity> get _box => Hive.box<GoalActivity>(_boxName);

  Future<void> addActivity(GoalActivity activity) async {
    print('ACTIVITY ADDED');
    print(activity.goalId);
    print(activity.type);
    print(activity.amount);

    await _box.put(activity.id, activity);
  }

  List<GoalActivity> getGoalActivities(String goalId) {
    final items = _box.values.where((e) => e.goalId == goalId).toList();

    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return items;
  }
}
