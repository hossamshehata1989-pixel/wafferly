import 'package:flutter_test/flutter_test.dart';
import 'package:wafferly/application/credit_card/credit_card_cycle_resolver.dart';

void main() {
  group('CreditCardCycleResolver', () {
    test('purchase on or before close day belongs to that close', () {
      expect(
        CreditCardCycleResolver.closeDateFor(DateTime(2026, 10, 15), 15),
        DateTime(2026, 10, 15),
      );
      expect(
        CreditCardCycleResolver.closeDateFor(DateTime(2026, 10, 10), 15),
        DateTime(2026, 10, 15),
      );
    });

    test('purchase after close day belongs to next statement close', () {
      expect(
        CreditCardCycleResolver.closeDateFor(DateTime(2026, 10, 16), 15),
        DateTime(2026, 11, 15),
      );
    });

    test('payment due date is in the month after statement close', () {
      expect(
        CreditCardCycleResolver.dueDateFor(DateTime(2026, 12, 31), 25),
        DateTime(2027, 1, 25),
      );
    });

    test('clamps cycle dates for short months', () {
      expect(
        CreditCardCycleResolver.closeDateFor(DateTime(2026, 2, 1), 31),
        DateTime(2026, 2, 28),
      );
      expect(
        CreditCardCycleResolver.closeDateFor(DateTime(2024, 2, 1), 31),
        DateTime(2024, 2, 29),
      );
    });

    test('reporting month follows the expected payment month', () {
      expect(
        CreditCardCycleResolver.cycleMonthFor(
          DateTime(2026, 10, 10),
          15,
          25,
        ),
        DateTime(2026, 11, 1),
      );
      expect(
        CreditCardCycleResolver.cycleMonthFor(
          DateTime(2026, 10, 16),
          15,
          25,
        ),
        DateTime(2026, 12, 1),
      );
    });
  });
}
