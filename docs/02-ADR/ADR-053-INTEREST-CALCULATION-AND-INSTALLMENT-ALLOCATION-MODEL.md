# ADR-053 — Interest Calculation and Installment Allocation Model

**Status:** Accepted
**Date:** 2026-09-27
**Related:** ADR-052, ADR-054, ADR-055, ADR-069, ADR-070

## Decision

Financing interest and amortization are calculated by pure domain calculators. The calculators produce expected contractual installment components and do not mutate financial truth.

### Rate model

The MVP rate model explicitly identifies:

- `ratePercent` — exact decimal percentage input.
- `rateType` — fixed in the MVP.
- `ratePeriod` — annual in the MVP.
- `periodsPerYear` — contractual periodicity used to derive the periodic rate.
- rounding scale and rounding mode.
- optional effective dates for future rate-policy expansion.

The calculation path is exact-decimal/rational arithmetic. Binary floating-point values are not used as the source of financial calculations.

### Interest

For a fixed annual rate:

`periodicRate = annualRate / periodsPerYear`

`periodInterest = openingPrincipal × periodicRate`

Interest is rounded only at the defined monetary rounding boundary.

### Amortization

The MVP uses a fixed-rate level-payment amortization model. Each scheduled installment contains:

- opening principal
- interest component
- principal component
- payment amount
- closing principal

The final installment reconciles any accumulated rounding difference so that closing principal is exactly zero.

### Invariants

- Calculators are pure and deterministic.
- No Account, Transaction, Ledger, Balance, Statement, or Financial Engine mutation occurs.
- Calculated interest is not equivalent to paid interest.
- Future calculated interest is contractual schedule state, not an immediate financial liability.
- Principal is the canonical amortizing contractual principal from ADR-052.
- Installment amount is the composition of principal + interest + applicable fees.
- Rounding policy is explicit and deterministic.

## Implementation boundary

The current implementation introduces:

- `FinancingRateModel`
- `FinancingInterestCalculator`
- `FinancingAmortizationCalculator`
- immutable `FinancingAmortizationRow` calculation results

Persistence into `FinancingInstallment` and deterministic due-date generation remain separate steps and are not implicitly performed by these calculators.
