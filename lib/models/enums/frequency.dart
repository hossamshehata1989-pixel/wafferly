import 'package:hive/hive.dart';

part 'frequency.g.dart';

@HiveType(typeId: 94)
enum Frequency {
  @HiveField(0)
  oneTime,

  @HiveField(1)
  daily,

  @HiveField(2)
  weekly,

  @HiveField(3)
  monthly,

  @HiveField(4)
  yearly,
}
