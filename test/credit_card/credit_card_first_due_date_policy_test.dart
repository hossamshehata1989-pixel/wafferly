import 'package:flutter_test/flutter_test.dart';
import 'package:wafferly/application/credit_card/credit_card_due_date_policy.dart';
import 'package:wafferly/application/credit_card/credit_card_first_due_date_policy.dart';

void main() {
  group('CreditCardFirstDueDatePolicy', () {
    test('uses next month and the card payment due day', () {
      final result = CreditCardFirstDueDatePolicy.defaultFirstDueDate(
        referenceDate: DateTime(2026, 10, 12, 19, 30),
        paymentDueDay: 25,
      );

      expect(result, DateTime(2026, 11, 25));
    });

    test('clamps the configured due day in a short next month', () {
      final result = CreditCardFirstDueDatePolicy.defaultFirstDueDate(
        referenceDate: DateTime(2027, 1, 31),
        paymentDueDay: 31,
      );

      expect(result, DateTime(2027, 2, 28));
    });

    test('uses the reference day when the card has no payment due day', () {
      final result = CreditCardFirstDueDatePolicy.defaultFirstDueDate(
        referenceDate: DateTime(2026, 10, 12),
        paymentDueDay: null,
      );

      expect(result, DateTime(2026, 11, 12));
    });

    test(
      'backdated installment purchase derives first due date from its purchase cycle',
      () {
        final result = CreditCardFirstDueDatePolicy.defaultFirstDueDate(
          referenceDate: DateTime(2026, 10, 6),
          statementDay: 15,
          paymentDueDay: 15,
        );

        // The October 6 purchase belongs to the cycle closing October 15,
        // which is payable November 15.
        expect(result, DateTime(2026, 11, 15));
      },
    );

    test(
      'conversion after statement close starts after the next statement cycle',
      () {
        final result = CreditCardFirstDueDatePolicy.defaultFirstDueDate(
          referenceDate: DateTime(2026, 10, 25),
          statementDay: 15,
          paymentDueDay: 15,
        );

        // October has already closed. The next cycle closes November 15 and is
        // payable December 15; do not schedule the first installment alongside
        // the already-closed statement's November 15 due date.
        expect(result, DateTime(2026, 12, 15));
      },
    );

    test(
      'fixed-offset card uses the configured offset after the eligible close',
      () {
        final result = CreditCardFirstDueDatePolicy.defaultFirstDueDate(
          referenceDate: DateTime(2026, 10, 25),
          statementDay: 15,
          paymentDueDay: null,
          dueDateCalculationMethod: CreditCardDueDatePolicy.fixedOffsetDays,
          dueDaysAfterStatement: 25,
          weekendHolidayPolicy: CreditCardDueDatePolicy.noAdjustment,
        );

        expect(result, DateTime(2026, 12, 10));
      },
    );
  });
}
