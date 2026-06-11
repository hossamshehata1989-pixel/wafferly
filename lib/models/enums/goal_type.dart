import 'package:hive/hive.dart';

part 'goal_type.g.dart';

@HiveType(typeId: 62)
enum GoalType {
  @HiveField(0)
  manual,

  @HiveField(1)
  recurring,
}
