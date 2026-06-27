import 'package:hive/hive.dart';
part 'commitment_status.g.dart';

@HiveType(typeId: 92)
enum CommitmentStatus {
  @HiveField(0)
  active,

  @HiveField(1)
  paused,

  @HiveField(2)
  completed,

  @HiveField(3)
  cancelled,
}
