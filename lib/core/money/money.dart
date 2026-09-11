import 'package:decimal/decimal.dart';

/// Exact monetary value.
///
/// Money deliberately does not expose a `Money(double)` constructor.
/// Financial values must enter the domain through exact representations
/// such as [parse] or [fromDecimal].
///
/// Currency is intentionally NOT part of Money. Currency is a separate
/// domain attribute and must be carried by the surrounding financial model.
final class Money implements Comparable<Money> {
  final Decimal _amount;

  const Money._(this._amount);

  /// Creates Money from an exact decimal value.
  factory Money.fromDecimal(Decimal amount) {
    return Money._(amount);
  }

  /// Creates Money from a decimal string.
  ///
  /// Examples:
  ///   Money.parse('100')
  ///   Money.parse('100.50')
  ///   Money.parse('-25.75')
  factory Money.parse(String value) {
    final normalized = value.trim();

    if (normalized.isEmpty) {
      throw const FormatException('Money value cannot be empty.');
    }

    try {
      return Money._(Decimal.parse(normalized));
    } on FormatException {
      rethrow;
    } catch (_) {
      throw FormatException('Invalid money value: $value');
    }
  }

  /// Zero monetary value.
  static final Money zero = Money._(Decimal.zero);

  /// Legacy bridge for existing double-based code.
  ///
  /// This method exists only during the migration from double to Money.
  /// New financial/domain code must not use double as its source value.
  ///
  /// The double is converted through its string representation to avoid
  /// passing the binary floating-point representation directly into Decimal.
  factory Money.fromDouble(double value) {
    if (!value.isFinite) {
      throw ArgumentError.value(
        value,
        'value',
        'Money cannot contain NaN or infinity.',
      );
    }

    return Money.parse(value.toString());
  }

  /// Returns the exact Decimal representation.
  Decimal get decimal => _amount;

  /// Returns true when this value is exactly zero.
  bool get isZero => _amount == Decimal.zero;

  /// Returns true when this value is positive.
  bool get isPositive => _amount > Decimal.zero;

  /// Returns true when this value is negative.
  bool get isNegative => _amount < Decimal.zero;

  /// Absolute value.
  Money abs() {
    return Money._(_amount.abs());
  }

  /// Addition.
  Money operator +(Money other) {
    return Money._(_amount + other._amount);
  }

  /// Subtraction.
  Money operator -(Money other) {
    return Money._(_amount - other._amount);
  }

  /// Unary negation.
  Money operator -() {
    return Money._(-_amount);
  }

  /// Comparison operators.
  bool operator <(Money other) {
    return _amount < other._amount;
  }

  bool operator <=(Money other) {
    return _amount <= other._amount;
  }

  bool operator >(Money other) {
    return _amount > other._amount;
  }

  bool operator >=(Money other) {
    return _amount >= other._amount;
  }

  @override
  int compareTo(Money other) {
    return _amount.compareTo(other._amount);
  }

  /// Explicit legacy/UI bridge.
  ///
  /// This must not be used for financial calculations.
  double toDouble() {
    return _amount.toDouble();
  }

  /// Canonical decimal string representation.
  @override
  String toString() {
    return _amount.toString();
  }

  @override
  bool operator ==(Object other) {
    return other is Money && _amount == other._amount;
  }

  @override
  int get hashCode => _amount.hashCode;
}