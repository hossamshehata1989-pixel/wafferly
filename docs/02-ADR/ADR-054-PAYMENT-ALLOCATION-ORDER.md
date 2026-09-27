# ADR-054 — Payment Allocation Order

**Status:** Proposed → Implementation  
**Date:** 2026-09-27  
**Related:** ADR-051 (Credit Card Payment / Settlement Operation), ADR-052 (Installment / Financing Contract Model), ADR-053 (Interest Calculation and Installment Allocation Model), ADR-057 (Late Payment Fee Policy)

## 1. Context

ADR-051 establishes `CreditCardPaymentOperation` as the actual financial settlement operation.

ADR-052 establishes the financing contract and expected installment schedule.

ADR-053 establishes that an installment may be decomposed into:

```text
Installment Amount
    =
Principal Component
+
Interest Component
+
Applicable Financing Fees
```

A payment may therefore need to be allocated across multiple outstanding components.

The allocation order must be explicit and deterministic. It must not be inferred from the transaction amount or implemented differently by different callers.

## 2. Decision

The payment allocation order for an installment / financing obligation is:

```text
1. Fees
2. Interest
3. Principal
```

A payment is applied to the oldest/currently applicable outstanding component according to this precedence before moving to the next component.

### Fee bucket semantics

`Fees` is one allocation bucket for the MVP.

It includes all currently applicable unpaid fee components of the selected
installment, including:

```text
Normal / financing fees
Late-payment fees
```

No secondary priority exists between fee types. A late fee does not outrank a
normal financing fee, and a normal financing fee does not outrank a late fee.

The allocator therefore operates on the aggregate:

```text
outstandingFees
    =
sum(all eligible unpaid fee components)
```

The source fee components remain individually identifiable for history,
assessment, and traceability, but payment allocation does not introduce a
second fee-ordering rule.

If a future product requires a fee-type-specific priority, that priority must
be introduced by an explicit policy/ADR and must not be inferred by callers.

Conceptually:

```text
Payment
   │
   ▼
Fees
   │ remaining
   ▼
Interest
   │ remaining
   ▼
Principal
```

This order is a settlement allocation rule, not a second financial balance system.

## 3. Allocation Algorithm

For a payment amount `P`:

```text
remaining = P

feePayment = min(remaining, outstandingFees)
remaining -= feePayment

interestPayment = min(remaining, outstandingInterest)
remaining -= interestPayment

principalPayment = min(remaining, outstandingPrincipal)
remaining -= principalPayment
```

The resulting allocation must satisfy:

```text
feePayment
+
interestPayment
+
principalPayment
+
unallocatedAmount
=
paymentAmount
```

No amount may be allocated twice.

## 4. Priority

The precedence is strict:

```text
Fees
    ↓
Interest
    ↓
Principal
```

A lower-priority component must not receive payment while an applicable higher-priority component remains unpaid, unless a future explicit policy overrides this contract.

No caller may silently choose a different order.

## 5. Multiple Installments

When more than one installment is outstanding, the system must first determine which installment(s) are eligible for payment allocation.

The base allocation contract applies the precedence within the applicable repayment sequence:

```text
Oldest applicable installment
        ↓
Fees
        ↓
Interest
        ↓
Principal
        ↓
Next applicable installment
```

The exact definition of installment eligibility / ordering must remain tied to the financing contract and its schedule rather than being inferred from UI ordering.

## 6. Partial Payment

A payment smaller than the outstanding amount of the highest-priority component is allocated entirely to that component.

Example:

```text
Outstanding Fees     = 100
Outstanding Interest = 200
Outstanding Principal = 1,000

Payment = 50

Result:
Fees     = 50
Interest = 0
Principal = 0
```

The remaining unpaid components remain outstanding according to the contract.

## 7. Exact Component Payment

If the payment exactly covers one component:

```text
Outstanding Fees = 100
Payment = 100
```

then:

```text
Fees = 100
Remaining Payment = 0
```

No amount is allocated to interest or principal.

## 8. Payment Exceeding One Component

When the payment exceeds a component:

```text
Fees = 100
Interest = 200
Principal = 1,000
Payment = 250
```

the allocation is:

```text
Fees     = 100
Interest = 150
Principal = 0
```

The remaining interest is not skipped in favor of principal.

## 9. Payment Exceeding All Outstanding Components

If:

```text
Payment > Fees + Interest + Principal
```

the allocation must explicitly preserve the remainder:

```text
unallocatedAmount
    =
Payment
-
Total Outstanding Components
```

The implementation must not silently manufacture an additional principal balance or another financial effect.

The policy for an excess payment—such as refund, unapplied payment, credit balance, or rejection—must be defined by a separate contract before the product uses such behavior.

## 10. Zero and Negative Payments

The allocation component accepts only a strictly positive payment amount.

```text
Payment <= 0
    → rejected before allocation
```

This follows the payment-operation semantics established by ADR-051.

The allocator itself must not mutate financial state.

## 11. Fees

Fees are the first allocation priority when they are applicable to the financing obligation.

The allocator must distinguish:

```text
Fee assessed
    ≠
Fee paid
```

