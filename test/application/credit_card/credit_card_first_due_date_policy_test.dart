import 'package:flutter_test/flutter_test.dart';
import 'package:wafferly/application/credit_card/credit_card_first_due_date_policy.dart';

void main() {
  group('CreditCardFirstDueDatePolicy', () {
    test('defaults the first installment to the next calendar month', () {
      final result = CreditCardFirstDueDatePolicy.defaultFirstDueDate(
        referenceDate: DateTime(2026, 9, 9),
        paymentDueDay: 15,
      );

      expect(result, DateTime(2026, 10, 15));
    });

    test('clamps the due day to the target month length', () {
      final result = CreditCardFirstDueDatePolicy.defaultFirstDueDate(
        referenceDate: DateTime(2026, 1, 31),
        paymentDueDay: 31,
      );

      expect(result, DateTime(2026, 2, 28));
    });

    test('rolls into the next year deterministically', () {
      final result = CreditCardFirstDueDatePolicy.defaultFirstDueDate(
        referenceDate: DateTime(2026, 12, 24),
        paymentDueDay: 15,
      );

      expect(result, DateTime(2027, 1, 15));
    });


    test('monthly installments preserve the original due-day anchor', () {
      final first = DateTime(2026, 1, 31);
      final dates = List<DateTime>.generate(
        4,
        (index) => CreditCardFirstDueDatePolicy.installmentDueDate(
          firstDueDate: first,
          installmentIndex: index,
        ),
      );

      expect(dates, [
        DateTime(2026, 1, 31),
        DateTime(2026, 2, 28),
        DateTime(2026, 3, 31),
        DateTime(2026, 4, 30),
      ]);
    });

    test('monthly schedule preserves a leap-year end-of-month anchor', () {
      final first = DateTime(2024, 1, 31);
      expect(
        CreditCardFirstDueDatePolicy.installmentDueDate(
          firstDueDate: first,
          installmentIndex: 1,
        ),
        DateTime(2024, 2, 29),
      );
      expect(
        CreditCardFirstDueDatePolicy.installmentDueDate(
          firstDueDate: first,
          installmentIndex: 2,
        ),
        DateTime(2024, 3, 31),
      );
    });

    test('uses the reference day when no due day is configured', () {
      final result = CreditCardFirstDueDatePolicy.defaultFirstDueDate(
        referenceDate: DateTime(2026, 9, 30),
        paymentDueDay: null,
      );

      expect(result, DateTime(2026, 10, 30));
    });
  });
}
