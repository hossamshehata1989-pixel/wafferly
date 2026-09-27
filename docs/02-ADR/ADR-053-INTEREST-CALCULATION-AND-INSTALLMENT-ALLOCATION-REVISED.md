# ADR-053 — Interest Calculation and Installment Allocation Model

**Status:** Proposed → Implementation  
**Date:** 2026-09-27  
**Related:** ADR-032 (Debt Domain Architecture), ADR-035 (Credit Card Domain), ADR-050 (Credit Card Statement Lifecycle & Due-Date Generation), ADR-051 (Credit Card Payment / Settlement Operation), ADR-052 (Installment / Financing Contract Model), ADR-069 (Credit Card Statement ↔ Installment Relationship)

## 1. Context

ADR-052 establishes the Installment / Financing Contract as the domain model for financing terms and expected repayment.

Interest and financing cost must be represented separately from the principal obligation so that the system can explain how each installment is composed.

The model must preserve the existing separation:

```text
Financing Contract
    ↓
Interest / Financing Policy
    ↓
Installment Schedule
    ↓
Expected Principal + Interest
    ↓
Actual Payment
    ↓
Financial Operation Engine
    ↓
Financial Truth
```

The interest model must not create an independent balance ledger.

## 2. Decision

Introduce an explicit **Interest / Financing Calculation Model** associated with an Installment Financing Contract.

The model determines:

- the applicable financing rate;
- the calculation basis;
- the calculation period;
- the interest amount attributable to each installment;
- the principal component of each installment;
- the total scheduled repayment amount.

The calculation result is deterministic for a given contract, policy, dates, and financial inputs.

## 3. Separation of Principal and Interest

Every scheduled installment must be conceptually decomposable into:

```text
Installment Amount
    =
Principal Component
    +
Interest Component
    +
Applicable Financing Fees
```

Where no fee applies:

```text
Installment Amount
    =
Principal Component
    +
Interest Component
```

Interest must not be hidden inside an opaque installment amount when the contract requires an auditable principal/interest breakdown.

## 4. Interest Rate Representation

The financing contract must explicitly identify the rate used by its interest policy.

The implementation must not infer a rate from the final installment amount.

The rate model must identify, as applicable:

- rate value;
- rate type;
- calculation period;
- effective dates;
- rounding policy.

The first implementation must support a deterministic fixed-rate contract.

Variable or market-linked rates require a separate policy and must not be implicitly introduced into this ADR.

## 5. Calculation Method

The calculation method must be explicit.

The first implementation should support an amortizing financing schedule where interest is calculated for each scheduled period from the defined outstanding principal basis.

Conceptually:

```text
Period Interest
    =
Interest Basis
    ×
Periodic Rate
```

Then:

```text
Principal Component
    =
Scheduled Installment
    -
Interest Component
```

The exact periodic-rate derivation from the contract's annual/nominal/effective rate must be an explicit contract field/policy and must not be guessed from UI values.

## 6. Amortization Schedule

For an amortizing plan, the system generates an ordered schedule:

```text
Installment 1
    ├── due date
    ├── opening principal
    ├── interest
    ├── principal
    └── closing principal

Installment 2
    ├── due date
    ├── opening principal
    ├── interest
    ├── principal
    └── closing principal

...
```

The schedule must satisfy:

```text
Closing Principal
    =
Opening Principal
    -
Principal Component
```

For the final installment, rounding reconciliation must ensure that the schedule closes the financed principal exactly according to the contract.

## 7. Rounding Policy

Interest and installment calculations must use deterministic monetary rounding.

All domain monetary values remain `Money`-native.

Rounding must occur according to one explicit policy rather than being delegated implicitly to floating-point arithmetic.

The implementation must define:

- calculation precision;
- display/payment precision;
- rounding mode;
- when rounding occurs;
- final-installment reconciliation.

A rounding difference must never cause the financing schedule to leave an unexplained residual principal.

## 8. Final Installment Reconciliation

Because periodic interest may require monetary rounding, the final installment may need a controlled reconciliation.

The final installment must be calculated so that:

```text
Total Principal Components
    =
Contract Principal
```

and:

```text
Closing Principal
    =
0
```

subject to the contract's defined rounding policy.

The reconciliation must be deterministic and must not mutate earlier immutable installment history.

## 9. Interest Allocation to Installments

Interest belongs to the scheduled financing period for which it is calculated.

Therefore each installment record should expose, directly or through a deterministic projection:

```text
principalComponent
interestComponent
totalInstallment
```

The schedule must preserve the relationship:

```text
totalInstallment
    =
principalComponent
    +
interestComponent
    +
applicableFees
```

Interest must not be allocated arbitrarily merely to make installment totals match.

## 10. Contract vs Financial Truth

The calculated amortization schedule is an expected financing schedule.

It is not itself a second financial ledger.

```text
Installment Schedule
    = expected repayment composition

Financial Transactions
    = actual money movement
```

Actual payment continues through `CreditCardPaymentOperation` and the Financial Operation Engine.

The schedule must not directly mutate:

