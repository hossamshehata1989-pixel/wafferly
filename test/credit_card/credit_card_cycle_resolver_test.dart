import 'package:flutter_test/flutter_test.dart';
import 'package:wafferly/application/credit_card/credit_card_cycle_resolver.dart';

void main() {
  group('CreditCardCycleResolver', () {
    test('payment day after close stays in following month', () {
      final close = CreditCardCycleResolver.closeDateFor(DateTime(2026, 10, 12), 9);
      expect(close, DateTime(2026, 11, 9));
      expect(CreditCardCycleResolver.dueDateFor(close, 25), DateTime(2026, 12, 25));
    });

    test('purchase before close uses that close then following-month due date', () {
      final close = CreditCardCycleResolver.closeDateFor(DateTime(2026, 10, 12), 14);
      expect(close, DateTime(2026, 10, 14));
      expect(CreditCardCycleResolver.dueDateFor(close, 15), DateTime(2026, 11, 15));
    });

    test('close day after purchase date rolls to next month', () {
      expect(CreditCardCycleResolver.closeDateFor(DateTime(2026, 10, 26), 25), DateTime(2026, 11, 25));
      expect(CreditCardCycleResolver.dueDateFor(DateTime(2026, 11, 25), 10), DateTime(2026, 12, 10));
    });

    test('clamps close and due dates at end of month and leap year', () {
      expect(CreditCardCycleResolver.closeDateFor(DateTime(2026, 2, 27), 31), DateTime(2026, 2, 28));
      expect(CreditCardCycleResolver.closeDateFor(DateTime(2024, 2, 28), 29), DateTime(2024, 2, 29));
      expect(CreditCardCycleResolver.dueDateFor(DateTime(2026, 1, 31), 31), DateTime(2026, 2, 28));
    });

    test('due date rolls across year boundary', () {
      expect(CreditCardCycleResolver.dueDateFor(DateTime(2026, 12, 31), 15), DateTime(2027, 1, 15));
    });
  });
}
