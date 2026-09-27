import 'package:flutter_test/flutter_test.dart';
import 'package:wafferly/core/money/money.dart';
import 'package:wafferly/financing/domain/financing_amortization.dart';
import 'package:wafferly/financing/domain/financing_rate_model.dart';

void main() {
  const rate = FinancingRateModel(
    ratePercent: '12',
    rateType: FinancingRateType.fixed,
    ratePeriod: FinancingRatePeriod.annual,
    periodsPerYear: 12,
    roundingScale: 2,
    roundingMode: FinancingRoundingMode.halfUp,
  );

  test('calculates monthly interest without floating-point arithmetic', () {
    const calculator = FinancingInterestCalculator();

    final interest = calculator.calculatePeriodicInterest(
      openingPrincipal: Money.parse('10000'),
      rate: rate,
    );

    expect(interest, Money.parse('100'));
  });

  test('zero rate divides principal deterministically', () {
    const calculator = FinancingAmortizationCalculator();
    const zeroRate = FinancingRateModel(
      ratePercent: '0',
      rateType: FinancingRateType.fixed,
      ratePeriod: FinancingRatePeriod.annual,
      periodsPerYear: 12,
      roundingScale: 2,
      roundingMode: FinancingRoundingMode.halfUp,
    );

    final rows = calculator.calculate(
      principal: Money.parse('1000'),
      installmentCount: 3,
      rate: zeroRate,
    );

    expect(rows, hasLength(3));
    expect(rows[0].interest, Money.zero);
    expect(rows[0].principal, Money.parse('333.33'));
    expect(rows[1].principal, Money.parse('333.33'));
    expect(rows[2].principal, Money.parse('333.34'));
    expect(rows.last.closingPrincipal, Money.zero);
  });

  test('fixed-rate schedule reconciles the final installment to zero', () {
    const calculator = FinancingAmortizationCalculator();

    final rows = calculator.calculate(
      principal: Money.parse('1000'),
      installmentCount: 12,
      rate: rate,
    );

    expect(rows, hasLength(12));
    expect(rows.first.openingPrincipal, Money.parse('1000'));
    expect(rows.first.interest, Money.parse('10'));
    expect(rows.first.payment, Money.parse('88.85'));
    expect(rows.last.closingPrincipal, Money.zero);
    expect(
      rows.fold<Money>(Money.zero, (sum, row) => sum + row.principal),
      Money.parse('1000'),
    );
  });

  test('rounding is deterministic for half-up interest', () {
    const calculator = FinancingInterestCalculator();
    const localRate = FinancingRateModel(
      ratePercent: '10',
      rateType: FinancingRateType.fixed,
      ratePeriod: FinancingRatePeriod.annual,
      periodsPerYear: 12,
      roundingScale: 2,
      roundingMode: FinancingRoundingMode.halfUp,
    );

    expect(
      calculator.calculatePeriodicInterest(
        openingPrincipal: Money.parse('100.05'),
        rate: localRate,
      ),
      Money.parse('0.83'),
    );
  });

  test('rejects negative principal', () {
    const calculator = FinancingAmortizationCalculator();

    expect(
      () => calculator.calculate(
        principal: Money.parse('-100'),
        installmentCount: 3,
        rate: rate,
      ),
      throwsArgumentError,
    );
  });
}
