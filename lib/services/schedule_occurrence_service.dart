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

  Future<List<ScheduleOccurrence>> getOrCreateOccurrencesThroughDate(
    ScheduleRule rule,
    DateTime throughDate,
  ) async {
    final targetDate = DateTime(throughDate.year, throughDate.month, throughDate.day);
    final occurrences = <ScheduleOccurrence>[];
    var dueDate = rule.nextDueDate;

    while (!dueDate.isAfter(targetDate)) {
      if (rule.endDate != null && dueDate.isAfter(rule.endDate!)) {
        break;
      }

      final id = ScheduleOccurrence.idFor(
        scheduleRuleId: rule.id,
        dueDate: dueDate,
      );
      final existing = _box.get(id);
      final occurrence = existing ??
          ScheduleOccurrence(
            id: id,
            scheduleRuleId: rule.id,
            dueDate: dueDate,
          );

      if (existing == null) {
        await _box.put(occurrence.id, occurrence);
      }

      occurrences.add(occurrence);

      if (rule.frequency == Frequency.oneTime) {
        break;
      }

      final nextDueDate = ruleService.calculateNextDueDate(
        rule.copyWith(nextDueDate: dueDate),
      );
      if (!nextDueDate.isAfter(dueDate)) {
        break;
      }
      dueDate = nextDueDate;
    }

    return occurrences;
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

    var currentRule = rule;

    if (currentRule.nextDueDate != occurrence.dueDate) {
      return currentRule;
    }

    while (true) {
      final nextDueDate = ruleService.calculateNextDueDate(currentRule);

      if (currentRule.endDate != null &&
          nextDueDate.isAfter(currentRule.endDate!)) {
        final updatedRule = currentRule.copyWith(nextDueDate: nextDueDate);
        await ruleService.updateRule(updatedRule);
        return updatedRule;
      }

      final nextOccurrenceId = ScheduleOccurrence.idFor(
        scheduleRuleId: currentRule.id,
        dueDate: nextDueDate,
      );
      final nextOccurrence = _box.get(nextOccurrenceId);

      final updatedRule = currentRule.copyWith(nextDueDate: nextDueDate);
      await ruleService.updateRule(updatedRule);
      currentRule = updatedRule;

      // If the next slot was already completed out of order, keep advancing
      // the cursor until the first pending/missing occurrence is reached.
      if (nextOccurrence?.status == ScheduleOccurrenceStatus.completed) {
        continue;
      }

      return currentRule;
    }
  }
}
