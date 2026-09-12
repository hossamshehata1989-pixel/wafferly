import 'package:flutter_test/flutter_test.dart';
import 'package:wafferly/models/enums/schedule_occurrence_status.dart';
import 'package:wafferly/models/schedule_occurrence.dart';

void main() {
  group('ScheduleOccurrence', () {
    final dueDate = DateTime(2026, 9, 12);

    test('identity is deterministic for the same rule and slot', () {
      expect(
        ScheduleOccurrence.idFor(
          scheduleRuleId: 'rule-1',
          dueDate: dueDate,
        ),
        ScheduleOccurrence.idFor(
          scheduleRuleId: 'rule-1',
          dueDate: dueDate,
        ),
      );
    });

    test('different recurrence slots have different identities', () {
      expect(
        ScheduleOccurrence.idFor(
          scheduleRuleId: 'rule-1',
          dueDate: dueDate,
        ),
        isNot(
          ScheduleOccurrence.idFor(
            scheduleRuleId: 'rule-1',
            dueDate: dueDate.add(const Duration(days: 1)),
          ),
        ),
      );
    });

    test('lifecycle is separate from temporal scheduling state', () {
      final occurrence = ScheduleOccurrence(
        id: 'rule-1|2026-09-12T00:00:00.000',
        scheduleRuleId: 'rule-1',
        dueDate: dueDate,
      );

      expect(occurrence.status, ScheduleOccurrenceStatus.pending);
      expect(occurrence.status, isNotNull);
    });
  });
}
