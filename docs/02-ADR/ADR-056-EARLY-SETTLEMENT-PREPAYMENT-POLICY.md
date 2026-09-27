# ADR-056 — Early Settlement / Prepayment Policy

**Status:** Proposed → Implementation  
**Date:** 2026-09-27  
**Related:** ADR-052 (Installment / Financing Contract Model), ADR-053 (Interest Calculation and Installment Allocation Model), ADR-054 (Payment Allocation Order), ADR-055 (Multi-Installment Payment Allocation)

## 1. Context

ADR-052 defines the financing contract and expected installment schedule.

ADR-053 defines how interest is calculated and allocated to installments.

ADR-054 defines component payment precedence:

```text
Fees → Interest → Principal
```

ADR-055 defines installment ordering:

```text
Oldest eligible installment first
```

A borrower may pay more than the currently due installment amount, including paying all or part of the remaining financing obligation before its scheduled maturity.

This creates a separate policy question:

```text
What happens to future interest when principal is prepaid?
What happens to the remaining installments?
```

The system must not silently invent a prepayment policy from the normal installment-payment flow.

## 2. Decision

Early settlement is treated as an explicit financing-domain operation/policy.

A payment is considered an **early settlement / prepayment** when it intentionally settles principal or future scheduled obligations before their contractual due dates.

The base policy is:

> **Future unaccrued interest is not automatically treated as payable when the underlying principal is prepaid.**

Therefore, when early settlement closes future principal obligations, interest that has not yet become applicable under the contract is excluded from the settlement amount unless an explicit financing policy says otherwise.

## 3. Important Distinction

The system must distinguish:

```text
Accrued / currently applicable interest
        ≠
Future unaccrued interest
```

An early settlement may settle:

```text
Applicable Fees
+
Applicable / Accrued Interest
+
Remaining Principal
```

but must not automatically add all future scheduled interest.

Conceptually:

```text
Early Settlement Amount
    =
Applicable Fees
+
Applicable Interest
+
Eligible Remaining Principal
+
Explicit Early-Settlement Fees, if contractually defined
```

Future unaccrued interest is excluded from the base settlement amount.

## 4. No Silent Interest Recalculation

The system must not mutate historical interest calculations merely because a borrower prepays.

Historical financial truth remains immutable.

Instead:

```text
Original Financing Schedule
        ↓
Early Settlement Event
        ↓
Future obligations become cancelled/superseded
        ↓
Settlement projection is recalculated for remaining obligations
```

The recalculation affects future contractual projections, not historical transactions.

## 5. Remaining Installments

When an early settlement fully satisfies the remaining financing obligation:

```text
Remaining Principal = 0
Applicable Interest = settled
Future Unaccrued Interest = 0 payable
```

Future installments are then marked as no longer payable under the original schedule.

They must not be deleted in a way that destroys historical schedule/audit evidence.

Conceptually:

```text
Future Installment
    ↓
Cancelled / Superseded by Early Settlement
```

rather than:

```text
Future Installment
    ↓
Deleted from history
```

## 6. Partial Prepayment

A partial prepayment does not automatically mean the entire contract is settled.

After a partial prepayment:

```text
Original Principal
    ↓
Partial Principal Reduction
    ↓
Reduced Future Principal
```

The system must then explicitly apply the contract's selected restructuring policy to the remaining installments.

The base ADR defines two supported projection modes:

### Mode A — Term Reduction

Keep the scheduled installment amount as the target amount and reduce the number of future installments.

```text
Payment Amount
    ≈ unchanged

Remaining Term
    ↓
shorter
```

### Mode B — Installment Reduction

Keep the remaining number of installments and recalculate their amounts from the reduced principal.

```text
Remaining Term
    = unchanged

Future Installment Amount
    ↓
recalculated downward
```

The selected mode must be an explicit contract/policy value. It must not be guessed from UI behavior.

## 7. Default Policy

If the financing contract does not explicitly select a partial-prepayment restructuring mode, the implementation must not silently choose one.

The system must require an explicit policy before changing the future schedule.

This prevents a payment operation from unexpectedly changing contractual terms.

## 8. Recalculation Boundary

After a valid partial prepayment, recalculation begins from the settlement boundary.

Conceptually:

```text
Historical installments
        │
        ├── remain immutable
        │
Settlement boundary
        │
        ▼
Recalculate future projection
        │
        ├── remaining principal
        ├── future interest
        └── remaining installments
```

Interest is recalculated only for future periods affected by the reduced principal and selected restructuring policy.

## 9. Interest Recalculation

For an amortizing financing plan:

```text
New Future Interest
    =
interest calculated from
reduced future principal
+
remaining contractual periods
+
selected interest policy
```

The system must use the same explicit rate and rounding semantics established by ADR-053 unless a separate contract amendment changes them.

No recalculation may modify already-settled or historically recorded interest.

## 10. Final Installment Reconciliation

After recalculation, the future schedule must still satisfy the financing invariants:

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

subject to the rounding policy established by ADR-053.

The final installment may be adjusted deterministically to absorb monetary rounding differences.

## 11. Early-Settlement Fee

This ADR does not assume that an early-settlement fee exists.

If the financing product has such a fee, it must be an explicit contract/policy value.

It must not be hidden inside:

```text
interest
```

or:

```text
principal
```

The fee must remain separately identifiable for allocation under ADR-054.

## 12. Payment Allocation Interaction

The payment itself continues to use the established allocation precedence:

```text
Fees
    ↓
Interest
    ↓
Principal
```

from ADR-054.

Early settlement changes **which future obligations remain**; it does not silently change the basic component precedence.

