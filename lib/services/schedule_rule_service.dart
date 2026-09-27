import 'package:hive/hive.dart';

import '../models/schedule_rule.dart';
import '../models/enums/frequency.dart';

class ScheduleRuleService {
  static const String _boxName = 'schedule_rules';

  Box<ScheduleRule> get _box => Hive.box<ScheduleRule>(_boxName);

  // =====================================================
  // Create
  // =====================================================

  Future<void> createRule(ScheduleRule rule) async {
    await _box.put(rule.id, rule);
  }

  // =====================================================
  // Read
  // =====================================================

  ScheduleRule? getRule(String id) {
    return _box.get(id);
  }

  List<ScheduleRule> getAllRules() {
    return _box.values.toList();
  }

  // =====================================================
  // Update
  // =====================================================

  Future<void> updateRule(ScheduleRule rule) async {
    await _box.put(rule.id, rule);
  }

  // =====================================================
  // Delete
  // =====================================================

  Future<void> deleteRule(String id) async {
    await _box.delete(id);
  }

  // =====================================================
  // Due Date Calculator
  // =====================================================

  DateTime calculateNextDueDate(ScheduleRule rule) {
    switch (rule.frequency) {
      case Frequency.oneTime:
        return rule.nextDueDate;

      case Frequency.daily:
        return rule.nextDueDate.add(const Duration(days: 1));

      case Frequency.weekly:
        return rule.nextDueDate.add(const Duration(days: 7));

      case Frequency.monthly:
        return _nextMonthlyDate(rule);

      case Frequency.yearly:
        return _nextYearlyDate(rule);
    }
  }

  DateTime _nextMonthlyDate(ScheduleRule rule) {
    final anchorDay = rule.startDate.day;
    final current = rule.nextDueDate;
    final targetYear = current.year + (current.month == 12 ? 1 : 0);
    final targetMonth = current.month == 12 ? 1 : current.month + 1;
    final lastDay = DateTime(targetYear, targetMonth + 1, 0).day;

    // ADR-046: an end-of-month anchor stays end-of-month.
    final anchorIsEndOfMonth =
        rule.startDate.day ==
        DateTime(rule.startDate.year, rule.startDate.month + 1, 0).day;
    final day = anchorIsEndOfMonth ? lastDay : (anchorDay <= lastDay ? anchorDay : lastDay);

    return DateTime(targetYear, targetMonth, day);
  }

  DateTime _nextYearlyDate(ScheduleRule rule) {
    final targetYear = rule.nextDueDate.year + 1;
    final targetMonth = rule.startDate.month;
    final anchorDay = rule.startDate.day;
    final lastDay = DateTime(targetYear, targetMonth + 1, 0).day;
    final day = anchorDay <= lastDay ? anchorDay : lastDay;

    return DateTime(targetYear, targetMonth, day);
  }
}
