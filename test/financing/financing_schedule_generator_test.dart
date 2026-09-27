import 'package:flutter_test/flutter_test.dart';
import 'package:wafferly/core/money/money.dart';
import 'package:wafferly/financing/domain/financing_rate_model.dart';
import 'package:wafferly/financing/domain/financing_schedule_generator.dart';

void main() {
  const rate = FinancingRateModel(
    ratePercent: '12',
    rateType: FinancingRateType.fixed,
    ratePeriod: FinancingRatePeriod.annual,
    periodsPerYear: 12,
    roundingScale: 2,
    roundingMode: FinancingRoundingMode.halfUp,
  );

  test('generates stable installment identity and monthly dates', () {
    const generator = FinancingScheduleGenerator();

    final schedule = generator.generate(
      scheduleId: 'schedule-1',
      principal: Money.parse('1000'),
      installmentCount: 3,
      paymentFrequency: 'monthly',
      firstDueDate: DateTime(2026, 1, 15),
      rate: rate,
    );

    expect(schedule, hasLength(3));
    expect(schedule[0].installmentId, 'schedule-1|1');
    expect(schedule[1].installmentId, 'schedule-1|2');
    expect(schedule[2].installmentId, 'schedule-1|3');
    expect(schedule[0].dueDate, DateTime(2026, 1, 15));
    expect(schedule[1].dueDate, DateTime(2026, 2, 15));
    expect(schedule[2].dueDate, DateTime(2026, 3, 15));
  });

  test('monthly end-of-month anchor stays end of month', () {
    const generator = FinancingScheduleGenerator();

    final schedule = generator.generate(
      scheduleId: 'eom',
      principal: Money.parse('1000'),
      installmentCount: 4,
      paymentFrequency: 'monthly',
      firstDueDate: DateTime(2026, 1, 31),
      rate: rate,
    );

    expect(schedule.map((item) => item.dueDate), [
      DateTime(2026, 1, 31),
      DateTime(2026, 2, 28),
      DateTime(2026, 3, 31),
      DateTime(2026, 4, 30),
    ]);
  });

  test('monthly non-end-of-month anchor clamps only when required', () {
    const generator = FinancingScheduleGenerator();

    final schedule = generator.generate(
      scheduleId: 'clamp',
      principal: Money.parse('1000'),
      installmentCount: 3,
      paymentFrequency: 'monthly',
      firstDueDate: DateTime(2026, 1, 30),
      rate: rate,
    );

    expect(schedule.map((item) => item.dueDate), [
      DateTime(2026, 1, 30),
      DateTime(2026, 2, 28),
      DateTime(2026, 3, 30),
    ]);
  });

  test('same inputs produce identical schedules', () {
    const generator = FinancingScheduleGenerator();

    final first = generator.generate(
      scheduleId: 'same',
      principal: Money.parse('2500'),
      installmentCount: 6,
      paymentFrequency: 'monthly',
      firstDueDate: DateTime(2026, 2, 28, 10, 30),
      rate: rate,
    );
    final second = generator.generate(
      scheduleId: 'same',
      principal: Money.parse('2500'),
      installmentCount: 6,
      paymentFrequency: 'monthly',
      firstDueDate: DateTime(2026, 2, 28, 10, 30),
      rate: rate,
    );

    expect(first.map(_signature), second.map(_signature));
  });

  test('fees are additive and do not alter principal amortization', () {
    const generator = FinancingScheduleGenerator();

    final schedule = generator.generate(
      scheduleId: 'fees',
      principal: Money.parse('1000'),
      installmentCount: 2,
      paymentFrequency: 'monthly',
      firstDueDate: DateTime(2026, 1, 10),
      rate: rate,
      fees: Money.parse('5'),
    );

    expect(schedule[0].fees, Money.parse('5'));
    expect(schedule[0].amount, schedule[0].principal + schedule[0].interest + schedule[0].fees);
    expect(schedule.last.closingPrincipal, Money.zero);
  });

  test('rejects unsupported frequency', () {
    const generator = FinancingScheduleGenerator();

    expect(
      () => generator.generate(
        scheduleId: 'bad',
        principal: Money.parse('1000'),
        installmentCount: 2,
        paymentFrequency: 'quarterly',
        firstDueDate: DateTime(2026, 1, 10),
        rate: rate,
      ),
      throwsArgumentError,
    );
  });
}

String _signature(dynamic item) =>
    '${item.installmentId}|${item.sequence}|${item.dueDate.toIso8601String()}|'
    '${item.openingPrincipal}|${item.principal}|${item.interest}|${item.fees}|'
    '${item.amount}|${item.closingPrincipal}';
