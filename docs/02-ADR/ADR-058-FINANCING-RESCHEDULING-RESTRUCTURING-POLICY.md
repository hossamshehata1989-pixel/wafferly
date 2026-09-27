# ADR-058 — Financing Contract Rescheduling / Restructuring Policy

**Status:** Proposed → Implementation  
**Date:** 2026-09-27  
**Related:** ADR-052 (Installment / Financing Contract Model), ADR-053 (Interest Calculation and Installment Allocation Model), ADR-055 (Multi-Installment Payment Allocation), ADR-056 (Early Settlement / Prepayment Policy), ADR-057 (Late Payment Fee Policy)

## 1. Context

A financing contract may need to change its future repayment schedule after its original schedule has been created.

Examples include:

- changing the number of future installments;
- changing future installment amounts;
- moving future due dates;
- responding to a partial prepayment;
- an explicit restructuring agreement;
- a contract amendment.

Rescheduling must not rewrite historical financial truth.

The architecture must distinguish:

```text
Historical Financial Truth
        ≠
Original Financing Contract Terms
        ≠
Future Restructured Projection
```

A rescheduling operation therefore changes future contractual expectations while preserving the immutable financial history that already occurred.

## 2. Decision

Introduce an explicit **Financing Rescheduling / Restructuring Policy**.

A schedule change must be represented as an explicit contract transition rather than by silently editing previously generated installment history.

The resulting lifecycle is:

```text
Original Contract
      ↓
Restructuring Event
      ↓
New Future Schedule
      ↓
Future Commitments / Occurrences
      ↓
Actual Payments
      ↓
Financial Truth
```

Historical installments remain available for audit and traceability.

## 3. Rescheduling vs Restructuring

The system must distinguish two concepts.

### A. Rescheduling

Rescheduling changes the timing or distribution of future obligations without changing the fundamental financing agreement.

Examples:

```text
Due date shift
Term extension
Term reduction
Future installment redistribution
```

### B. Restructuring

Restructuring changes one or more substantive financing terms.

Examples:

```text
Interest policy change
New financed amount
Fee/penalty treatment change
New repayment structure
Contract amendment
```

The implementation must not classify a substantive contract change as a simple date edit.

## 4. Historical Immutability

A rescheduling operation must never mutate or delete:

- completed payments;
- historical financial transactions;
- historical ledger entries;
- already-settled interest;
- previously assessed fees;
- historical statement records.

If an earlier financial event must be corrected, the existing correction/invalidation architecture must be used.

The new schedule applies only from the defined restructuring boundary forward.

## 5. Restructuring Effective Date

Every rescheduling/restructuring event must have an explicit effective date.

Conceptually:

```text
Historical Period
        │
        │ immutable
        ▼
Restructuring Effective Date
        │
        ▼
New Future Schedule
```

The effective date must be supplied explicitly and must not be inferred from the machine clock.

The event must define which future obligations are affected.

## 6. Eligible Installments

By default, only future or otherwise explicitly eligible unpaid installments may be changed.

Already settled installments are immutable.

Overdue installments require explicit policy handling.

A restructuring operation must not silently rewrite delinquency history or erase previously assessed late fees.

If overdue amounts are rolled into a new financing arrangement, that conversion must be explicit and traceable.

## 7. Existing Payments

Actual payments already recorded remain financial truth.

After restructuring:

```text
Historical Payments
    = unchanged
```

The remaining contractual obligation is calculated from the current effective financing state.

A restructuring operation must not create a fake historical payment merely to make the new schedule balance.

## 8. Principal Recalculation

The new future schedule must start from the explicitly determined remaining principal.

Conceptually:

```text
Original Principal
    -
Principal already settled
    -
Explicit principal adjustments
    =
Remaining Principal
```

The exact adjustment policy must be represented explicitly.

The system must never infer a principal adjustment from UI totals.

## 9. Interest Recalculation

Future interest must be recalculated from the new future schedule and the applicable financing policy.

Historical interest remains unchanged.

