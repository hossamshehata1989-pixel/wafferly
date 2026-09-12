import 'package:hive/hive.dart';

part 'schedule_occurrence_status.g.dart';

@HiveType(typeId: 99)
enum ScheduleOccurrenceStatus {
  @HiveField(0)
  pending,

  @HiveField(1)
  skipped,

  @HiveField(2)
  completed,
}
