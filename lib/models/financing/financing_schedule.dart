import 'package:hive/hive.dart';

part 'financing_schedule.g.dart';

/// Persisted identity/configuration for one financing schedule.
///
/// Timing remains delegated to the existing ScheduleRule/ScheduleOccurrence
/// architecture. This object links that schedule to one financing contract.
@HiveType(typeId: 111)
class FinancingSchedule {
  @HiveField(0)
  final String scheduleId;

  @HiveField(1)
  final String contractId;

  @HiveField(2)
  final String scheduleRuleId;

  @HiveField(3)
  final int installmentCount;

  @HiveField(4)
  final String status;

  @HiveField(5)
  final DateTime createdAt;

  const FinancingSchedule({
    required this.scheduleId,
    required this.contractId,
    required this.scheduleRuleId,
    required this.installmentCount,
    required this.status,
    required this.createdAt,
  });
}
