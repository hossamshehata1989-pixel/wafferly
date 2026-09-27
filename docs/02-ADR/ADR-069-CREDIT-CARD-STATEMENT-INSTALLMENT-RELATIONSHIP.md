# ADR-069 — Credit Card Statement ↔ Installment Relationship

**Status:** Proposed → Implementation  
**Date:** 2026-09-27  
**Related:** ADR-050 (Credit Card Statement Lifecycle & Due-Date Generation), ADR-052 (Installment / Financing Contract Model), ADR-053 (Interest Calculation and Installment Allocation Model), ADR-051 (Credit Card Payment / Settlement Operation)

## 1. Context

ADR-050 defines a Statement as a derived closed-period representation and preserves the Liability Account as the authoritative current financial position.

ADR-052 defines an Installment Financing Contract as expected repayment structure rather than financial truth.

ADR-053 defines the installment schedule and separates calculated principal/interest/fees from actual payment.

The remaining boundary is how scheduled installments appear in Credit Card statements without double-counting the originating financial liability.

## 2. Decision

For Credit Card installment financing, **statement inclusion is based on the scheduled installment's eligibility for the statement cycle**.

```text
Originating Charge / Financing Event
        ↓
Financial Liability
        +
Installment Financing Contract
        ↓
Installment Schedule
        ↓
Installment Due Date
        ↓
Statement Cycle Eligibility
        ↓
Statement Contribution
```

The statement does not copy the full financing principal merely because a financing contract exists.

## 3. No Double Counting

The following invariant is mandatory:

```text
Originating financed liability
        ≠
Repeated full-principal statement entries
```

For an amortizing plan:

```text
Statement Contribution
    =
scheduled principal component
+
scheduled interest component
+
applicable scheduled financing fees
```

where applicable.

Future installments are not included in an earlier statement merely because the contract already exists.

## 4. Statement Balance Boundary

Statement balance is a closed-period value.

It is neither:

```text
current liability
```

nor:

```text
remaining financing principal
```

The authoritative current liability remains:

```text
Liability Account
+
effective financial transactions
```

The statement is a derived period presentation of eligible obligations at the statement closing boundary.

## 5. Originating Charge and Financing Conversion

When an originating Credit Card charge is converted into an installment plan, the conversion establishes an explicit financing boundary.

The implementation must identify which scheduled installment obligations are statement-eligible after that boundary so that:

```text
full originating amount
+
installment amount
```

is never silently counted twice for the same economic obligation.

Previously closed statements remain historical records and are not rewritten merely because a later financing conversion occurred.

## 6. Interest and Fees

Interest calculation remains governed by ADR-053.

Statement inclusion does not recalculate interest.

```text
Interest Calculation
        ↓
Scheduled Interest Component
        ↓
Statement Eligibility
        ↓
Statement Contribution
```

Applicable financing fees follow the same separation.

Assessment/calculation is distinct from actual payment.

## 7. Payment Relationship

A statement containing an installment does not mean that the installment has been paid.

```text
Statement Contribution
    ≠
Payment
```

Actual payment continues through ADR-051 and the Financial Operation Engine.

Payment allocation follows ADR-054/ADR-055 and must not rewrite the historical closed statement amount.

## 8. State and Source-of-Truth Boundaries

| Concern | Owner |
|---|---|
| Current liability | Liability Account + effective financial transactions |
| Financing terms | Installment Financing Contract |
| Expected installment | Schedule / Installment |
| Installment due date | Schedule / Installment |
| Statement cycle | Statement domain |
| Statement contribution | Derived statement/installment relationship |
| Closed statement balance | Statement domain |
| Actual payment | Financial Operation Engine |
| Payment allocation | ADR-054 / ADR-055 |
| Audit/traceability | ADR-068 |

No statement or installment projection may become a second financial ledger.

## 9. Idempotency

Statement generation for an eligible installment must be deterministic and idempotent.

Repeated closing of the same statement cycle must not:

```text
duplicate an installment contribution
create a second statement
create a financial transaction
```

A stable relationship identity should be based on the statement cycle and installment identity.

## 10. Corrections and Historical Immutability

Closed statements remain historical period records.

A later transaction correction, financing conversion, reversal, or replacement follows the existing effective-truth and correction architecture.

A closed statement must not be rewritten merely to make current data appear historically convenient.

## 11. Required Tests

- First installment in a statement cycle contributes once.
- Future installment does not contribute to an earlier statement.
- Financed purchase does not contribute both the full financed principal and the same scheduled principal again.
- Scheduled interest contributes only when its installment is statement-eligible.
- Applicable financing fees follow the same eligibility boundary.
- Later events do not rewrite a closed statement.
- Same statement cycle + same installment produces one contribution.
- Statement contribution does not equal payment.
- Statement generation does not directly mutate Account, Transaction, Ledger, or Balance.

## 12. Architectural Invariants

```text
Statement
    ≠
Current Liability
```

```text
Installment Schedule
    ≠
Financial Transaction
```

```text
Statement Contribution
    ≠
Payment
```

```text
Full Financed Principal
    ≠
Repeated Monthly Statement Principal
```

And:

```text
Actual Financial Effect
        ↓
FinancialOperationEngine
```

## 13. Consequence

The resulting boundary is:

```text
Financial Truth
    ↓
Liability Account / Transactions

Financing Projection
    ↓
Contract / Schedule / Installments

Periodic Presentation
    ↓
Statements
```

This prevents double counting while allowing each installment's principal, interest, and applicable fees to appear in the statement period in which they are contractually eligible.

No second liability ledger is introduced.
