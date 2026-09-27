import 'package:hive/hive.dart';

import '../models/schedule_rule.dart';
import '../models/enums/frequency.dart';

class ScheduleRuleService {
  static const String _boxName = 'schedule_rules';

  Box<ScheduleRule> get _box => Hive.box<ScheduleRule>(_boxName);

  Future<void> createRule(ScheduleRule rule) async {
    await _box.put(rule.id, rule);
  }

  ScheduleRule? getRule(String id) {
    return _box.get(id);
  }

  List<ScheduleRule> getAllRules() {
    return _box.values.toList();
  }

  Future<void> updateRule(ScheduleRule rule) async {
    await _box.put(rule.id, rule);
  }

  Future<void> deleteRule(String id) async {
    await _box.delete(id);
  }

  /// Calculates the next occurrence without relying on Dart DateTime
  /// overflow semantics.
  ///
  /// Monthly recurrence preserves the original day-of-month anchor from
  /// [ScheduleRule.startDate]. If the target month does not contain that
  /// day, the occurrence is clamped to the target month's last day.
  ///
  /// End-of-month anchors remain end-of-month in every subsequent month.
  DateTime calculateNextDueDate(ScheduleRule rule) {
    switch (rule.frequency) {
      case Frequency.oneTime:
        return rule.nextDueDate;

      case Frequency.daily:
        return rule.nextDueDate.add(const Duration(days: 1));

      case Frequency.weekly:
        return rule.nextDueDate.add(const Duration(days: 7));

      case Frequency.monthly:
        return _calculateNextMonthlyDueDate(rule);

      case Frequency.yearly:
        return DateTime(
          rule.nextDueDate.year + 1,
          rule.nextDueDate.month,
          rule.nextDueDate.day,
        );
    }
  }

  DateTime _calculateNextMonthlyDueDate(ScheduleRule rule) {
    final current = rule.nextDueDate;
    final targetYear = current.month == DateTime.december
        ? current.year + 1
        : current.year;
    final targetMonth = current.month == DateTime.december
        ? DateTime.january
        : current.month + 1;

    final anchorDay = rule.startDate.day;
    final targetLastDay = _lastDayOfMonth(targetYear, targetMonth);

    final targetDay = _isLastDayOfMonth(rule.startDate)
        ? targetLastDay
        : anchorDay.clamp(1, targetLastDay);

    return DateTime(targetYear, targetMonth, targetDay);
  }

  bool _isLastDayOfMonth(DateTime date) {
    return date.day == _lastDayOfMonth(date.year, date.month);
  }

  int _lastDayOfMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }
}
