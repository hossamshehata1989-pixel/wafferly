import '../../core/money/money.dart';
import 'financing_rate_model.dart';

/// One calculated installment obligation.
///
/// This is a pure calculation result. It is not persisted and it does not
/// mutate Accounts, Transactions, Ledger, Statements, or Financial Engine
/// state.
class FinancingAmortizationRow {
  final int sequence;
  final Money openingPrincipal;
  final Money interest;
  final Money principal;
  final Money payment;
  final Money closingPrincipal;

  const FinancingAmortizationRow({
    required this.sequence,
    required this.openingPrincipal,
    required this.interest,
    required this.principal,
    required this.payment,
    required this.closingPrincipal,
  });
}

/// Pure fixed-rate interest calculator defined by ADR-053.
class FinancingInterestCalculator {
  const FinancingInterestCalculator();

  Money calculatePeriodicInterest({
    required Money openingPrincipal,
    required FinancingRateModel rate,
  }) {
    if (openingPrincipal.isNegative) {
      throw ArgumentError.value(
        openingPrincipal,
        'openingPrincipal',
        'Principal cannot be negative.',
      );
    }
    if (rate.rateType != FinancingRateType.fixed) {
      throw UnsupportedError('Only fixed rates are implemented in MVP.');
    }
    if (rate.ratePeriod != FinancingRatePeriod.annual) {
      throw UnsupportedError('Only annual rate input is implemented in MVP.');
    }

    final annualRate = _Fraction.fromDecimalString(rate.ratePercent) /
        _Fraction.fromInt(100);
    final periodicRate = annualRate / _Fraction.fromInt(rate.periodsPerYear);
    final interest =
        _Fraction.fromMoney(openingPrincipal) * periodicRate;
    return interest.toMoney(rate.roundingScale, rate.roundingMode);
  }
}

/// Pure fixed-rate amortization schedule calculator defined by ADR-053.
class FinancingAmortizationCalculator {
  final FinancingInterestCalculator interestCalculator;

  const FinancingAmortizationCalculator({
    this.interestCalculator = const FinancingInterestCalculator(),
  });

  List<FinancingAmortizationRow> calculate({
    required Money principal,
    required int installmentCount,
    required FinancingRateModel rate,
  }) {
    if (!principal.isPositive) {
      throw ArgumentError.value(
        principal,
        'principal',
        'Principal must be greater than zero.',
      );
    }
    if (installmentCount <= 0) {
      throw ArgumentError.value(
        installmentCount,
        'installmentCount',
        'Installment count must be greater than zero.',
      );
    }
    if (rate.rateType != FinancingRateType.fixed) {
      throw UnsupportedError('Only fixed rates are implemented in MVP.');
    }
    if (rate.ratePeriod != FinancingRatePeriod.annual) {
      throw UnsupportedError('Only annual rate input is implemented in MVP.');
    }

    final periodicRate = _periodicRate(rate);
    final payment = _levelPayment(
      principal: principal,
      periodicRate: periodicRate,
      installmentCount: installmentCount,
      scale: rate.roundingScale,
      mode: rate.roundingMode,
    );

    var opening = principal;
    final rows = <FinancingAmortizationRow>[];

    for (var sequence = 1; sequence <= installmentCount; sequence++) {
      final interest = interestCalculator.calculatePeriodicInterest(
        openingPrincipal: opening,
        rate: rate,
      );

      final isFinal = sequence == installmentCount;
      final principalComponent = isFinal
          ? opening
          : payment - interest;

      if (principalComponent.isNegative) {
        throw StateError(
          'Calculated payment does not amortize the principal.',
        );
      }

      final actualPayment = isFinal
          ? principalComponent + interest
          : payment;
      final closing = opening - principalComponent;

      rows.add(
        FinancingAmortizationRow(
          sequence: sequence,
          openingPrincipal: opening,
          interest: interest,
          principal: principalComponent,
          payment: actualPayment,
          closingPrincipal: closing.isZero ? Money.zero : closing,
        ),
      );

      opening = closing.isZero ? Money.zero : closing;
    }

    if (!opening.isZero) {
      throw StateError('Amortization schedule did not reconcile to zero.');
    }

    return List.unmodifiable(rows);
  }

  _Fraction _periodicRate(FinancingRateModel rate) {
    final annualRate = _Fraction.fromDecimalString(rate.ratePercent) /
        _Fraction.fromInt(100);
    return annualRate / _Fraction.fromInt(rate.periodsPerYear);
  }

