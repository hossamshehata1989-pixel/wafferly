import 'credit_card_due_date_policy.dart';
import 'credit_card_expense_projection_service.dart';

/// Shared default-date policy for a new Credit Card installment plan.
///
/// [referenceDate] is the date the installment commitment became effective:
/// the purchase date for an installment purchase created from the beginning,
/// or the actual conversion date when converting an already-posted regular
/// purchase later. It is deliberately not the app-entry/record-creation time.
///
/// When the card has cycle configuration, the first due date is the due date
/// for the statement cycle that contains [referenceDate]. This ensures a
/// conversion after a statement has closed starts in the next eligible cycle.
/// If cycle configuration is incomplete, the policy uses a deterministic
/// next-calendar-month fallback.
final class CreditCardFirstDueDatePolicy {
  const CreditCardFirstDueDatePolicy._();

  static DateTime defaultFirstDueDate({
    required DateTime referenceDate,
    required int? paymentDueDay,
    int? statementDay,
    String dueDateCalculationMethod = CreditCardDueDatePolicy.fixedCalendarDay,
    int? dueDaysAfterStatement,
    String weekendHolidayPolicy = CreditCardDueDatePolicy.noAdjustment,
  }) {
    final hasValidDueRule =
        dueDateCalculationMethod == CreditCardDueDatePolicy.fixedOffsetDays
            ? dueDaysAfterStatement != null
            : paymentDueDay != null;

    if (statementDay != null && hasValidDueRule) {
      final closeDate =
          CreditCardExpenseProjectionService.statementCloseDateForCharge(
        referenceDate,
        statementDay,
      );
      return CreditCardDueDatePolicy.forStatementClose(
        statementCloseDate: closeDate,
        calculationMethod: dueDateCalculationMethod,
        paymentDueDay: paymentDueDay,
        dueDaysAfterStatement: dueDaysAfterStatement,
        weekendHolidayPolicy: weekendHolidayPolicy,
      );
    }

    final targetMonth = DateTime(referenceDate.year, referenceDate.month + 1, 1);
    final lastDay = DateTime(targetMonth.year, targetMonth.month + 1, 0).day;
    final requestedDay = (paymentDueDay ?? referenceDate.day)
        .clamp(1, lastDay)
        .toInt();
    return DateTime(targetMonth.year, targetMonth.month, requestedDay);
  }

  /// Calculates a contractual installment due date from the original anchor.
  /// Each installment is based on [firstDueDate], not the previous installment,
  /// so a Jan-31 schedule is Jan-31, Feb-28/29, Mar-31, etc.
  /// The zero-based index 0 returns the first due date; negative indices fail.
  static DateTime installmentDueDate({
    required DateTime firstDueDate,
    required int installmentIndex,
  }) {
    if (installmentIndex < 0) {
      throw ArgumentError.value(
        installmentIndex,
        'installmentIndex',
        'Must be zero or greater.',
      );
    }
    final targetMonth = DateTime(
      firstDueDate.year,
      firstDueDate.month + installmentIndex,
      1,
    );
    final lastDay = DateTime(targetMonth.year, targetMonth.month + 1, 0).day;
    final day = firstDueDate.day.clamp(1, lastDay).toInt();
    return DateTime(targetMonth.year, targetMonth.month, day);
  }
}