Conceptually:

```text
Historical Interest
    = immutable

Future Interest
    = recalculated according to new terms
```

If the restructuring changes the interest rate or calculation method, that change must be explicit in the restructuring event.

The system must not retroactively recalculate already-settled interest.

## 10. Term Extension

A restructuring may extend the remaining term.

The system must:

1. preserve the remaining principal;
2. preserve settled history;
3. generate new future due dates;
4. calculate future interest according to the applicable rate/policy;
5. generate the resulting installment schedule.

The new schedule must close the remaining principal exactly according to ADR-053 rounding rules.

## 11. Term Reduction

A restructuring may reduce the remaining term.

The system must:

1. preserve historical financial truth;
2. calculate the remaining principal;
3. generate fewer future installments;
4. recalculate future interest;
5. reconcile the final installment.

Term reduction must not be implemented as deletion of historical installments.

## 12. Installment Amount Change

A restructuring may keep the remaining term while changing future installment amounts.

The new schedule must explicitly identify:

```text
remaining term
new installment calculation
future interest
principal allocation
```

The schedule must satisfy:

```text
Sum of future principal components
    =
remaining principal
```

and:

```text
Final future closing principal
    =
0
```

subject to the approved rounding policy.

## 13. Due-Date Changes

A restructuring may move future due dates.

The new dates must use the existing scheduled-money date contract.

Monthly recurrence must continue to follow ADR-046:

```text
original anchor
    ↓
target month
    ↓
explicit valid day
    ↓
clamp when required
```

No due date may depend on implicit Dart `DateTime` overflow.

## 14. Statement Interaction

Future statement projections may change because future installment dates or amounts change.

Historical closed statements must not be rewritten.

Statement lifecycle remains governed by ADR-050.

A restructuring event must therefore distinguish:

```text
Historical Statement
    = immutable

Future Statement Projection
    = may change
```

## 15. Late Fees and Delinquency

Rescheduling does not automatically forgive late fees.

Existing assessed late fees remain governed by ADR-057 unless the restructuring agreement explicitly changes them.

If a restructuring explicitly waives, replaces, or capitalizes a late fee, that action must be represented as an explicit contract/financial policy and remain traceable.

No late fee may be silently deleted.

## 16. Partial Prepayment Relationship

ADR-056 already defines that a partial prepayment requires an explicit future restructuring mode.

This ADR provides the resulting schedule-transition contract.

Supported base outcomes are:

### Term Reduction

```text
Future installment target
    ≈ preserved

Remaining term
    ↓
shorter
```

### Installment Reduction

```text
Remaining term
    = preserved

Future installment amount
    ↓
recalculated
```

The restructuring event must explicitly identify the selected mode.

## 17. Contract Versioning

A restructuring should create a new effective contract/schedule version rather than silently replacing the historical version.

Conceptually:

```text
Contract Version 1
        ↓
Restructuring Event
        ↓
Contract Version 2
```

The previous version remains available for historical/audit purposes.

Only one version should be authoritative for future obligations at a given effective date.

## 18. Stable Identity

A restructuring event must have a stable identity.

Each resulting schedule/commitment/occurrence must also retain stable identity.

Repeated processing of the same restructuring event must not create:

- duplicate contract versions;
- duplicate installments;
- duplicate schedule occurrences;
- duplicate financial transactions.

## 19. Future Schedule Replacement

When a new schedule replaces future obligations, the implementation must explicitly mark affected future schedule items as:

```text
cancelled
superseded
replaced
```

or an equivalent domain state.

They must not simply disappear from persistence.

The replacement schedule must carry a reference to the restructuring event.

## 20. Financial Truth Boundary

Rescheduling is primarily a contract/planning transition.

It must not directly mutate:

```text
Account
Transaction
Ledger
Balance
Hive
```

If the restructuring produces an actual financial effect—such as a fee, adjustment, capitalization, or settlement—that financial effect must pass through the Financial Operation Engine.

Conceptually:

