# ADR-059 — Financing Contract Replacement Policy

**Status:** Proposed → Implementation  
**Date:** 2026-09-27  
**Related:** ADR-052 (Installment / Financing Contract Model), ADR-053 (Interest Calculation and Installment Allocation Model), ADR-054 (Payment Allocation Order), ADR-055 (Multi-Installment Payment Allocation), ADR-056 (Early Settlement / Prepayment Policy), ADR-057 (Late Payment Fee Policy), ADR-058 (Financing Contract Rescheduling / Restructuring Policy)

## 1. Context

A financing arrangement may need to be replaced by a new financing contract.

Contract replacement is materially different from ordinary rescheduling.

Rescheduling preserves the same financing contract identity while changing future terms.

Replacement creates a new financing contract while preserving the complete financial and contractual history of the previous contract.

The system must therefore distinguish:

```text
Contract Rescheduling
    ≠
Contract Replacement
```

and:

```text
Historical Financial Truth
    ≠
Current Financing Contract
```

A replacement must never be implemented by editing the old contract into the new contract.

## 2. Decision

Introduce an explicit **Financing Contract Replacement** domain operation.

The replacement lifecycle is:

```text
Old Financing Contract
        ↓
Replacement Event
        ↓
Old Contract Closed / Replaced
        ↓
New Financing Contract
        ↓
New Future Schedule
        ↓
Future Payments
```

The old contract remains permanently available as historical record.

The new contract becomes the authoritative contract for future obligations after the replacement effective date.

## 3. Replacement vs Rescheduling

### Rescheduling

The same contract continues:

```text
Contract A
   ↓
Contract A — Version 2
```

### Replacement

A new contract is created:

```text
Contract A
   ↓
Replacement Event
   ↓
Contract B
```

Contract A and Contract B retain separate identities.

Contract B must reference Contract A as its predecessor/origin where applicable.

## 4. Replacement Effective Date

Every replacement must have an explicit effective date.

The effective date determines the boundary between:

```text
Historical / Previous Contract
        │
        ↓
Replacement Boundary
        │
        ↓
New Contract
```

The effective date must be explicit and deterministic.

It must not depend on `DateTime.now()`.

## 5. Preservation of Historical Financial Truth

The following records belonging to the old contract must remain immutable:

- financial transactions;
- payments;
- settled principal;
- settled interest;
- assessed fees;
- late fees;
- closed statements;
- historical schedule occurrences;
- audit/traceability records.

Replacement must never:

```text
UPDATE old financial transaction
DELETE old payment
DELETE old statement
REWRITE historical interest
```

Any correction must use the existing correction/invalidation architecture.

## 6. Old Contract State

After a successful replacement, the old contract becomes non-active for future obligations.

The domain should represent an explicit terminal/replaced state such as:

```text
REPLACED
```

or an equivalent state.

The old contract must not continue generating:

- future installments;
- new schedule occurrences;
- new late fees;
- new statements for future periods.

Already assessed historical obligations remain preserved.

## 7. New Contract Identity

The replacement contract receives a new stable contract identity.

It must not reuse the old contract ID.

Conceptually:

```text
Old Contract ID = CONTRACT-A
New Contract ID = CONTRACT-B
```

with:

```text
CONTRACT-B.previousContractId = CONTRACT-A
```

or an equivalent immutable origin reference.

## 8. Replacement Reason

A replacement event should carry an explicit reason/category.

Examples:

```text
Refinancing
Contract amendment requiring a new contract
Product conversion
Lender/product migration
Explicit customer restructuring
System migration
```

The exact allowed values belong to the implementation/domain enum.

The reason must not be inferred from the resulting financial amounts.

## 9. Closing the Old Contract

Replacement must define how the old contract is closed.

The base policy is:

```text
Old Contract
    ↓
Determine remaining contractual obligation
    ↓
Close / replace
    ↓
New Contract assumes explicitly defined future obligation
```

The replacement event must explicitly define what happens to:

- remaining principal;
- future interest;
- outstanding fees;
- assessed late fees;
- unpaid installments;
- future scheduled obligations.

Nothing is implicitly forgiven, transferred, capitalized, or deleted.

## 10. Remaining Principal

The new contract's principal must be derived from an explicit replacement calculation.

Conceptually:

```text
Original Principal
    -
Principal already settled
    ±
Explicit replacement adjustments
    =
Replacement Principal
```

The implementation must not use a UI balance or a cached balance as the authoritative replacement amount.

The calculation must use the effective financial/contractual state defined by the financing architecture.

## 11. Existing Interest

