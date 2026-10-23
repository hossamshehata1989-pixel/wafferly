/// Pure date policy for projecting a card's expected payment due date.
///
/// This is an estimate only. When the issuer provides the actual due date for
/// a statement, that actual date should take precedence over this projection.
abstract final class CreditCardDueDatePolicy {
  static const fixedCalendarDay = 'fixed_calendar_day';
  static const fixedOffsetDays = 'fixed_offset_days';

  static const noAdjustment = 'no_adjustment';
  static const nextBusinessDay = 'next_business_day';
  static const previousBusinessDay = 'previous_business_day';

  static DateTime forStatementClose({
    required DateTime statementCloseDate,
    required String calculationMethod,
    required int? paymentDueDay,
    required int? dueDaysAfterStatement,
    required String weekendHolidayPolicy,
  }) {
    final closeDate = _dateOnly(statementCloseDate);
    if (calculationMethod == fixedOffsetDays) {
      final days = dueDaysAfterStatement;
      if (days == null || days < 1 || days > 90) {
        throw ArgumentError.value(
          days,
          'dueDaysAfterStatement',
          'Due-date offset must be between 1 and 90 days.',
        );
      }
      return _adjustWeekend(
        closeDate.add(Duration(days: days)),
        weekendHolidayPolicy,
      );
    }

    if (paymentDueDay == null || paymentDueDay < 1 || paymentDueDay > 31) {
      throw ArgumentError.value(
        paymentDueDay,
        'paymentDueDay',
        'Payment due day must be between 1 and 31.',
      );
    }
    final nextMonth = DateTime(closeDate.year, closeDate.month + 1, 1);
    final due = _dateForDay(nextMonth.year, nextMonth.month, paymentDueDay);
    return _adjustWeekend(due, weekendHolidayPolicy);
  }

  /// Wafferly V1 handles weekend adjustments only. Public holidays cannot be
  /// inferred reliably without an issuer/country calendar, so actual dates
  /// from statements or bank messages must override this estimate.
  static DateTime _adjustWeekend(DateTime date, String policy) {
    var result = _dateOnly(date);
    if (policy == nextBusinessDay) {
      while (_isEgyptWeekend(result)) {
        result = result.add(const Duration(days: 1));
      }
    } else if (policy == previousBusinessDay) {
      while (_isEgyptWeekend(result)) {
        result = result.subtract(const Duration(days: 1));
      }
    }
    return result;
  }

  // Egypt's standard weekend is Friday/Saturday. This is deliberately named
  // in the helper so it can later be replaced by a profile-specific calendar.
  static bool _isEgyptWeekend(DateTime date) =>
      date.weekday == DateTime.friday || date.weekday == DateTime.saturday;

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static DateTime _dateForDay(int year, int month, int requestedDay) {
    final first = DateTime(year, month, 1);
    final lastDay = DateTime(first.year, first.month + 1, 0).day;
    return DateTime(first.year, first.month, requestedDay.clamp(1, lastDay).toInt());
  }
}