```text
Account
Transaction
Ledger
Balance
```

## 11. Accrual vs Payment

Interest being calculated for an installment does not automatically mean that the interest has been paid.

The architecture distinguishes:

```text
Calculated Interest
    ≠
Paid Interest
```

A scheduled installment may therefore contain an expected interest component before the corresponding payment occurs.

Actual payment remains an independent financial event.

## 12. Early Payment and Partial Payment

The interest model must not silently assume that every payment exactly matches the scheduled installment.

The schedule represents the contractual expectation.

Actual payment may differ.

Policies for:

- partial payment;
- early payment;
- prepayment;
- interest rebate;
- early-settlement fee;

are outside the base calculation model unless explicitly configured.

Those policies must define how future interest is treated rather than modifying historical calculations implicitly.

## 13. Interest and Statement Lifecycle

For Credit Cards, interest associated with a financing plan may interact with statement periods.

The statement lifecycle defined by ADR-050 remains separate.

The system must distinguish:

```text
Installment Schedule Interest
        ≠
Statement Balance
        ≠
Actual Payment
```

Statement inclusion for installment principal, interest, and applicable financing fees is defined by ADR-069.

This ADR defines the calculation and installment allocation model; ADR-050 and ADR-069 define statement-period presentation and inclusion semantics.

## 14. Idempotency and Determinism

Generating the same financing schedule from the same contract and policy must produce the same result.

Repeated calculation must not create duplicate financial transactions.

Schedule generation may be safely recomputed as a projection as long as the contract inputs and policy are unchanged.

If a generated schedule is persisted, its identities must be stable and duplicate generation must be prevented.

## 15. Corrections and Contract Changes

Historical financial transactions must remain immutable.

A later correction to a financial transaction must use the existing correction/invalidation architecture.

A change to future financing terms must not silently rewrite historical financial effects.

The implementation must distinguish:

```text
Historical Financial Truth
        ≠
Future Financing Projection
```

A contract amendment, refinancing, or restructuring requires an explicit domain operation.

## 16. Money Boundary

All interest, principal, installment, and fee amounts inside Financial Domain / Planning code must use `Money`.

No calculation may convert monetary values to `double` merely to perform arithmetic.

Conversions to legacy `double` are permitted only at already-approved compatibility/persistence boundaries defined by the Money ADRs.

## 17. Non-Goals

This ADR does not define:

- APR disclosure rules;
- variable/market-linked interest;
- late-payment interest;
- penalty fees;
- grace periods;
- minimum payment;
- Credit Card statement closing;
- payment allocation order;
- early-settlement economics;
- refinancing/restructuring;
- tax treatment;
- currency conversion;
- legal/regulatory interest disclosure requirements.

These require separate domain/policy decisions where needed.

## 18. Required Tests

The implementation gate must cover:

### Zero-interest financing

```text
Principal = 12,000
Interest = 0

→ total principal allocation = 12,000
→ total interest = 0
```

### Fixed-rate amortization

The generated schedule must have deterministic principal and interest components for every installment.

### Principal reconciliation

```text
sum(principal components)
    =
contract principal
```

### Installment reconciliation

```text
installment
    =
principal
    +
interest
    +
fees
```

where applicable.

### Final-installment rounding

The final installment must close the remaining principal without unexplained residual.

### EOM schedule

Monthly due dates must follow ADR-046.

### Deterministic recalculation

Same contract + same policy + same dates:

```text
→ identical schedule
```

### No financial mutation

Schedule calculation must not mutate Account, Transaction, Ledger, or Balance.

### Partial/early payment separation

Actual payment must not silently rewrite the contractual schedule.

### Money boundary

No unapproved `double` monetary fields or arithmetic inside the Financial Domain / Planning calculation path.

## 19. Architectural Invariants

The following are mandatory:

```text
Interest Calculation
    ≠
Financial Transaction
```

```text
Installment Schedule
    ≠
Financial Balance
```

```text
Calculated Interest
    ≠
Paid Interest
```

```text
Contract Projection
    ≠
Historical Financial Truth
```

And:

```text
Actual Financial Effect
        ↓
FinancialOperationEngine
```

The interest calculation component must never become a financial writer.

## 20. Consequence

This model provides an auditable and deterministic separation between:

```text
Financing Terms
        ↓
Interest Calculation
        ↓
Principal / Interest Allocation
        ↓
Expected Installments
        ↓
Actual Payment
        ↓
Financial Truth
```

It allows future policies for early settlement, variable rates, late interest, restructuring, and payment allocation without corrupting the core Account/Transaction source-of-truth architecture.

## 21. Implementation Boundary

Implementation should begin with:

1. an explicit interest calculation policy/model;
2. a deterministic amortization schedule calculator;
3. principal/interest `Money` components;
4. explicit rounding and final-installment reconciliation;
5. integration with `InstallmentFinancingContract`;
6. projection into existing Commitment / ScheduleOccurrence infrastructure;
7. tests proving no financial persistence mutation during calculation.

No independent interest balance or financing ledger should be introduced.
