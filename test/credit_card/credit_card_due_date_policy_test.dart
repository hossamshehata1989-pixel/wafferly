import 'package:flutter_test/flutter_test.dart';
import 'package:wafferly/application/credit_card/credit_card_due_date_policy.dart';

void main() {
  test('fixed offset adds calendar days to statement close', () {
    final dueDate = CreditCardDueDatePolicy.forStatementClose(
      statementCloseDate: DateTime(2026, 11, 7),
      calculationMethod: CreditCardDueDatePolicy.fixedOffsetDays,
      paymentDueDay: null,
      dueDaysAfterStatement: 25,
      weekendHolidayPolicy: CreditCardDueDatePolicy.noAdjustment,
    );

    expect(dueDate, DateTime(2026, 12, 2));
  });

  test('Egypt weekend adjustment moves Friday to Sunday when selected', () {
    final dueDate = CreditCardDueDatePolicy.forStatementClose(
      statementCloseDate: DateTime(2026, 1, 1),
      calculationMethod: CreditCardDueDatePolicy.fixedOffsetDays,
      paymentDueDay: null,
      dueDaysAfterStatement: 1,
      weekendHolidayPolicy: CreditCardDueDatePolicy.nextBusinessDay,
    );

    // 2 January 2026 is Friday; the next regular working day is Sunday.
    expect(dueDate, DateTime(2026, 1, 4));
  });

  test('fixed calendar day is clamped for shorter months', () {
    final dueDate = CreditCardDueDatePolicy.forStatementClose(
      statementCloseDate: DateTime(2026, 1, 31),
      calculationMethod: CreditCardDueDatePolicy.fixedCalendarDay,
      paymentDueDay: 31,
      dueDaysAfterStatement: null,
      weekendHolidayPolicy: CreditCardDueDatePolicy.noAdjustment,
    );

    expect(dueDate, DateTime(2026, 2, 28));
  });
}