Historical interest remains historical truth.

For future interest:

```text
Old Contract Future Interest
    ≠
Automatically carried forward
```

The new contract must explicitly define its future interest terms.

Any interest already settled remains associated with the old contract.

Unpaid future interest must not be silently treated as settled.

If it is transferred, capitalized, waived, or otherwise transformed, that treatment must be explicit and traceable.

## 12. Existing Fees and Late Fees

Fees and late fees are not automatically erased by replacement.

For each outstanding fee, the replacement policy must explicitly classify it as one of:

```text
Remain payable under old contract
Transferred to new contract
Capitalized into new principal
Waived
Settled before replacement
```

The implementation must record the chosen treatment.

No implicit fee forgiveness is allowed.

## 13. Future Schedule

The old contract's future schedule must be explicitly terminated/superseded.

It must not continue producing future obligations after the replacement boundary.

The new contract receives a new schedule.

The new schedule must be generated according to the new contract's financing terms and ADR-053 calculation/rounding rules.

The new schedule must not reuse old installment identities.

## 14. Installment Identity

Installments belonging to the old contract retain their original identity.

New installments receive new stable identities.

Therefore:

```text
Old Installment ID
    ≠
New Installment ID
```

Even if the new installment has the same amount or due date.

This prevents historical records from being confused with replacement obligations.

## 15. Payment History

Historical payments remain attached to the old contract unless an explicit financial/domain transition states otherwise.

A replacement must not move a historical payment by changing its original record.

If an economic amount is transferred between contracts, that transfer must be represented by an explicit domain/financial operation.

## 16. Statement Interaction

Closed statements generated under the old contract remain immutable.

The new contract starts its own statement lifecycle where applicable.

A replacement must not rewrite a closed statement to make it appear as if it belonged to the new contract.

Future statement projections for the old contract cease after the replacement boundary.

## 17. Late Fees and Delinquency

ADR-057 continues to govern late fees on the old contract up to the replacement boundary.

After replacement:

```text
Old Contract
    ↓
No new delinquency assessment
```

for obligations that have been explicitly terminated by replacement.

If outstanding delinquency is transferred to the new contract, the transfer must be explicit.

The new contract must not inherit delinquency merely because it references the old contract.

## 18. Early Settlement Interaction

A replacement may economically resemble settlement of the old contract, but the architecture must not treat it as an ordinary payment unless an explicit financial settlement operation is created.

If replacement requires the old contract to be settled:

```text
Old Contract Settlement
        ↓
Explicit Financial Operation
        ↓
New Contract Creation
```

The settlement amount must be determined according to the applicable contract/replacement policy.

ADR-056 remains applicable where the old contract is actually settled early.

## 19. Financial Effect

Contract replacement itself is not automatically a financial transaction.

It becomes financially material only when the replacement requires an actual movement or recognition of money.

Examples:

```text
Settlement payment
Refinancing disbursement
Fee
Adjustment
Principal transfer
```

Any actual financial effect must pass through the Financial Operation Engine.

The replacement service must not directly mutate:

```text
Account
Transaction
Ledger
Balance
Hive
```

## 20. Single Writer Boundary

The replacement workflow must respect existing writer boundaries.

Conceptually:

```text
Replacement Policy
        ↓
Replacement Plan
        ↓
Contract / Schedule Transition
        │
        └── Financial Effect?
                  ↓
          FinancialOperationEngine
```

No replacement service may become a hidden financial writer.

## 21. Atomicity

If replacement includes financial settlement plus contract transition, the operation must be recoverable.

A failure must not produce:

```text
Old contract closed
+
New contract missing
```

or:

```text
Financial settlement succeeded
+
Retry creates second settlement
```

The replacement workflow therefore requires:

- stable replacement operation identity;
- durable idempotency;
- explicit transition state;
- recoverable execution;
- no duplicate financial mutation.

## 22. Replacement State Machine

The replacement workflow should use explicit durable states.

Conceptually:

```text
REQUESTED
    ↓
VALIDATED
    ↓
FINANCIAL_EFFECT_PENDING
    ↓
FINANCIAL_EFFECT_SUCCEEDED
    ↓
OLD_CONTRACT_CLOSED
    ↓
NEW_CONTRACT_CREATED
    ↓
NEW_SCHEDULE_CREATED
    ↓
COMPLETED
```

Failure must be represented explicitly rather than inferred from missing records.

The exact persisted state model may be implemented according to the existing scheduling/journal architecture.

## 23. Idempotency

A replacement operation must have a stable idempotency key.

