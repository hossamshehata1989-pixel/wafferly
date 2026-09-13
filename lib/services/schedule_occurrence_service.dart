import 'package:hive/hive.dart';

import '../models/enums/frequency.dart';
import '../models/enums/schedule_occurrence_status.dart';
import '../models/schedule_occurrence.dart';
import '../models/schedule_rule.dart';
import 'schedule_rule_service.dart';

class ScheduleOccurrenceService {
  static const String _boxName = 'schedule_occurrences';

  final ScheduleRuleService ruleService;

  const ScheduleOccurrenceService({required this.ruleService});

  Box<ScheduleOccurrence> get _box =>
      Hive.box<ScheduleOccurrence>(_boxName);

  ScheduleOccurrence? getOccurrence(String id) => _box.get(id);

  List<ScheduleOccurrence> getAllOccurrences() => _box.values.toList();

  Future<ScheduleOccurrence?> getOrCreateCurrentOccurrence(
    ScheduleRule rule,
  ) async {
    final dueDate = rule.nextDueDate;

    if (rule.endDate != null && dueDate.isAfter(rule.endDate!)) {
      return null;
    }

    final id = ScheduleOccurrence.idFor(
      scheduleRuleId: rule.id,
      dueDate: dueDate,
    );
    final existing = _box.get(id);
    if (existing != null) {
      return existing;
    }

    final occurrence = ScheduleOccurrence(
      id: id,
      scheduleRuleId: rule.id,
      dueDate: dueDate,
    );
    await _box.put(occurrence.id, occurrence);
    return occurrence;
  }

  Future<ScheduleOccurrence> completeOccurrence(
    ScheduleOccurrence occurrence,
  ) async {
    if (occurrence.status == ScheduleOccurrenceStatus.completed) {
      return occurrence;
    }

    final completed = ScheduleOccurrence(
      id: occurrence.id,
      scheduleRuleId: occurrence.scheduleRuleId,
      dueDate: occurrence.dueDate,
      status: ScheduleOccurrenceStatus.completed,
    );

    await _box.put(completed.id, completed);
    return completed;
  }

  Future<ScheduleRule> advanceRuleAfterOccurrence(
    ScheduleRule rule,
    ScheduleOccurrence occurrence,
  ) async {
    if (rule.frequency == Frequency.oneTime) {
      return rule;
    }

    if (rule.nextDueDate != occurrence.dueDate) {
      return rule;
    }

    final nextDueDate = ruleService.calculateNextDueDate(rule);
    final updatedRule = rule.copyWith(nextDueDate: nextDueDate);
    await ruleService.updateRule(updatedRule);
    return updatedRule;
  }
}
