# ADR-055 — Multi-Installment Payment Allocation by Seniority and Due Status

**Status:** Proposed → Implementation  
**Date:** 2026-09-27  
**Related:** ADR-052 (Installment / Financing Contract Model), ADR-053 (Interest Calculation and Installment Allocation Model), ADR-054 (Payment Allocation Order), ADR-051 (Credit Card Payment / Settlement Operation)

## 1. Context

ADR-054 defines the allocation precedence inside an applicable installment:

```text
Fees
    ↓
Interest
    ↓
Principal
```

A financing contract may have multiple outstanding installments at the same time. A single payment therefore needs a deterministic rule for deciding **which installment receives the payment first**.

Without an explicit ordering contract, different callers could allocate the same payment differently.

This ADR defines installment-level ordering. It does not replace the component-level precedence established by ADR-054.

## 2. Decision

When a payment is allocated across multiple outstanding installments, the system uses **oldest eligible installment first**.

Eligibility and ordering are determined from the installment's contractual due status and scheduled due date.

The base precedence is:

```text
Eligible overdue installments
        ↓
Eligible due-today installment
        ↓
Eligible future installments
```

Within each group, installments are ordered by:

```text
dueDate ASC
stable installment identity ASC
```

This creates a deterministic oldest-first repayment sequence.

## 3. Installment Eligibility

An installment is eligible for allocation when it represents an outstanding contractual obligation that may receive payment under the financing contract.

The allocator must not allocate against:

- cancelled installments;
- already fully settled installments;
- superseded/replaced installments;
- installments that are not legally/contractually payable under the current contract state.

The exact contract state model remains governed by ADR-052.

## 4. Due Status

For allocation purposes, an installment is classified using its scheduled due date relative to the allocation date:

```text
dueDate < allocationDate
    → overdue

dueDate == allocationDate
    → due today

dueDate > allocationDate
    → future
```

The allocation date must be supplied explicitly.

The allocator must not depend on the machine clock implicitly.

## 5. Base Priority

The base installment-level precedence is:

```text
1. Oldest overdue installment
2. Next overdue installment
3. Due-today installment
4. Earliest future installment
5. Continue chronologically
```

In compact form:

```text
overdue
    ↓
due today
    ↓
future

within each group:
dueDate ASC
```

This means a future installment must not receive payment while an earlier eligible overdue or due installment remains outstanding.

## 6. Interaction With ADR-054

Installment ordering and component ordering are separate decisions.

The complete allocation process is:

```text
Payment
   ↓
Select oldest eligible installment
   ↓
Fees
   ↓
Interest
   ↓
Principal
   ↓
If payment remains:
   ↓
Select next eligible installment
   ↓
Fees
   ↓
Interest
   ↓
Principal
   ↓
Continue
```

Therefore:

```text
Installment Priority
    = oldest eligible first

Component Priority
    = Fees → Interest → Principal
```

Neither rule replaces the other.

## 7. Example — One Payment Across Multiple Installments

Assume:

```text
Installment 1
Due: Jan 10
Fees: 100
Interest: 200
Principal: 700

Installment 2
Due: Feb 10
Fees: 0
Interest: 150
Principal: 850

Payment: 500
Allocation Date: Mar 1
```

Both installments are overdue.

Installment 1 is older, so it is selected first:

```text
Installment 1:
Fees     = 100
Interest = 200
Principal = 200
```

Installment 2 receives nothing.

The remaining principal of Installment 1 remains outstanding.

## 8. Example — First Installment Fully Settled

Assume:

```text
Installment 1 total outstanding = 1,000
Installment 2 total outstanding = 1,000
Payment = 1,400
```

The allocator must:

```text
Installment 1
    → settle all 1,000

Remaining payment
    → 400

Installment 2
    → allocate 400 according to ADR-054
```

The payment must not skip directly to Installment 2.

## 9. Example — Overdue vs Future

Assume:

```text
Installment 1
Due: Jan 10
Outstanding: 500

Installment 2
Due: Feb 10
Outstanding: 500

Installment 3
Due: Apr 10
Outstanding: 500

Allocation date: Mar 1
Payment: 700
```

Installments 1 and 2 are overdue.

Installment 1 is older and receives payment first:

```text
Installment 1 → 500
Installment 2 → 200
Installment 3 → 0
```

The future installment is not selected while earlier eligible obligations remain unpaid.

## 10. Example — Due Today

If:

```text
Installment 1
Due: yesterday
Outstanding: 500

Installment 2
Due: today
Outstanding: 500
```

the overdue installment is selected first.

The due-today installment is selected only after the earlier eligible obligation is satisfied.

## 11. Example — Multiple Future Installments

If no overdue or due-today installment remains and a payment is explicitly allowed to cover future obligations:

```text
Installment 3 → due Apr 10
Installment 4 → due May 10
Installment 5 → due Jun 10
```

the allocation order is:

```text
Apr 10
    ↓
May 10
    ↓
Jun 10
```

The allocator must never rely on list insertion order.

## 12. Stable Tie-Breaking

Two installments may theoretically have the same due date.

The allocator therefore requires a stable secondary ordering:

```text
dueDate ASC
stable installment identity ASC
```

The identity must be deterministic and persisted with the installment/occurrence.

This prevents allocation results from changing because of database or collection ordering.

## 13. Partial Allocation

