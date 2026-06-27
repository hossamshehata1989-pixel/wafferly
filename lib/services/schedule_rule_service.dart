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
        return DateTime(
          rule.nextDueDate.year,
          rule.nextDueDate.month + 1,
          rule.nextDueDate.day,
        );

      case Frequency.yearly:
        return DateTime(
          rule.nextDueDate.year + 1,
          rule.nextDueDate.month,
          rule.nextDueDate.day,
        );
    }
  }
}
