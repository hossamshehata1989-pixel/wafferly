# ADR-071 — Credit Card Charge Payment Method Change Boundary

**Status:** Accepted  
**Date:** 2026-10-04  
**Scope:** Architecture decision only; implementation is intentionally deferred.  
**Related:** ADR-047 (Credit Card Charge Operation), ADR-049 (Credit Limit / Credit Exposure Domain Guard), ADR-050 (Credit Card Statement Lifecycle & Due-Date Generation), ADR-051 (Credit Card Payment / Settlement Operation), ADR-052 (Installment / Financing Contract Model), ADR-054 (Payment Allocation Order), ADR-055 (Multi-Installment Payment Allocation), ADR-062 (Overpayment / Excess-Payment Policy), ADR-066 (Financing Financial Effects Boundary), ADR-067 (Financing Operation Idempotency), ADR-068 (Financing Audit / Traceability Boundary), ADR-069 (Credit Card Statement ↔ Installment Relationship), ADR-070 (Credit Card Posted-Charge → Installment Conversion Boundary)

## 1. Context

Wafferly supports editing an existing Credit Card charge. Editing ordinary transaction data such as category, member, date, note, or amount is distinct from changing the **Payment Method** of the charge.

A Credit Card charge is a liability-producing financial event. Changing its payment method changes the financial accounts affected by the event.

Therefore:

```text
Change Amount
    ≠
Change Payment Method
```

A Payment Method change is not a simple `Account` field update.

The primary boundary is the **Credit Card Statement lifecycle**. Financing is an additional independent boundary.

This ADR is intentionally scoped to:

```text
Existing posted Credit Card Charge
        ↓
Change its Payment Method
        ↓
to another eligible financial account
```

It does **not** define Cash/Debit → Credit Card entry as part of the same operation. A separate operation/ADR may define that flow later.

## 2. Decision

Wafferly will treat **Change Payment Method on an existing Credit Card Charge** as a dedicated financial correction operation.

The MVP UI will **not expose direct Payment Method switching from the normal Edit Transaction screen**.

The Credit Card account shown by the existing Edit screen remains fixed.

A future explicit action such as:

```text
Change Payment Method
```

may invoke the dedicated correction operation after all eligibility checks pass.

The operation must preserve the logical Transaction ID.

It must not delete the transaction and create an unrelated replacement transaction.

## 3. Exact Definition of "Unbilled"

For this ADR, **unbilled is a statement-cycle state, not the presence or absence of a persisted Statement record**.

A Credit Card charge is considered **unbilled / eligible on the source side** only when its effective transaction date belongs to a statement cycle that is still open under the source Credit Card's statement lifecycle.

Therefore:

```text
Statement record exists
    ≠
only test for billed state
```

and:

```text
Statement record does not exist
    ≠
automatically unbilled
```

The implementation must evaluate the Credit Card's statement-cycle boundaries.

If the charge's effective date belongs to a cycle whose closing boundary has already passed, the charge is treated as billed/closed for this operation even if statement materialization has not yet created a persisted Statement record.

Conceptually:

```text
Transaction Effective Date
          ↓
Statement Cycle Resolution
          ↓
Cycle still open?
      /         \
    YES          NO
     ↓            ↓
Potentially       Billed /
eligible          closed
```

The same statement-cycle eligibility rule applies to the **destination Credit Card** when the destination is another Credit Card.

## 4. Eligibility Boundary

A Payment Method change from a Credit Card charge is eligible only when **all** applicable conditions are true:

1. The source charge is unbilled according to §3.
2. If the destination is a Credit Card, the charge's effective date also belongs to an open statement cycle for the destination Credit Card.
3. The source charge has no Financing Contract.
4. The charge has no installment relationship that depends on the original Payment Method.
5. The charge has no settled or allocated statement contribution that would be invalidated.
6. The destination account passes all applicable domain guards.
7. The correction does not create an invalid historical or subsequent account state.
8. The operation can be executed atomically.

