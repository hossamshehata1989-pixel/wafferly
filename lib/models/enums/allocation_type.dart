import 'package:hive/hive.dart';

part 'allocation_type.g.dart';

@HiveType(typeId: 81)
enum AllocationType {
  @HiveField(0)
  goal,

  @HiveField(1)
  saving,

  @HiveField(2)
  budgetSurplus,
}
