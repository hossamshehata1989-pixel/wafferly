// lib/models/enums/goal_status.dart

import 'package:hive/hive.dart';

part 'goal_status.g.dart';

@HiveType(typeId: 61)
enum GoalStatus {
  @HiveField(0)
  active,

  @HiveField(1)
  completed,

  @HiveField(2)
  cancelled,
}