```text
Restructuring Policy
        ↓
New Contract / Schedule Projection
        │
        ├── no financial effect
        │
        └── explicit financial adjustment
                    ↓
          FinancialOperationEngine
```

## 21. Atomicity and Recovery

If a restructuring includes both financial mutation and schedule transition, it must use the existing financial idempotency and scheduled-execution recovery boundaries.

A failure after financial success must not cause the financial effect to be applied twice.

A failure during schedule replacement must leave sufficient durable state to complete the transition safely.

## 22. Money Semantics

All principal, interest, fees, installment amounts, and adjustments inside Domain/Planning remain `Money`-native.

No restructuring calculation may use `double` for financial arithmetic.

Rounding follows ADR-053 and the existing Money boundary contracts.

## 23. Required Tests

### Historical immutability

Restructuring must not modify or delete historical transactions, payments, interest, fees, or closed statements.

### Term extension

Future schedule is extended while remaining principal is preserved.

### Term reduction

Future schedule is shortened and final principal reconciles to zero.

### Installment reduction

Same remaining term with recalculated future installment amounts.

### Due-date change

Future due dates follow the explicit scheduling contract.

### EOM behavior

Rescheduled monthly dates follow ADR-046.

### Interest recalculation

Historical interest remains unchanged while future interest follows the new terms.

### Late-fee preservation

Existing assessed late fees are not silently removed.

### Explicit fee waiver/capitalization

Any change to an assessed fee is represented by an explicit policy/event.

### Partial-prepayment integration

ADR-056 term-reduction and installment-reduction modes produce the correct future schedules.

### Contract versioning

A restructuring creates one new effective version and preserves the prior version.

### Idempotency

Retrying the same restructuring event creates no duplicate version, schedule, occurrence, or financial effect.

### No direct financial mutation

Pure rescheduling does not write Account, Transaction, Ledger, Balance, or Hive.

### Atomic recovery

If an explicit financial adjustment succeeds before schedule transition completion, retry must not create a second financial adjustment.

## 24. Architectural Invariants

The following are mandatory:

```text
Historical Contract Version
    ≠
Current Future Contract Version
```

```text
Historical Financial Truth
    ≠
Future Financing Projection
```

```text
Rescheduling
    ≠
Historical Mutation
```

```text
Contract/Schedule Transition
    ≠
Financial Transaction
```

And:

```text
Actual Financial Effect
        ↓
FinancialOperationEngine
```

## 25. Non-Goals

This ADR does not define:

- interest calculation itself;
- payment allocation order;
- early-settlement economics;
- late-fee calculation;
- statement generation;
- minimum payment;
- refinancing;
- contract transfer;
- variable-rate financing;
- legal/regulatory restructuring requirements.

Those remain governed by their respective ADRs or require separate policies.

## 26. Consequence

The financing model can now change future repayment terms without corrupting historical financial truth.

The resulting architecture is:

```text
Original Financing Contract
        ↓
Historical Schedule
        │
        └── preserved
        ↓
Restructuring Event
        ↓
New Effective Contract Version
        ↓
New Future Schedule
        ↓
Commitments / ScheduleOccurrences
        ↓
Actual Payments
        ↓
Financial Truth
```

This provides deterministic restructuring while preserving auditability, Single Writer, Money boundaries, and the separation between financial truth and future planning.

## 27. Implementation Boundary

Implementation should begin with a pure `FinancingRestructuringCalculator` / equivalent domain service that:

1. receives the current effective contract;
2. receives the explicit restructuring effective date;
3. receives the current effective financing state;
4. identifies affected future obligations;
5. calculates remaining principal;
6. applies the selected restructuring mode;
7. recalculates future interest;
8. generates the new future schedule;
9. produces a contract-version transition plan;
10. performs no persistence or financial mutation.

Only after the pure restructuring tests pass should the transition be integrated with the persistent contract/schedule layer and, where required, the Financial Operation Engine.

No independent restructuring balance or financing ledger should be introduced.
