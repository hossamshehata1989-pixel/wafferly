import 'package:hive/hive.dart';

import 'enums/schedule_occurrence_status.dart';

part 'schedule_occurrence.g.dart';

/// One concrete due instance produced from a ScheduleRule.
///
/// Financial meaning remains on Commitment; temporal state (upcoming/due/
/// overdue) remains derived by ScheduleEvaluator.
@HiveType(typeId: 98)
class ScheduleOccurrence {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String scheduleRuleId;

  @HiveField(2)
  final DateTime dueDate;

  @HiveField(3)
  final ScheduleOccurrenceStatus status;

  const ScheduleOccurrence({
    required this.id,
    required this.scheduleRuleId,
    required this.dueDate,
    this.status = ScheduleOccurrenceStatus.pending,
  });

  /// Stable identity for one recurrence slot.
  ///
  /// The slot currently uses the rule's concrete dueDate. Keeping the
  /// identity rule+slot based prevents repeated generation from creating a
  /// second occurrence for the same scheduled instance.
  static String idFor({
    required String scheduleRuleId,
    required DateTime dueDate,
  }) {
    return '$scheduleRuleId|${dueDate.toIso8601String()}';
  }

  ScheduleOccurrence copyWith({
    DateTime? dueDate,
    ScheduleOccurrenceStatus? status,
  }) {
    return ScheduleOccurrence(
      id: id,
      scheduleRuleId: scheduleRuleId,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
    );
  }
}
