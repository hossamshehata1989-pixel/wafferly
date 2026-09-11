import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wafferly/core/money/money.dart';

void main() {
  group('Money', () {
    test('parses exact decimal values', () {
  final money = Money.parse('125.50');

  expect(money, Money.parse('125.50'));
  expect(money.decimal, Decimal.parse('125.50'));
});

    test('does not suffer from floating-point addition errors', () {
      final first = Money.parse('0.1');
      final second = Money.parse('0.2');

      final result = first + second;

      expect(result, Money.parse('0.3'));
      expect(result.toString(), '0.3');
    });

    test('supports subtraction exactly', () {
      final result = Money.parse('100.10') - Money.parse('0.20');

      expect(result, Money.parse('99.90'));
    });

    test('supports negative values', () {
      final money = Money.parse('-25.75');

      expect(money.isNegative, isTrue);
      expect(money.isPositive, isFalse);
      expect(money.isZero, isFalse);
    });

    test('supports zero', () {
      expect(Money.zero.isZero, isTrue);
      expect(Money.parse('0'), Money.zero);
      expect(Money.parse('0.00'), Money.zero);
    });

    test('supports comparisons', () {
      final low = Money.parse('10.00');
      final high = Money.parse('20.00');

      expect(low < high, isTrue);
      expect(low <= high, isTrue);
      expect(high > low, isTrue);
      expect(high >= low, isTrue);
      expect(low.compareTo(high), lessThan(0));
      expect(high.compareTo(low), greaterThan(0));
    });

    test('supports absolute value', () {
      expect(Money.parse('-50.25').abs(), Money.parse('50.25'));
      expect(Money.parse('50.25').abs(), Money.parse('50.25'));
    });

    test('supports unary negation', () {
      expect(-Money.parse('50.25'), Money.parse('-50.25'));
      expect(-Money.parse('-50.25'), Money.parse('50.25'));
    });

    test('rejects empty values', () {
      expect(
        () => Money.parse(''),
        throwsA(isA<FormatException>()),
      );

      expect(
        () => Money.parse('   '),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects invalid decimal values', () {
      expect(
        () => Money.parse('abc'),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects NaN from legacy double bridge', () {
      expect(
        () => Money.fromDouble(double.nan),
        throwsArgumentError,
      );
    });

    test('rejects infinity from legacy double bridge', () {
      expect(
        () => Money.fromDouble(double.infinity),
        throwsArgumentError,
      );

      expect(
        () => Money.fromDouble(double.negativeInfinity),
        throwsArgumentError,
      );
    });

    test('legacy double bridge can represent ordinary values', () {
      expect(
        Money.fromDouble(125.50),
        Money.parse('125.5'),
      );
    });

    test('equality is based on monetary value', () {
      expect(
        Money.parse('100'),
        Money.parse('100.00'),
      );

      expect(
        Money.parse('100'),
        isNot(Money.parse('100.01')),
      );
    });

    test('can explicitly convert to double for legacy/UI boundaries', () {
      final money = Money.parse('125.50');

      expect(money.toDouble(), 125.5);
    });
  });
}