Repeated execution of the same replacement request must not create:

- a second new contract;
- duplicate installments;
- duplicate schedule occurrences;
- duplicate settlement;
- duplicate fees;
- duplicate traceability events.

A retry after financial success must resume from the durable replacement state.

## 24. Traceability

The replacement event must preserve a complete relationship:

```text
Old Contract
      ↓
Replacement Event
      ↓
New Contract
```

Traceability should include:

- old contract ID;
- new contract ID;
- effective date;
- replacement reason;
- remaining obligation calculation;
- fee treatment;
- interest treatment;
- schedule transition;
- financial operation IDs where applicable.

Traceability is audit/history data and is not itself financial truth.

## 25. Money Semantics

All replacement calculations must remain `Money`-native within Domain/Planning.

The following must not use `double` arithmetic:

- remaining principal;
- interest;
- fees;
- settlement amount;
- transferred amount;
- replacement schedule amounts.

Legacy conversion is allowed only at approved compatibility/persistence boundaries.

## 26. No Silent Obligation Transfer

The new contract must never automatically inherit every obligation of the old contract.

Each category must have an explicit treatment:

```text
Principal
Interest
Fees
Late Fees
Future Installments
Statements
```

This is required to prevent accidental duplication or forgiveness.

## 27. Required Tests

### Basic replacement

```text
Contract A
    ↓ replacement
Contract B
```

Both identities remain distinct.

### Historical immutability

All historical financial records of Contract A remain unchanged.

### Old contract closure

Contract A becomes replaced/inactive and produces no future obligations.

### New contract identity

Contract B has a new stable ID and references Contract A.

### Schedule replacement

Old future installments are superseded/cancelled and new installments receive new IDs.

### Principal calculation

Replacement principal matches the explicit remaining-obligation calculation.

### Interest treatment

Historical interest remains unchanged and future interest follows Contract B terms.

### Fee treatment

Every outstanding fee receives an explicit treatment.

### Late-fee treatment

No new old-contract late fee is generated after the replacement boundary.

### Statement preservation

Closed old statements remain unchanged.

### Payment preservation

Historical payments are not moved or rewritten.

### Financial settlement

If replacement requires settlement, it uses the Financial Operation Engine.

### Idempotency

Retrying the replacement creates no duplicate contract, schedule, or financial effect.

### Atomic recovery

Failure after financial success can resume without duplicate financial mutation.

### No direct persistence mutation

Replacement calculation/service cannot directly write Account, Transaction, Ledger, Balance, or Hive.

### Money boundary

All financial calculations remain `Money`-native.

## 28. Architectural Invariants

The following are mandatory:

```text
Old Contract ID
    ≠
New Contract ID
```

```text
Old Installment ID
    ≠
New Installment ID
```

```text
Historical Financial Truth
    = immutable
```

```text
Replacement
    ≠
Historical Mutation
```

```text
Contract Replacement
    ≠
Financial Transaction
```

and:

```text
Actual Financial Effect
        ↓
FinancialOperationEngine
```

## 29. Non-Goals

This ADR does not define:

- refinancing interest rates;
- lender/product eligibility;
- credit underwriting;
- legal/regulatory requirements;
- payment allocation;
- interest calculation itself;
- late-fee calculation itself;
- early-settlement economics;
- statement generation;
- collections workflows;
- tax treatment.

Those remain governed by existing ADRs or require separate decisions.

## 30. Consequence

The financing architecture can replace a financing contract without destroying its historical record.

The resulting model is:

```text
Contract A
   │
   ├── Historical Payments
   ├── Historical Interest
   ├── Historical Fees
   ├── Historical Statements
   └── Historical Schedule
            │
            ▼
     Replacement Event
            │
            ▼
        Contract B
            │
            ├── New Terms
            ├── New Schedule
            └── Future Payments
```

This preserves financial history while making the new contract authoritative for future obligations.

## 31. Implementation Boundary

Implementation should begin with a pure `FinancingContractReplacementCalculator` / equivalent domain service that:

1. receives the old effective contract;
2. receives the explicit replacement effective date;
3. receives the effective remaining obligation;
4. receives explicit treatment rules for principal, interest, fees, and delinquency;
5. calculates the replacement contract terms;
6. produces a replacement transition plan;
7. produces the new future schedule;
8. produces explicit financial-effect intents where required;
9. performs no persistence or direct financial mutation.

Only after the pure replacement tests pass should the workflow be integrated with persistent contract/schedule state and the Financial Operation Engine.

No independent replacement balance or shadow financial ledger should be introduced.