If the payment cannot fully settle the selected installment, allocation stops at that installment.

ADR-054 applies inside it:

```text
Fees → Interest → Principal
```

Example:

```text
Selected installment:
Fees = 100
Interest = 200
Principal = 1,000

Payment = 250
```

Result:

```text
Fees = 100
Interest = 150
Principal = 0
```

No allocation proceeds to the next installment because the selected installment still has an outstanding higher-priority component.

## 14. Fully Settled Installment

An installment is considered fully satisfied only when all applicable outstanding components have been settled according to the contract.

Conceptually:

```text
Outstanding Fees = 0
Outstanding Interest = 0
Outstanding Principal = 0
```

Only then may remaining payment continue to the next eligible installment.

## 15. Future Installment Payments

This ADR allows a financing contract to explicitly support payment toward future installments, but it does not define the economic consequences of such prepayment.

In particular, it does not decide:

- whether future interest is waived;
- whether the term is shortened;
- whether future installments are reduced;
- whether an early-settlement fee applies.

Those remain separate policies.

The allocation order only determines which eligible installment is selected.

## 16. Overpayment

If the payment exceeds every eligible outstanding installment:

```text
Total Payment
    >
Total Eligible Outstanding
```

the remaining amount becomes:

```text
unallocatedAmount
```

as established by ADR-054.

This ADR does not define whether that remainder becomes:

- an unapplied payment;
- customer credit;
- refund;
- rejection.

That policy requires a separate contract.

## 17. Financial Truth Boundary

The multi-installment allocator is a pure domain calculation.

It must not directly mutate:

```text
Account
Transaction
Ledger
Balance
Hive
```

The flow remains:

```text
CreditCardPaymentOperation
        ↓
Multi-Installment Allocation
        ↓
Allocation Result
        ↓
FinancialOperationEngine
        ↓
Financial Truth
```

The allocator decides distribution; the Financial Engine owns financial mutation.

## 18. Money Semantics

All allocation amounts must remain `Money`.

The allocator must not use:

```text
double
int cents as a substitute for Money
```

as a financial domain representation.

Any legacy conversion must occur only at an approved compatibility boundary.

## 19. Determinism and Idempotency

Given identical:

```text
payment
allocationDate
installment state
contract policy
```

the allocator must return the same result.

The allocator itself is side-effect free.

Financial idempotency remains owned by the Financial Operation Engine.

A retry of the same payment operation must not allocate and persist a second financial effect.

## 20. Corrections and Historical Truth

Allocation must operate against the applicable current contractual/financial state.

It must not rewrite immutable historical transactions.

If a previous payment is corrected or invalidated, the effective financial truth rules determine the active financial effect.

Any resulting change in future allocation must be represented through the established correction/invalidation architecture rather than modifying historical payment records.

## 21. Required Tests

The implementation gate must cover:

### Oldest overdue first

```text
Installment 1 overdue
Installment 2 overdue
→ Installment 1 first
```

### Due today after overdue

```text
overdue
+
due today
→ overdue first
```

### Future after due

```text
due today
+
future
→ due today first
```

### Chronological future ordering

```text
Apr → May → Jun
```

### Same-date tie breaker

```text
same dueDate
→ stable identity ordering
```

### Partial allocation

Payment must stop at the first incompletely settled eligible installment.

### Cross-installment payment

A payment that fully settles one installment must continue to the next.

### Component precedence

Within each installment:

```text
Fees → Interest → Principal
```

### Future payment policy boundary

A payment against future installments must not silently change future-interest economics.

### Excess payment

Remaining payment must be returned as explicit `unallocatedAmount`.

### Determinism

Same inputs must produce identical allocation output.

### No mutation

Allocation must not mutate financial persistence.

### Explicit allocation date

The test must prove the allocator does not depend on the machine's current date/time.

## 22. Architectural Invariants

The following are mandatory:

```text
Installment Priority
    = oldest eligible first
```

```text
Component Priority
    = Fees → Interest → Principal
```

```text
Payment Allocation
    ≠
Financial Mutation
```

```text
ScheduleOccurrence
    ≠
Payment Transaction
```

```text
Installment Contract
    ≠
Financial Balance
```

And:

```text
Actual Financial Effect
        ↓
FinancialOperationEngine
```

## 23. Non-Goals

This ADR does not define:

- interest calculation;
- fee calculation;
- payment allocation within one installment beyond ADR-054;
- early-settlement economics;
- prepayment interest rebate;
- refinancing;
- restructuring;
- minimum payment;
- statement generation;
- payment refund/credit policy;
- legal/regulatory allocation rules.

## 24. Consequence

The financing system now has two explicit allocation dimensions:

```text
Which installment?
    ↓
Oldest eligible first

What component within it?
    ↓
Fees → Interest → Principal
```

This produces a deterministic multi-installment settlement model without introducing another financial balance source or writer.

## 25. Implementation Boundary

Implementation should begin with a pure multi-installment allocation service/calculator that:

1. accepts an immutable list of outstanding installment projections;
2. accepts an explicit allocation date;
3. filters eligible installments;
4. orders them deterministically;
5. delegates component allocation to the ADR-054 precedence;
6. returns an immutable allocation result;
7. performs no persistence or financial mutation.

Integration with `CreditCardPaymentOperation` should occur only after the pure allocation tests pass.

No independent installment balance ledger should be introduced.
