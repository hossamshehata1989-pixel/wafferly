import '../planning/goal_activity_mutation.dart';

abstract interface class GoalActivityPort {
  Future<void> recordActivity(
    GoalActivityMutation mutation,
  );
}