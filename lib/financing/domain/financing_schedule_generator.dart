import '../../core/money/money.dart';
import 'financing_amortization.dart';
import 'financing_rate_model.dart';

/// Pure deterministic financing schedule result.
///
/// This is calculation output only. Persistence of FinancingSchedule and
/// FinancingInstallment remains outside this calculator.
class FinancingScheduleDraft {
  final String scheduleId;
  final int sequence;
  final DateTime dueDate;
  final String installmentId;
  final Money openingPrincipal;
  final Money principal;
  final Money interest;
  final Money fees;
  final Money amount;
  final Money closingPrincipal;

  const FinancingScheduleDraft({
    required this.scheduleId,
    required this.sequence,
    required this.dueDate,
    required this.installmentId,
    required this.openingPrincipal,
    required this.principal,
    required this.interest,
    required this.fees,
    required this.amount,
    required this.closingPrincipal,
  });
}

/// Pure deterministic generator for financing installment obligations.
///
/// ADR-053 owns the amortization math. This class adds stable schedule
/// identity and due-date generation without mutating Hive, Accounts,
/// Transactions, Statements, or the Financial Engine.
class FinancingScheduleGenerator {
  final FinancingAmortizationCalculator amortizationCalculator;

  const FinancingScheduleGenerator({
    this.amortizationCalculator = const FinancingAmortizationCalculator(),
  });

  List<FinancingScheduleDraft> generate({
    required String scheduleId,
    required Money principal,
    required int installmentCount,
    required String paymentFrequency,
    required DateTime firstDueDate,
    required FinancingRateModel rate,
    Money? fees,
  }) {
    if (scheduleId.trim().isEmpty) {
      throw ArgumentError.value(scheduleId, 'scheduleId', 'Cannot be empty.');
    }
    final effectiveFees = fees ?? Money.zero;
    if (effectiveFees.isNegative) {
      throw ArgumentError.value(effectiveFees, 'fees', 'Fees cannot be negative.');
    }
    final frequency = _parseFrequency(paymentFrequency);
    final rows = amortizationCalculator.calculate(
      principal: principal,
      installmentCount: installmentCount,
      rate: rate,
    );

    return List.unmodifiable(
      rows.map((row) {
        final dueDate = _dueDate(
          firstDueDate: firstDueDate,
          frequency: frequency,
          sequence: row.sequence,
        );
        final installmentFees = effectiveFees;
        final amount = row.payment + installmentFees;
        return FinancingScheduleDraft(
          scheduleId: scheduleId,
          sequence: row.sequence,
          dueDate: dueDate,
          installmentId: '$scheduleId|${row.sequence}',
          openingPrincipal: row.openingPrincipal,
          principal: row.principal,
          interest: row.interest,
          fees: installmentFees,
          amount: amount,
          closingPrincipal: row.closingPrincipal,
        );
      }),
    );
  }

  _FinancingFrequency _parseFrequency(String value) {
    switch (value.trim().toLowerCase()) {
      case 'onetime':
      case 'one_time':
      case 'one-time':
        return _FinancingFrequency.oneTime;
      case 'daily':
        return _FinancingFrequency.daily;
      case 'weekly':
        return _FinancingFrequency.weekly;
      case 'monthly':
        return _FinancingFrequency.monthly;
      case 'yearly':
      case 'annual':
        return _FinancingFrequency.yearly;
      default:
        throw ArgumentError.value(
          value,
          'paymentFrequency',
          'Unsupported financing payment frequency.',
        );
    }
  }

  DateTime _dueDate({
    required DateTime firstDueDate,
    required _FinancingFrequency frequency,
    required int sequence,
  }) {
    final offset = sequence - 1;
    switch (frequency) {
      case _FinancingFrequency.oneTime:
        if (sequence != 1) {
          throw ArgumentError(
            'oneTime financing frequency requires one installment.',
          );
        }
        return firstDueDate;
      case _FinancingFrequency.daily:
        return firstDueDate.add(Duration(days: offset));
      case _FinancingFrequency.weekly:
        return firstDueDate.add(Duration(days: offset * 7));
      case _FinancingFrequency.monthly:
        return _addMonths(firstDueDate, offset);
      case _FinancingFrequency.yearly:
        return _addYears(firstDueDate, offset);
    }
  }

  /// Monthly rule follows ADR-046: an end-of-month anchor stays end-of-month;
  /// otherwise the original day is clamped to the target month's last day.
  DateTime _addMonths(DateTime anchor, int months) {
    final targetMonthIndex = anchor.year * 12 + (anchor.month - 1) + months;
    final targetYear = targetMonthIndex ~/ 12;
    final targetMonth = targetMonthIndex % 12 + 1;
    final targetLastDay = _daysInMonth(targetYear, targetMonth);
    final isEndOfMonth = anchor.day == _daysInMonth(anchor.year, anchor.month);
    final day = isEndOfMonth ? targetLastDay : anchor.day.clamp(1, targetLastDay);
    return DateTime(
      targetYear,
      targetMonth,
      day,
      anchor.hour,
      anchor.minute,
      anchor.second,
      anchor.millisecond,
      anchor.microsecond,
    );
  }

  DateTime _addYears(DateTime anchor, int years) {
    final targetYear = anchor.year + years;
    final targetLastDay = _daysInMonth(targetYear, anchor.month);
    final day = anchor.day.clamp(1, targetLastDay);
    return DateTime(
      targetYear,
      anchor.month,
      day,
      anchor.hour,
      anchor.minute,
      anchor.second,
      anchor.millisecond,
      anchor.microsecond,
    );
  }

  int _daysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }
}

enum _FinancingFrequency { oneTime, daily, weekly, monthly, yearly }
