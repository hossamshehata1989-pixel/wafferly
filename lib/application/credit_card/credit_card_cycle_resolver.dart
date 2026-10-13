/// Single source of truth for recurring Credit Card statement-cycle dates.
///
/// Policy: a charge belongs to the first statement close on/after its purchase
/// date. The payment due date is on the configured due day in the month AFTER
/// that close. Analysis for ordinary card purchases follows that expected
/// payment month; installment rows already carry their contractual due dates.
final class CreditCardCycleResolver {
  const CreditCardCycleResolver._();

  static DateTime closeDateFor(DateTime purchaseDate, int statementDay) {
    _validateDay(statementDay, 'statementDay');
    final thisMonth = _dateForDay(purchaseDate.year, purchaseDate.month, statementDay);
    if (!DateTime(purchaseDate.year, purchaseDate.month, purchaseDate.day).isAfter(thisMonth)) {
      return thisMonth;
    }
    final nextMonth = DateTime(purchaseDate.year, purchaseDate.month + 1, 1);
    return _dateForDay(nextMonth.year, nextMonth.month, statementDay);
  }

  static DateTime dueDateFor(DateTime closeDate, int paymentDueDay) {
    _validateDay(paymentDueDay, 'paymentDueDay');
    final nextMonth = DateTime(closeDate.year, closeDate.month + 1, 1);
    return _dateForDay(nextMonth.year, nextMonth.month, paymentDueDay);
  }

  /// The reporting month for a normal unconverted purchase is its expected
  /// payment month, not its purchase month or statement-close month.
  static DateTime cycleMonthFor(DateTime purchaseDate, int statementDay, int paymentDueDay) {
    final closeDate = closeDateFor(purchaseDate, statementDay);
    final dueDate = dueDateFor(closeDate, paymentDueDay);
    return DateTime(dueDate.year, dueDate.month, 1);
  }

  static DateTime fallbackMonthFor(DateTime purchaseDate) {
    final next = DateTime(purchaseDate.year, purchaseDate.month + 1, 1);
    return DateTime(next.year, next.month, purchaseDate.day.clamp(1, _daysInMonth(next.year, next.month)).toInt());
  }

  static DateTime _dateForDay(int year, int month, int day) {
    final first = DateTime(year, month, 1);
    return DateTime(first.year, first.month, day.clamp(1, DateTime(first.year, first.month + 1, 0).day).toInt());
  }

  static int _daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

  static void _validateDay(int day, String name) {
    if (day < 1 || day > 31) throw ArgumentError.value(day, name, 'Must be between 1 and 31.');
  }
}
