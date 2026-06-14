import 'package:hive/hive.dart';

part 'goal_frequency.g.dart';

@HiveType(typeId: 64)
enum GoalFrequency {
  @HiveField(0)
  weekly,

  @HiveField(1)
  monthly,
}