If any condition fails, the Payment Method change is rejected.

## 5. Statement Boundary Is Primary

The presence of installments is not the only restriction.

The authoritative boundary is whether the charge's effective date belongs to a statement cycle that has crossed its closing boundary.

A charge whose cycle is already closed must not be silently moved to another payment method.

Closed statements remain historical records and must remain immutable.

Therefore:

```text
Effective date in open source cycle
    +
eligible destination cycle
    =
Potentially eligible
```

```text
Effective date in closed source or destination cycle
    =
Direct Payment Method Change Forbidden
```

A future product workflow may support a separate explicit reversal/replacement process for billed charges, subject to statement, payment, allocation, and overpayment rules.

## 6. Financing Boundary

A Credit Card charge with a Financing Contract is not eligible for direct Payment Method change.

This follows ADR-070:

```text
Existing Charge
      +
Financing Contract
      ≠
Second Liability
```

The financing contract depends on the originating charge as its principal source.

Therefore:

```text
Credit Card Charge + Financing
        ↓
Payment Method Change
        ↓
REJECT
```

The financing relationship must never be silently detached or reassigned by this operation.

## 7. Destination Account Guards and Point-in-Time Validation

Payment Method change must validate the **new financial effect**, not only the old one.

Validation is performed against the account state relevant to the transaction's effective date and must also account for subsequent dependent state up to the correction execution point.

### 7.1 Credit Card → Cash / Debit

The destination liquidity account must be evaluated as if the replacement effect had existed from the original transaction date.

The guard must not stop at a single point-in-time balance.

The correction must verify that applying the replacement effect does not create an invalid state at any affected point from:

```text
Transaction Effective Date
        ↓
through correction execution date
```

This includes later transactions whose available balance depends on the corrected history.

### 7.2 Reserved Money / Allocation Interaction

Where Wafferly's Reserved Money / Allocation rules constrain available liquidity, the correction must evaluate the resulting effective available amount, not only raw account balance.

A correction must not silently consume or invalidate reserved allocations.

If the resulting state violates the applicable allocation or reserved-money invariant, the correction is rejected.

### 7.3 Cash / Debit → Credit Card

This direction is outside the primary scope of this ADR.

If a future operation moves an existing cash/debit expense to a Credit Card, it must independently validate the destination Credit Card's credit exposure and statement-cycle eligibility. That operation should be defined explicitly rather than inferred from this ADR.

### 7.4 Credit Card → Credit Card

Both Credit Cards participate in validation.

Each card may have a different:

- credit limit;
- exposure;
- statement cycle;
- statement closing boundary;
- due-date configuration.

Therefore Card → Card is not a simple account substitution.

Both source reversal and destination replacement effects must be valid.

## 8. Liability / Overpayment Boundary

Before reversing the source Credit Card charge, the operation must evaluate the resulting liability state.

If the reversal would cause the source Credit Card liability to become invalid under the applicable overpayment / excess-credit rules, the operation is rejected unless an explicit applicable policy permits the resulting state.

For example:

```text
Charge +700
Payment already made against that card
        ↓
Reverse -700
        ↓
Resulting liability / credit state
        ↓
Must pass ADR-062 and applicable Credit Card invariants
```

The correction must not create an unhandled negative-liability / excess-payment state.

## 9. Correction Semantics and Current Payment Method

Changing Payment Method changes the accounts affected by the economic event. It is therefore a distinct correction type from changing only the amount.

The original transaction and journal effects remain immutable.

The effective current Payment Method is **not a mutable second source of truth**.

Instead:

```text
Original Transaction
        +
Immutable Correction Chain
        ↓
Current Effective Payment Method
```

The read model must derive the current Payment Method from the latest valid correction state associated with the original Transaction ID.

Conceptually:

```text
Original:
Credit Card A
     ↓
Correction 1:
Credit Card A → Credit Card B
     ↓
Correction 2:
Credit Card B → Cash
     ↓
Current effective Payment Method:
Cash
```

