/// Explicit financing rate terms used by ADR-053.
///
/// The model is configuration/contractual input only. It does not mutate
/// financial truth or calculate balances by itself.
enum FinancingRateType { fixed }

enum FinancingRatePeriod { annual }

enum FinancingRoundingMode { halfUp, down, up }

class FinancingRateModel {
  final String ratePercent;
  final FinancingRateType rateType;
  final FinancingRatePeriod ratePeriod;
  final int periodsPerYear;
  final int roundingScale;
  final FinancingRoundingMode roundingMode;
  final DateTime? effectiveFrom;
  final DateTime? effectiveTo;

  const FinancingRateModel({
    required this.ratePercent,
    required this.rateType,
    required this.ratePeriod,
    required this.periodsPerYear,
    required this.roundingScale,
    required this.roundingMode,
    this.effectiveFrom,
    this.effectiveTo,
  })  : assert(periodsPerYear > 0),
        assert(roundingScale >= 0);
}