ADR-055 installment ordering remains applicable to selecting the obligations affected by the payment.

## 13. Early Settlement vs Normal Payment

The system must distinguish:

```text
Normal Scheduled Payment
        ≠
Partial Prepayment
        ≠
Full Early Settlement
```

### Normal Scheduled Payment

Pays the applicable scheduled obligation.

### Partial Prepayment

Pays additional principal before its scheduled maturity and requires an explicit future-schedule policy.

### Full Early Settlement

Settles the remaining eligible financing obligation and terminates future repayment obligations under that contract.

## 14. Contract State

A fully settled financing contract transitions to:

```text
completed
```

or the equivalent terminal contract state defined by ADR-052.

A partially prepaid contract remains active unless the remaining obligation reaches zero.

Contract state changes must not delete financial history.

## 15. Idempotency

Early settlement must have a stable operation identity.

Retrying the same settlement operation must not:

- settle the same principal twice;
- create duplicate payment transactions;
- cancel future installments twice;
- generate duplicate replacement schedules.

The Financial Operation Engine remains the authority for financial idempotency.

Schedule/contract transitions must use stable identities and the existing durable recovery semantics where applicable.

## 16. Atomicity

A settlement operation that produces financial mutation and contract/schedule transition must not leave an ambiguous partial state.

Conceptually:

```text
Financial Settlement
        +
Contract/Schedule Transition
```

must converge through the existing Financial Engine and scheduling recovery architecture.

If the financial effect succeeds but a scheduling transition fails, recovery must resume the scheduling transition without creating a second financial payment.

## 17. Financial Truth Boundary

Early-settlement calculation is a domain projection.

It must not directly mutate:

```text
Account
Transaction
Ledger
Balance
Hive
```

Actual settlement remains:

```text
Early Settlement Operation
        ↓
FinancialOperationEngine
        ↓
Payment Transaction
        ↓
Financial Truth
```

The future schedule is then transitioned/recalculated according to this ADR.

## 18. Statement Interaction

An early settlement may affect future statements, but this ADR does not redefine the Statement Lifecycle.

The statement model remains governed by ADR-050.

Historical closed statements must not be rewritten merely because a later early settlement occurs.

Future statement projections may change because future installments are cancelled or recalculated.

## 19. Money Semantics

All principal, interest, fee, settlement, and installment values inside the Domain/Planning boundary remain `Money`-native.

No early-settlement calculation may use `double` for monetary arithmetic.

Rounding follows ADR-053 and the established Money boundary contracts.

## 20. Required Tests

### Full early settlement

```text
Remaining Principal = 5,000
Future Unaccrued Interest = 800

Early Settlement
→ settles applicable current amounts + 5,000 principal
→ future 800 interest is not charged by default
→ future installments become cancelled/superseded
→ contract completes
```

### Partial prepayment

A partial principal payment must reduce future principal and require an explicit restructuring mode.

### Term reduction

```text
Installment target amount
    ≈ preserved

Remaining term
    ↓
reduced
```

The recalculated schedule must close principal exactly.

### Installment reduction

```text
Remaining term
    = preserved

Future installment amount
    ↓
recalculated
```

The recalculated schedule must close principal exactly.

### Historical immutability

Early settlement must not modify or delete historical financial transactions or already-settled interest.

### Future interest exclusion

Unaccrued future interest must not automatically become payable.

### Explicit fee

If an early-settlement fee is configured, it remains a separate fee component.

### No implicit restructuring

A partial prepayment without a configured restructuring mode must be rejected or require explicit user/domain selection according to the implementation contract.

### Idempotency

Retrying the same settlement operation produces one financial effect and one contract transition.

### Atomic recovery

A failure after financial success must not cause a second financial settlement during retry.

### Money boundary

All domain monetary calculations remain `Money`-native.

## 21. Architectural Invariants

The following are mandatory:

```text
Future Unaccrued Interest
    ≠
Automatically Payable Interest
```

```text
Historical Financial Truth
    ≠
Future Financing Projection
```

```text
Early Settlement
    ≠
Negative Credit Card Charge
```

```text
Contract Schedule
    ≠
Financial Balance
```

And:

```text
Actual Settlement
        ↓
FinancialOperationEngine
```

## 22. Non-Goals

This ADR does not define:

- legal/regulatory prepayment rules;
- mandatory early-settlement fees;
- variable interest;
- late-payment interest;
- statement generation;
- minimum payment;
- refinancing;
- contract transfer;
- tax treatment;
- jurisdiction-specific consumer-credit requirements.

Those require separate policy/domain decisions.

## 23. Consequence

The financing architecture now has an explicit distinction between normal repayment and early settlement.

The base policy ensures:

```text
Early Principal Settlement
        ↓
Future Unaccrued Interest
        ↓
excluded by default
```

while preserving:

```text
Fees → Interest → Principal
```

for the actual payment allocation.

Partial prepayment cannot silently rewrite the financing contract. The future schedule must be regenerated using an explicitly selected term-reduction or installment-reduction policy.

This keeps historical financial truth immutable while allowing future financing projections to change deterministically.

## 24. Implementation Boundary

Implementation should begin with a pure early-settlement calculator/policy service that:

1. receives the financing contract;
2. receives the current effective financing state;
3. receives the explicit settlement date;
4. determines applicable fees/interest;
5. calculates eligible remaining principal;
6. excludes future unaccrued interest by default;
7. produces a settlement projection;
8. produces a future schedule transition plan;
9. performs no persistence or financial mutation.

Only after these pure calculations are tested should the policy be integrated with the Financial Operation Engine and contract/schedule transition layer.

No independent settlement balance or financing ledger should be introduced.