Historical corrections remain preserved.

No read model may independently invent or persist a conflicting authoritative Payment Method.

## 10. Correction Chain / Sequential Corrections

Each correction operates on the **latest valid effective state** of the transaction.

Therefore:

```text
A → B
B → C
C → D
```

is evaluated as a correction chain, not as independent edits against the original A state.

A new correction must validate the current effective Payment Method and all current eligibility boundaries before planning the next correction.

A correction must never silently bypass or rewrite an earlier correction.

Amount correction and Payment Method correction remain separate operations, but each must operate against the latest valid financial state.

## 11. Idempotency

Idempotency follows ADR-067, but the idempotency identity for Payment Method Change is the **unique correction request identity**, not merely:

```text
(transactionId + targetAccountId)
```

The correction request must have a stable unique identity.

Conceptually:

```text
CorrectionRequestId
        ↓
Idempotency Key
        ↓
One correction execution
```

Therefore:

```text
A → B
```

with request `R1` and:

```text
A → B
```

with request `R2`

are not automatically duplicates.

Likewise:

```text
A → B
B → A
```

are distinct correction requests and must not collide merely because the same accounts appear in reverse order.

## 12. Atomicity

The entire Payment Method change must execute as one atomic Unit of Work.

```text
BEGIN
  Resolve latest effective state
  Validate source statement eligibility
  Validate destination statement eligibility if applicable
  Validate financing boundary
  Validate point-in-time guards
  Validate liability / overpayment boundary
  Plan reversal
  Plan replacement
  Execute reversal
  Execute replacement
  Persist correction/audit links
COMMIT
```

If any step fails:

```text
ROLLBACK
```

No partial reversal or partial replacement may remain.

The system must never reach a state where:

```text
Old effect reversed
+
New effect missing
```

or:

```text
New effect applied
+
Old effect still active
```

## 13. Historical Immutability

The correction must not mutate:

- original Transaction identity;
- original journal entries;
- closed statement records;
- financing records;
- prior correction records.

New reversal/replacement effects provide the updated financial reality while preserving historical traceability.

## 14. UI Boundary

The normal Edit Transaction screen must not expose the Credit Card account as a freely changeable account selector.

For the MVP:

```text
Edit Credit Card Charge
    ├── Category       ✓
    ├── Amount         ✓
    ├── Date           ✓
    ├── Member         ✓
    ├── Note           ✓
    └── Payment Method 🔒
```

A future explicit action may be introduced:

```text
Change Payment Method
```

The UI must not bypass the Financial Operation Engine.

Until the implementation described in §18 exists, the normal Edit screen must continue rejecting direct Payment Method changes.

## 15. Rejection Behavior

If the charge is not eligible, the operation must fail without modifying financial truth.

Examples:

```text
Source cycle is closed
→ Payment Method Change Not Allowed

Destination Credit Card cycle is closed
→ Payment Method Change Not Allowed

Charge has Financing Contract
→ Payment Method Change Not Allowed

Charge has statement allocation
→ Payment Method Change Not Allowed

Historical/subsequent liquidity guard fails
→ Payment Method Change Not Allowed

Reserved-money/allocation invariant fails
→ Payment Method Change Not Allowed

Source liability would violate overpayment/excess-payment rules
→ Payment Method Change Not Allowed
```

Delete + New is not the default correction mechanism.

## 16. Relationship to Amount Correction

Changing the amount and changing the Payment Method are separate operations.

### Amount correction

```text
Same financial accounts
+
different monetary amount
```

### Payment Method correction

```text
Different financial accounts
+
same economic event
```

The amount-only correction path must not be used for Payment Method changes.

## 17. Required Tests

### Statement / Eligibility

- Unbilled source Credit Card charge can request Payment Method change.
- Source cycle is closed even when no persisted Statement record exists → rejected.
- Destination Credit Card has a closed cycle for the transaction effective date → rejected.
- Charge with Financing Contract → rejected.
- Charge with statement allocation → rejected.
- Charge with settled payment/allocation dependency → rejected.

