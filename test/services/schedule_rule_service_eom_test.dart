import 'package:flutter_test/flutter_test.dart';

import 'package:wafferly/models/enums/frequency.dart';
import 'package:wafferly/models/schedule_rule.dart';
import 'package:wafferly/services/schedule_rule_service.dart';

void main() {
final service = ScheduleRuleService();
  ScheduleRule rule({
    required DateTime startDate,
    required DateTime nextDueDate,
  }) {
    return ScheduleRule(
      id: 'eom-test',
      frequency: Frequency.monthly,
      startDate: startDate,
      nextDueDate: nextDueDate,
    );
  }

  test('clamps January 31 to February 28 and restores month end in March', () {
    final jan31 = rule(
      startDate: DateTime(2027, 1, 31),
      nextDueDate: DateTime(2027, 1, 31),
    );

    final feb28 = service.calculateNextDueDate(jan31);
    expect(feb28, DateTime(2027, 2, 28));

    final mar31 = service.calculateNextDueDate(
      jan31.copyWith(nextDueDate: feb28),
    );
    expect(mar31, DateTime(2027, 3, 31));
  });

  test('keeps an end-of-month rule on the last day of every month', () {
    final april30 = rule(
      startDate: DateTime(2027, 4, 30),
      nextDueDate: DateTime(2027, 4, 30),
    );

    expect(
      service.calculateNextDueDate(april30),
      DateTime(2027, 5, 31),
    );

    expect(
      service.calculateNextDueDate(
        april30.copyWith(nextDueDate: DateTime(2027, 5, 31)),
      ),
      DateTime(2027, 6, 30),
    );
  });

  test('preserves a non-EOM day-of-month anchor across short months', () {
    final jan30 = rule(
      startDate: DateTime(2027, 1, 30),
      nextDueDate: DateTime(2027, 1, 30),
    );

    final feb28 = service.calculateNextDueDate(jan30);
    expect(feb28, DateTime(2027, 2, 28));

    final mar30 = service.calculateNextDueDate(
      jan30.copyWith(nextDueDate: feb28),
    );
    expect(mar30, DateTime(2027, 3, 30));
  });

  test('handles leap-year February for an end-of-month rule', () {
    final jan31 = rule(
      startDate: DateTime(2028, 1, 31),
      nextDueDate: DateTime(2028, 1, 31),
    );

    expect(
      service.calculateNextDueDate(jan31),
      DateTime(2028, 2, 29),
    );

    expect(
      service.calculateNextDueDate(
        jan31.copyWith(nextDueDate: DateTime(2028, 2, 29)),
      ),
      DateTime(2028, 3, 31),
    );
  });

  test('handles December to January without overflow', () {
    final dec31 = rule(
      startDate: DateTime(2027, 12, 31),
      nextDueDate: DateTime(2027, 12, 31),
    );

    expect(
      service.calculateNextDueDate(dec31),
      DateTime(2028, 1, 31),
    );
  });

  test('daily and weekly calculations remain unchanged', () {
    final daily = ScheduleRule(
      id: 'daily',
      frequency: Frequency.daily,
      startDate: DateTime(2027, 1, 31),
      nextDueDate: DateTime(2027, 1, 31),
    );
    expect(
      service.calculateNextDueDate(daily),
      DateTime(2027, 2, 1),
    );

    final weekly = daily.copyWith(
      frequency: Frequency.weekly,
    );
    expect(
      service.calculateNextDueDate(weekly),
      DateTime(2027, 2, 7),
    );
  });
}
