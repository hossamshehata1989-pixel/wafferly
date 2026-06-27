import 'package:hive/hive.dart';
import 'enums/frequency.dart';

part 'schedule_rule.g.dart';

@HiveType(typeId: 95)
class ScheduleRule {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final Frequency frequency;

  @HiveField(2)
  final DateTime startDate;

  @HiveField(3)
  final DateTime nextDueDate;

  @HiveField(4)
  final DateTime? endDate;

  const ScheduleRule({
    required this.id,
    required this.frequency,
    required this.startDate,
    required this.nextDueDate,
    this.endDate,
  });

  ScheduleRule copyWith({
    Frequency? frequency,
    DateTime? startDate,
    DateTime? nextDueDate,
    DateTime? endDate,
  }) {
    return ScheduleRule(
      id: id,
      frequency: frequency ?? this.frequency,
      startDate: startDate ?? this.startDate,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      endDate: endDate ?? this.endDate,
    );
  }
}