  Money _levelPayment({
    required Money principal,
    required _Fraction periodicRate,
    required int installmentCount,
    required int scale,
    required FinancingRoundingMode mode,
  }) {
    if (periodicRate.isZero) {
      return (_Fraction.fromMoney(principal) /
              _Fraction.fromInt(installmentCount))
          .toMoney(scale, mode);
    }

    final onePlusRate = _Fraction.one + periodicRate;
    var discount = _Fraction.one;
    var annuityFactor = _Fraction.zero;

    for (var i = 1; i <= installmentCount; i++) {
      discount = discount / onePlusRate;
      annuityFactor += discount;
    }

    return (_Fraction.fromMoney(principal) / annuityFactor)
        .toMoney(scale, mode);
  }
}

/// Small exact rational helper used to keep financing calculations free from
/// binary floating-point arithmetic. It is intentionally private to the pure
/// financing calculator.
class _Fraction {
  final BigInt numerator;
  final BigInt denominator;

  _Fraction._(this.numerator, this.denominator)
      : assert(denominator != BigInt.zero);

  factory _Fraction(BigInt numerator, BigInt denominator) {
    if (denominator == BigInt.zero) {
      throw ArgumentError('Denominator cannot be zero.');
    }
    if (denominator.isNegative) {
      numerator = -numerator;
      denominator = -denominator;
    }
    final divisor = _gcd(numerator.abs(), denominator);
    return _Fraction._(numerator ~/ divisor, denominator ~/ divisor);
  }

  static final zero = _Fraction(BigInt.zero, BigInt.one);
  static final one = _Fraction(BigInt.one, BigInt.one);

  factory _Fraction.fromInt(int value) =>
      _Fraction(BigInt.from(value), BigInt.one);

  factory _Fraction.fromMoney(Money value) =>
      _Fraction.fromDecimalString(value.toString());

  factory _Fraction.fromDecimalString(String value) {
    final normalized = value.trim();
    final match = RegExp(r'^([+-]?)(\d+)(?:\.(\d+))?$').firstMatch(normalized);
    if (match == null) {
      throw FormatException('Invalid decimal: $value');
    }
    return _fromMatch(match);
  }

  static _Fraction _fromMatch(RegExpMatch match) {
    final sign = match.group(1) == '-' ? -BigInt.one : BigInt.one;
    final whole = BigInt.parse(match.group(2)!);
    final fraction = match.group(3) ?? '';
    final scale = fraction.length;
    final denominator = BigInt.from(10).pow(scale);
    final numerator = whole * denominator +
        (fraction.isEmpty ? BigInt.zero : BigInt.parse(fraction));
    return _Fraction(sign * numerator, denominator);
  }

  bool get isZero => numerator == BigInt.zero;

  _Fraction operator +( _Fraction other) => _Fraction(
        numerator * other.denominator + other.numerator * denominator,
        denominator * other.denominator,
      );

  _Fraction operator -( _Fraction other) => _Fraction(
        numerator * other.denominator - other.numerator * denominator,
        denominator * other.denominator,
      );

  _Fraction operator *( _Fraction other) =>
      _Fraction(numerator * other.numerator, denominator * other.denominator);

  _Fraction operator /( _Fraction other) {
    if (other.numerator == BigInt.zero) {
      throw ArgumentError('Cannot divide by zero.');
    }
    return _Fraction(
      numerator * other.denominator,
      denominator * other.numerator,
    );
  }

  Money toMoney(int scale, FinancingRoundingMode mode) {
    final factor = BigInt.from(10).pow(scale);
    final scaledNumerator = numerator * factor;
    var quotient = scaledNumerator ~/ denominator;
    final remainder = scaledNumerator.remainder(denominator).abs();

    if (remainder != BigInt.zero) {
      final shouldRound = switch (mode) {
        FinancingRoundingMode.down => false,
        FinancingRoundingMode.up => true,
        FinancingRoundingMode.halfUp =>
          remainder * BigInt.from(2) >= denominator.abs(),
      };
      if (shouldRound) {
        quotient += numerator.isNegative ? -BigInt.one : BigInt.one;
      }
    }

    final negative = quotient.isNegative;
    final absolute = quotient.abs().toString().padLeft(scale + 1, '0');
    if (scale == 0) {
      return Money.parse('${negative ? '-' : ''}$absolute');
    }
    final split = absolute.length - scale;
    return Money.parse(
      '${negative ? '-' : ''}${absolute.substring(0, split)}.${absolute.substring(split)}',
    );
  }

  static BigInt _gcd(BigInt a, BigInt b) {
    while (b != BigInt.zero) {
      final remainder = a.remainder(b);
      a = b;
      b = remainder;
    }
    return a == BigInt.zero ? BigInt.one : a;
  }
}
