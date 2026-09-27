# ADR-057 — Late Payment Fee Policy

**Status:** Proposed → Implementation  
**Date:** 2026-09-27  
**Related:** ADR-052 (Installment / Financing Contract Model), ADR-053 (Interest Calculation and Installment Allocation Model), ADR-054 (Payment Allocation Order), ADR-055 (Multi-Installment Payment Allocation), ADR-056 (Early Settlement / Prepayment Policy)

## 1. Context

A financing contract may define an installment due date. If an applicable payment is not received by the contractual due date, the financing product may impose a late-payment fee.

Late fees must be separated from:

```text
Principal
Interest
Normal Financing Fees
```

A late fee is a consequence of delinquency. It must not be silently added to interest or principal.

The system also needs a deterministic rule for when a fee becomes applicable, how it is represented, and how it is paid.

## 2. Decision

Late-payment fees are an explicit, contract/policy-defined financing component.

A late fee may become applicable only when all of the following are true:

1. an installment is contractually payable;
2. its due date has passed;
3. the applicable grace period, if any, has elapsed;
4. the required triggering conditions are satisfied;
5. the contract explicitly permits a late fee.

The system must not invent a late fee merely because an installment is overdue.

## 3. Due Date and Grace Period

The late-fee eligibility date is:

```text
Due Date
    +
Configured Grace Period
    ↓
Late-Fee Trigger Date
```

If no grace period is configured:

```text
Late-Fee Trigger Date = Due Date
```

The trigger calculation must use an explicit allocation/evaluation date supplied by the domain operation.

It must not depend implicitly on `DateTime.now()`.

## 4. Late Fee Configuration

The contract/policy must explicitly identify the late-fee rule.

The base model should support:

```text
No late fee
Fixed late fee
```

A percentage-based or time-accruing late fee requires a separate explicit policy and must not be inferred from the fixed-fee model.

A configured late fee must use `Money` in the Domain/Planning boundary.

## 4A. Installment Lifecycle Boundary

Late-fee eligibility is evaluated against the effective installment lifecycle.
A cancelled, superseded, or already-settled installment must not receive a new
late-fee assessment.

Contract-level delinquency/default state is governed by ADR-064 and does not,
by itself, create a late fee.

## 5. One-Time vs Repeating Late Fees

The base policy supports a **one-time late fee per installment delinquency event**.

The system must not repeatedly add the same fee every time a delinquent installment is evaluated.

Conceptually:

```text
Installment becomes delinquent
        ↓
Late Fee assessed once
        ↓
Repeated evaluation
        ↓
No duplicate fee
```

A recurring daily/monthly delinquency charge is outside the base policy and requires a separate contract.

## 6. Fee Identity and Idempotency

Every assessed late fee must have a stable identity tied to:

```text
Financing Contract
+
Installment / ScheduleOccurrence
+
Late-Fee Policy Event
```

Repeated processing of the same delinquency event must return the existing fee state rather than create another fee.

The fee identity must remain stable across retries and process restarts.

## 7. Assessment vs Payment

The system must distinguish:

```text
Late Fee Assessed
    ≠
Late Fee Paid
```

Assessment creates a contractual/financing obligation.

Actual payment remains a financial operation through the Financial Operation Engine.

A late fee must not be considered paid merely because it was assessed.

## 8. Allocation Priority

Once assessed and outstanding, a late fee is a **Fee** component.

Therefore ADR-054 applies:

```text
Fees
    ↓
Interest
    ↓
Principal
```

A payment allocated to an installment may therefore settle an applicable late fee before interest and principal.

The late-fee policy does not create a new payment precedence rule.

## 9. Relationship to Multiple Installments

ADR-055 determines which installment receives payment first.

Within the selected installment:

```text
Late Fees / Applicable Fees
        ↓
Interest
        ↓
Principal
```

An overdue older installment must therefore retain priority over a later installment according to ADR-055.

## 10. Partial Payment

If a payment does not fully cover the applicable late fee:

```text
Late Fee = 100
Payment = 40

→ Late Fee Paid = 40
→ Remaining Late Fee = 60
```

The payment must not skip the remaining fee and allocate the remainder to interest or principal.

## 11. Fee Calculation

The late-fee calculation must be deterministic.

For a fixed late fee:

```text
Late Fee = configured fixed Money amount
```

The calculation must not depend on:

```text
floating-point arithmetic
machine clock
collection order
UI state
```

The fee calculation must be a pure domain calculation before persistence.

## 12. Interaction With Interest

A late fee is not normal financing interest.

Therefore:

```text
Late Fee
    ≠
Interest
```

The late fee must not be included in the interest calculation base unless a separate financing policy explicitly defines such behavior.

This ADR does not authorize interest-on-fee or penalty-interest compounding.

## 13. Interaction With Early Settlement

If an installment has an assessed and outstanding late fee at the time of early settlement:

```text
Early Settlement
    ↓
Applicable Fees
    ↓
Applicable Interest
    ↓
Remaining Principal
```

