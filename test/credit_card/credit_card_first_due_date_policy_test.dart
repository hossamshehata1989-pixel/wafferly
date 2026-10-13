import 'package:flutter_test/flutter_test.dart';
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
  });
}
