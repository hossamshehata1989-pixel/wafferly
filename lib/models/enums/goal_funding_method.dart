import 'package:hive/hive.dart';

part 'goal_funding_method.g.dart';

@HiveType(typeId: 63)
enum GoalFundingMethod {
  @HiveField(0)
  saving,

  @HiveField(1)
  reserve,
}