An assessed fee becomes paid only through actual payment allocation.

The allocation model must not invent fees; it consumes the fee amounts already established by the applicable financing policy.

## 12. Interest

Interest is allocated after applicable fees and before principal.

The interest amount used by the allocator must come from the established interest/financing calculation model defined by ADR-053.

The allocator must not recalculate interest as a side effect of payment allocation.

Conceptually:

```text
ADR-053
Interest Calculation
        ↓
Outstanding Interest
        ↓
ADR-054
Payment Allocation
```

## 13. Principal

Principal receives payment only after all applicable higher-priority fees and interest have been satisfied.

Principal allocation reduces the outstanding principal of the financing obligation.

The allocator must not alter the original contractual principal amount merely because a payment is received.

## 14. Financial Truth Boundary

Payment allocation is a domain calculation.

It must produce an allocation result but must not directly mutate:

```text
Account
Transaction
Ledger
Balance
Hive
```

Actual financial movement remains owned by the Financial Operation Engine.

Conceptually:

```text
CreditCardPaymentOperation
        ↓
Payment Allocation
        ↓
Allocation Result
        ↓
FinancialOperationEngine Executor
        ↓
Financial Truth
```

## 15. Money Semantics

All allocation amounts must use `Money`.

The allocation calculation must not use `double` for:

```text
paymentAmount
feePayment
interestPayment
principalPayment
unallocatedAmount
```

Rounding behavior follows the explicit monetary policy established by ADR-053 and the existing Money boundary ADRs.

## 16. Idempotency

Payment allocation must be deterministic for the same:

```text
payment operation
+
financing state
+
allocation policy
```

Repeated execution of the same payment operation must not create a second financial mutation.

Idempotency remains owned by the Financial Operation Engine as established by ADR-051.

The allocator itself remains side-effect free.

## 17. Partial / Early Payment

The allocation order does not by itself define early-settlement economics.

For a partial payment:

```text
Fees → Interest → Principal
```

is applied to the eligible outstanding amounts.

For an early payment that exceeds the current scheduled installment, future-interest treatment is not inferred by this ADR.

Policies for:

- future interest rebate;
- early-settlement fee;
- shortening the term;
- reducing future installments;

remain separate decisions.

## 18. Statement Interaction

Statement state remains separate from payment allocation.

The following must not be conflated:

```text
Statement Balance
Outstanding Financing Components
Payment Allocation
Current Liability
```

If a payment settles a closed statement, the allocation still follows the financing/payment policy established here.

Statement lifecycle remains governed by ADR-050.

## 19. Required Tests

The implementation gate must cover:

### Fee first

```text
Fees     = 100
Interest = 200
Principal = 1,000
Payment = 50

→ Fees = 50
```

### Interest after fees

```text
Payment = 250

→ Fees = 100
→ Interest = 150
→ Principal = 0
```

### Principal after fee + interest

```text
Payment = 1,300

→ Fees = 100
→ Interest = 200
→ Principal = 1,000
→ Unallocated = 0
```

### Exact component boundary

Each component must be fully consumed before allocation proceeds to the next component.

### Partial payment

A partial payment must not allocate to a lower-priority component while a higher-priority component remains outstanding.

### Excess payment

Payment exceeding all outstanding components must produce an explicit `unallocatedAmount`.

### Zero / negative payment

```text
amount <= 0
→ rejected
```

### Determinism

Same inputs must produce the same allocation result.

### No mutation

Running the allocator must not change Account, Transaction, Ledger, Balance, or Hive state.

### Money boundary

All allocation amounts remain `Money`-native.

## 20. Architectural Invariants

The following are mandatory:

```text
Fees
    >
Interest
    >
Principal
```

where `>` represents allocation precedence, not monetary magnitude.

```text
Payment Allocation
    ≠
Financial Mutation
```

```text
Calculated Interest
    ≠
Paid Interest
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

## 21. Non-Goals

This ADR does not define:

- interest calculation;
- financing rate calculation;
- minimum payment;
- statement generation;
- payment scheduling;
- early-settlement economics;
- refund processing;
- overpayment refund/credit policy;
- late fees;
- legal/regulatory payment-allocation requirements.

These require separate domain/policy decisions where applicable.

## 22. Consequence

The system now has an explicit and deterministic settlement precedence:

```text
Payment
   ↓
Fees
   ↓
Interest
   ↓
Principal
```

This keeps payment allocation separate from interest calculation, installment scheduling, statement lifecycle, and financial mutation.

It also allows future policies—such as early settlement, payment restructuring, or jurisdiction-specific allocation rules—to override or extend the base contract explicitly rather than through hidden caller behavior.

## 23. Implementation Boundary

Implementation should begin with a pure `PaymentAllocationCalculator` / equivalent domain service that:

1. accepts immutable outstanding component values;
2. accepts a positive `Money` payment;
3. applies the fixed precedence;
4. returns an immutable allocation result;
5. performs no persistence or financial mutation.

Integration with `CreditCardPaymentOperation` must occur only after the pure allocation tests pass.

No new payment balance store or financing ledger should be introduced.