### Point-in-Time Guards

- Credit Card → Cash validates the liquidity effect from transaction date through correction execution date.
- Credit Card → Debit follows the same historical/subsequent-state rule.
- Later transactions that would become invalid after the correction cause rejection.
- Reserved Money / Allocation constraints are evaluated against the resulting available state.
- Destination guard failure leaves the original financial state unchanged.

### Liability / Overpayment

- Reversal that would create an invalid negative-liability / excess-payment state is rejected unless an explicit policy permits it.
- A prior Credit Card payment is included in the eligibility calculation.

### Correction Chain

- Transaction ID is preserved.
- Original journal entries remain immutable.
- A reversal is created for the old effect.
- A replacement effect is created for the new Payment Method.
- A → B → A is treated as two distinct correction requests.
- A correction after a previous correction operates on the latest valid effective state.
- Read model displays the current Payment Method from the correction chain.
- Historical transaction/correction history remains intact.

### Idempotency

- Same CorrectionRequestId executes at most once.
- Different CorrectionRequestIds are not collapsed merely because transaction/target values match.
- Repeated delivery of the same request produces no duplicate reversal/replacement.

### Atomicity

- Failure before execution changes nothing.
- Failure during planned execution rolls back the entire correction.
- No partial reversal remains.
- No partial replacement remains.

## 18. Implementation Boundary

ADR-071 is an **Accepted architecture decision**, not an implementation request.

Implementation is intentionally deferred until the Generic Financial Engine migration phase specified by the project's implementation plan.

Before enabling the future Payment Method Change UI, implementation must provide:

1. a dedicated Payment Method Correction operation;
2. exact statement-cycle resolution independent of Statement-record materialization;
3. source and destination statement eligibility validation;
4. financing eligibility validation;
5. point-in-time and subsequent-state domain guards;
6. Reserved Money / Allocation compatibility checks;
7. liability / overpayment validation;
8. immutable correction-chain traceability;
9. CorrectionRequestId-based idempotency;
10. atomic reversal + replacement execution;
11. architecture and integration tests.

Until those capabilities exist, the normal Edit Transaction screen must keep the Credit Card account fixed.

## 19. Architectural Invariants

```text
Change Payment Method
    ≠
Change Account Field
```

```text
Unbilled
    =
Transaction Effective Date belongs to an Open Statement Cycle
    and
no applicable closed-statement boundary is crossed
```

```text
Missing Statement Record
    ≠
Proof of Unbilled State
```

```text
Billed / Closed Source or Destination Cycle
    =
Direct Payment Method Change Forbidden
```

```text
Financed Charge
    =
Direct Payment Method Change Forbidden
```

```text
Original Transaction ID
    =
Preserved
```

```text
Original Journal Entries
    =
Immutable
```

```text
Current Payment Method
    =
Derived from the Latest Valid Correction Chain
```

```text
CorrectionRequestId
    =
Idempotency Identity
```

```text
Reversal + Replacement
    =
One Atomic Correction
```

```text
Destination / Liquidity Guards
    =
Evaluate the Effective Historical State
    +
All Affected Subsequent State
```

```text
Statement / Financing / Allocation History
    =
Never Silently Rewritten
```

## 20. Consequence

Wafferly gains a strict separation between:

```text
Editing Transaction Data
        ↓
Normal Edit Flow

Changing Payment Method
        ↓
Dedicated Financial Correction

Changing a Billed / Financed / Allocated Charge
        ↓
Explicit Reversal / Replacement Workflow
        (future capability)
```

This protects:

- Credit Card liability;
- available credit;
- statement history;
- payment allocation;
- financing contracts;
- Reserved Money / Allocations;
- overpayment rules;
- auditability;
- historical financial truth.

The MVP therefore keeps Credit Card Payment Method fixed in the normal Edit screen and does not expose an unsafe direct switch to Cash, Debit, or another Credit Card.
