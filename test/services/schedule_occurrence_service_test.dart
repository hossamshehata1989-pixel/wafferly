import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:wafferly/models/enums/frequency.dart';
import 'package:wafferly/models/enums/schedule_occurrence_status.dart';
import 'package:wafferly/models/schedule_occurrence.dart';
import 'package:wafferly/models/schedule_rule.dart';
import 'package:wafferly/services/schedule_occurrence_service.dart';
import 'package:wafferly/services/schedule_rule_service.dart';

class _TestScheduleRuleService extends ScheduleRuleService {
  final Map<String, ScheduleRule> rules = {};

  @override
  Future<void> updateRule(ScheduleRule rule) async {
    rules[rule.id] = rule;
  }

  @override
  DateTime calculateNextDueDate(ScheduleRule rule) {
    return super.calculateNextDueDate(rule);
  }
}

void main() {
  setUpAll(() async {
    Hive.init('test_schedule_occurrences');
    if (!Hive.isAdapterRegistered(98)) {
      Hive.registerAdapter(ScheduleOccurrenceAdapter());
    }
    if (!Hive.isAdapterRegistered(99)) {
      Hive.registerAdapter(ScheduleOccurrenceStatusAdapter());
    }
    await Hive.openBox<ScheduleOccurrence>('schedule_occurrences');
  });

  tearDown(() async {
    await Hive.box<ScheduleOccurrence>('schedule_occurrences').clear();
  });

  tearDownAll(() async {
    await Hive.deleteBoxFromDisk('schedule_occurrences');
  });

  ScheduleRule rule({
    required Frequency frequency,
    required DateTime dueDate,
    DateTime? endDate,
  }) {
    return ScheduleRule(
      id: 'rule-1',
      frequency: frequency,
      startDate: dueDate,
      nextDueDate: dueDate,
      endDate: endDate,
    );
  }

  test('oneTime creates one occurrence and does not advance the cursor', () async {
    final rules = _TestScheduleRuleService();
    final service = ScheduleOccurrenceService(ruleService: rules);
    final current = rule(
      frequency: Frequency.oneTime,
      dueDate: DateTime(2026, 9, 12),
    );

    final occurrence = await service.getOrCreateCurrentOccurrence(current);
    final updatedRule = await service.advanceRuleAfterOccurrence(
      current,
      occurrence!,
    );

    expect(occurrence.status, ScheduleOccurrenceStatus.pending);
    expect(updatedRule.nextDueDate, current.nextDueDate);
    expect(rules.rules, isEmpty);
  });

  test('daily occurrence advances the rule cursor only after processing', () async {
    final rules = _TestScheduleRuleService();
    final service = ScheduleOccurrenceService(ruleService: rules);
    final current = rule(
      frequency: Frequency.daily,
      dueDate: DateTime(2026, 9, 12),
    );

    final occurrence = await service.getOrCreateCurrentOccurrence(current);
    expect(rules.rules, isEmpty);

    await service.advanceRuleAfterOccurrence(current, occurrence!);

    expect(rules.rules['rule-1']!.nextDueDate, DateTime(2026, 9, 13));
  });

  test('weekly occurrence advances by seven days', () async {
    final rules = _TestScheduleRuleService();
    final service = ScheduleOccurrenceService(ruleService: rules);
    final current = rule(
      frequency: Frequency.weekly,
      dueDate: DateTime(2026, 9, 12),
    );

    final occurrence = await service.getOrCreateCurrentOccurrence(current);
    await service.advanceRuleAfterOccurrence(current, occurrence!);

    expect(rules.rules['rule-1']!.nextDueDate, DateTime(2026, 9, 19));
  });

  test('monthly occurrence uses the existing calculator', () async {
    final rules = _TestScheduleRuleService();
    final service = ScheduleOccurrenceService(ruleService: rules);
    final current = rule(
      frequency: Frequency.monthly,
      dueDate: DateTime(2026, 9, 12),
    );

    final occurrence = await service.getOrCreateCurrentOccurrence(current);
    await service.advanceRuleAfterOccurrence(current, occurrence!);

    expect(rules.rules['rule-1']!.nextDueDate, DateTime(2026, 10, 12));
  });

  test('yearly occurrence advances by one year', () async {
    final rules = _TestScheduleRuleService();
    final service = ScheduleOccurrenceService(ruleService: rules);
    final current = rule(
      frequency: Frequency.yearly,
      dueDate: DateTime(2026, 9, 12),
    );

    final occurrence = await service.getOrCreateCurrentOccurrence(current);
    await service.advanceRuleAfterOccurrence(current, occurrence!);

    expect(rules.rules['rule-1']!.nextDueDate, DateTime(2027, 9, 12));
  });

  test('generation is idempotent for the same recurrence slot', () async {
    final rules = _TestScheduleRuleService();
    final service = ScheduleOccurrenceService(ruleService: rules);
    final current = rule(
      frequency: Frequency.daily,
      dueDate: DateTime(2026, 9, 12),
    );

    final first = await service.getOrCreateCurrentOccurrence(current);
    final second = await service.getOrCreateCurrentOccurrence(current);

    expect(second!.id, first!.id);
    expect(Hive.box<ScheduleOccurrence>('schedule_occurrences').length, 1);
    expect(rules.rules, isEmpty);
  });

  test('advancement is idempotent when repeated for the same occurrence', () async {
    final rules = _TestScheduleRuleService();
    final service = ScheduleOccurrenceService(ruleService: rules);
    final current = rule(
      frequency: Frequency.daily,
      dueDate: DateTime(2026, 9, 12),
    );

    final occurrence = await service.getOrCreateCurrentOccurrence(current);
    final advanced = await service.advanceRuleAfterOccurrence(current, occurrence!);
    final repeated = await service.advanceRuleAfterOccurrence(advanced, occurrence);

    expect(advanced.nextDueDate, DateTime(2026, 9, 13));
    expect(repeated.nextDueDate, DateTime(2026, 9, 13));
  });

  test('does not generate beyond endDate', () async {
    final rules = _TestScheduleRuleService();
    final service = ScheduleOccurrenceService(ruleService: rules);
    final current = rule(
      frequency: Frequency.daily,
      dueDate: DateTime(2026, 9, 13),
      endDate: DateTime(2026, 9, 12),
    );

    final occurrence = await service.getOrCreateCurrentOccurrence(current);

    expect(occurrence, isNull);
    expect(Hive.box<ScheduleOccurrence>('schedule_occurrences').isEmpty, true);
    expect(rules.rules, isEmpty);
  });

test('advancement catches up over already completed future occurrences', () async {
  final rules = _TestScheduleRuleService();
  final service = ScheduleOccurrenceService(ruleService: rules);
  final current = rule(
    frequency: Frequency.daily,
    dueDate: DateTime(2026, 9, 12),
  );

  final currentOccurrence = await service.getOrCreateCurrentOccurrence(current);
  final futureOccurrence = ScheduleOccurrence(
    id: ScheduleOccurrence.idFor(
      scheduleRuleId: current.id,
      dueDate: DateTime(2026, 9, 13),
    ),
    scheduleRuleId: current.id,
    dueDate: DateTime(2026, 9, 13),
    status: ScheduleOccurrenceStatus.completed,
  );
  await Hive.box<ScheduleOccurrence>('schedule_occurrences').put(
    futureOccurrence.id,
    futureOccurrence,
  );

  final advanced = await service.advanceRuleAfterOccurrence(
    current,
    currentOccurrence!,
  );

  expect(advanced.nextDueDate, DateTime(2026, 9, 14));
  expect(rules.rules['rule-1']!.nextDueDate, DateTime(2026, 9, 14));
});
}