The late fee remains a fee component under ADR-054.

Future late fees for installments that become cancelled/superseded by a valid full early settlement must not be generated after those installments cease to be payable.

Historical assessed fees must not be deleted merely because later contract state changes.

## 14. Cancellation and Contract State

A late fee may only be assessed while the underlying installment is contractually payable.

No new late fee may be generated for:

- cancelled installments;
- superseded installments;
- fully settled installments;
- completed financing contracts.

If a previously assessed fee is later found to be invalid because of a correction or contract transition, its reversal/correction must use an explicit financial/domain operation.

The system must not delete historical financial records to hide the invalid fee.

## 15. Financial Truth Boundary

Late-fee assessment is a domain calculation/state transition.

It must not directly mutate:

```text
Account
Transaction
Ledger
Balance
Hive
```

Actual financial recognition/payment must follow the application's financial writer boundary.

Conceptually:

```text
Late Fee Policy
      ↓
Late Fee Assessment
      ↓
Contract / Financing State
      ↓
Financial Operation when applicable
      ↓
Financial Truth
```

The late-fee calculator itself must remain side-effect free.

## 16. Scheduled Evaluation

Late-fee eligibility may be evaluated by a scheduled process.

If scheduled execution is used, the existing scheduled execution atomicity and recovery contract applies.

A retry must not:

```text
assess the same late fee twice
create duplicate financial effects
advance the same occurrence twice
```

Stable installment/event identity is required.

## 17. Traceability

Each late-fee assessment should be traceable to:

```text
Contract
Installment / ScheduleOccurrence
Due Date
Grace Period
Trigger Date
Late-Fee Policy
Assessment Identity
```

If a financial operation is produced, it must also use the existing Financial Operation Traceability boundary.

Traceability remains audit/history data and is not financial truth.

## 18. Money Semantics

All late-fee amounts inside Domain/Planning code must use `Money`.

No late-fee calculation may convert to `double` for arithmetic.

Legacy conversion is permitted only at approved persistence/application compatibility boundaries.

## 19. Required Tests

### No late fee before due date

```text
evaluationDate < dueDate
→ no fee
```

### Grace period

```text
dueDate < evaluationDate <= triggerDate
→ no fee
```

### Trigger

```text
evaluationDate > / >= triggerDate
→ fee eligible according to configured boundary
```

The exact inclusive/exclusive trigger comparison must be encoded and tested.

### One-time assessment

```text
evaluate twice
→ one fee
```

### Fixed fee

The same contract inputs must produce the same `Money` fee.

### Partial payment

```text
Fee = 100
Payment = 40

→ Fee remaining = 60
```

### Allocation precedence

```text
Late Fee
    before
Interest
    before
Principal
```

### Older installment

Late fee on an older eligible installment must be encountered according to ADR-055 installment ordering.

### Cancelled installment

No new late fee may be assessed.

### Early settlement

Future late fees for cancelled/superseded future installments must not be created.

### Idempotency

Retrying the same delinquency event produces one fee.

### No duplicate financial mutation

Repeated scheduled evaluation must not create duplicate financial effects.

### No direct persistence mutation

The fee calculator must not write Account, Transaction, Ledger, Balance, or Hive.

### Explicit evaluation date

Tests must not depend on the machine's current date/time.

## 20. Architectural Invariants

The following are mandatory:

```text
Late Fee
    ≠
Interest
```

```text
Late Fee Assessed
    ≠
Late Fee Paid
```

```text
Late Fee
    = Fee component
```

and therefore:

```text
Fees → Interest → Principal
```

remains the payment allocation order.

Also:

```text
Late Fee Calculation
    ≠
Financial Mutation
```

Actual financial effects must remain behind the Financial Operation Engine.

## 21. Non-Goals

This ADR does not define:

- percentage-based late fees;
- daily/monthly recurring delinquency fees;
- interest on late fees;
- penalty interest;
- legal/regulatory limits;
- collections workflows;
- credit bureau reporting;
- minimum payment;
- statement generation;
- refund policy for invalid late fees.

These require separate domain/policy decisions.

## 22. Consequence

The financing model now has an explicit delinquency-fee contract:

```text
Due Date
    ↓
Grace Period
    ↓
Late-Fee Trigger
    ↓
One-Time Fee Assessment
    ↓
Fees → Interest → Principal
```

This keeps late fees separate from interest and principal, prevents duplicate assessment, preserves installment seniority, and maintains the existing Single Writer / Financial Truth boundaries.

## 23. Implementation Boundary

Implementation should begin with a pure `LateFeeCalculator` / equivalent domain service that:

1. receives the installment due date;
2. receives the explicit evaluation date;
3. receives the configured grace period;
4. receives the late-fee policy;
5. determines eligibility;
6. calculates the fixed `Money` fee;
7. produces a deterministic assessment result;
8. performs no persistence or financial mutation.

The assessment identity and persistence transition should then be integrated with the existing commitment/schedule architecture and idempotency/recovery boundaries.

No independent late-fee balance ledger should be introduced.
