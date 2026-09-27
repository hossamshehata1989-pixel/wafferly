# ADR-070 — Credit Card Financing Conversion Boundary

**Status:** Proposed → Implementation  
**Date:** 2026-09-27  
**Related:** ADR-047 (Credit Card Charge Operation), ADR-049 (Credit Limit Domain Guard), ADR-050 (Credit Card Statement Lifecycle & Due-Date Generation), ADR-051 (Credit Card Payment / Settlement Operation), ADR-052 (Installment / Financing Contract Model), ADR-053 (Interest Calculation and Installment Allocation Model), ADR-059 (Financing Contract Replacement Policy), ADR-066 (Financing Financial Effects Boundary), ADR-067 (Financing Operation Idempotency), ADR-068 (Financing Audit / Traceability Boundary), ADR-069 (Credit Card Statement ↔ Installment Relationship)

## 1. Context

A Credit Card purchase may already have been posted as a financial charge before the user requests installment financing.

ADR-047 establishes that the original charge creates the authoritative Credit Card liability through the Financial Operation Engine.

ADR-052 establishes that an Installment Financing Contract is contractual/planning state and is not a second balance source of truth.

ADR-069 establishes that statement presentation for financed purchases is based on scheduled installment eligibility and must not double-count the originating liability.

The missing boundary is therefore the conversion of an **already-posted Credit Card charge** into an installment plan.

The critical invariant is:

```text
Existing Charge
    +
Installment Contract
    ≠
Second Liability
```

## 2. Decision

For the first implementation, **conversion of an already-posted Credit Card charge into an installment plan is a financing-domain operation, not a new financial transaction**.

The conversion:

1. validates the originating charge;
2. establishes the financing contract;
3. generates the contractual installment schedule;
4. establishes the originating-charge ↔ financing-contract relationship;
5. establishes the statement/installment eligibility boundary;
6. records traceability and stable conversion identity.

It does **not**, by itself:

- create another liability transaction for the principal;
- reverse the original charge;
- create a second principal liability;
- create a payment;
- create a cash movement;
- mutate the historical charge;
- rewrite a closed statement.

Conceptually:

```text
Posted Credit Card Charge
        │
        │ remains authoritative financial truth
        ▼
Existing Liability
        │
        ├───────────────┐
        │               │
        ▼               ▼
Origin Reference   Financing Conversion
                        │
                        ▼
                Financing Contract
                        │
                        ▼
                Installment Schedule
                        │
                        ▼
              Statement Eligibility
```

## 3. No New Principal Liability

The original posted charge already established the financial liability.

Therefore conversion must not execute:

```text
Original Charge:        +P liability
Conversion:             +P liability
--------------------------------------
Result:                 +2P liability   ❌
```

The correct MVP behavior is:

```text
Original Charge:        +P liability
Conversion:              0 new principal liability
-----------------------------------------------
Result:                 +P liability      ✓
```

The installment contract describes how the existing obligation is expected to be repaid.

Any future financial effect that genuinely changes the liability must be represented by a separate Financial Operation governed by the applicable ADR.

## 4. Original Charge Immutability

The originating charge remains historical financial truth.

Conversion must not:

```text
UPDATE original Transaction
DELETE original Transaction
change original amount
change original account
rewrite original date
rewrite historical financial effect
```

If a future product requires actual reversal and replacement of the original financial obligation, that is a separate financial workflow and must use the existing correction/reversal/financial-operation architecture.

Conversion alone is not that workflow.

## 5. Principal Source

For an already-posted charge conversion, the MVP contractual principal is derived from the explicit originating financial event selected for conversion.

The implementation must establish a deterministic source reference:

```text
originReference
    =
originating charge identity
```

The resulting contract stores:

```text
contractId
liabilityAccountId
originReference
principal
repayment terms
interest / financing policy
lifecycle / traceability state
```

The implementation must not derive principal from:

```text
current account balance
current statement balance
available credit
cached UI balance
```

The originating charge is the conversion source.

## 6. Conversion Eligibility

The conversion operation must validate, at minimum:

- originating charge exists;
- originating charge is a Credit Card charge;
- originating charge belongs to the target Credit Card liability account;
- originating charge has a positive amount;
- originating charge has not already been converted into an active financing plan;
- requested financing terms are valid;
- the conversion identity has not already been completed.

The exact product eligibility rules remain implementation-specific unless separately defined by a future ADR.

## 7. Statement Boundary

Statement behavior follows ADR-069.

### Conversion before statement close

If the conversion occurs before the relevant statement closes, the statement read/projection layer must not count both:

```text
Original full charge
+
Scheduled installment contribution
```

for the same economic obligation.

The statement representation must use the financing boundary to determine the eligible installment contribution.

### Conversion after statement close

A previously closed statement remains immutable.

Therefore:

```text
Closed Statement
    = historical truth for that closed period
```

A later conversion must not rewrite it.

Future statement cycles use the installment eligibility established by the conversion.

This means a conversion may legitimately produce:

```text
Previous closed statement
    → original charge remains

Future statement
    → eligible installment contribution
```

without changing the authoritative liability account.

## 8. Interest and Financing Fees

Conversion does not immediately create financial liability for future interest merely because the schedule contains calculated interest.

ADR-053 remains authoritative for calculating expected interest.

Conceptually:

```text
Contract
    ↓
Interest Calculation
    ↓
Scheduled Interest
    ↓
Statement Eligibility
    ↓
Actual Financial Effect
```

Any actual recognition/payment/financial effect of interest or fees must use the applicable financial operation boundary.

The conversion operation must not silently post the entire future interest amount as a new liability.

## 9. Statement Contribution Is Not Financial Mutation

A statement contribution created from an installment is a periodic presentation/read-model relationship.

It must not be implemented by creating:

```text
Transaction
Account mutation
Ledger entry
Balance mutation
```

The authoritative liability remains the original financial transaction plus subsequent effective financial operations.

## 10. Idempotency

The conversion has its own logical financing operation identity, while financial mutation idempotency remains owned by the Financial Engine as required by ADR-067.

A stable conversion identity should include the logical source and conversion instruction, for example:

```text
conversionId
    =
stable identity of the conversion request
```

The same conversion request must not create:

```text
second contract
second schedule
second installment set
second statement relationship
```

If the workflow is retried after partial persistence, recovery must resume from durable conversion state rather than creating another financing plan.

## 11. Traceability

The conversion must preserve:

```text
Originating Charge
        ↓
Conversion Operation
        ↓
Financing Contract
        ↓
Installment Schedule
        ↓
Statement Relationship
        ↓
Future Payment Operations
```

At minimum, the relationship must make it possible to answer:

- which charge created this financing plan?
- which contract was created?
- which conversion request created it?
- which installments belong to the contract?
- which statement contribution belongs to each installment?
- which payment operation settled the liability?

Traceability remains explanatory/history data and is not a financial source of truth.

## 12. Writer Boundary

The conversion domain service may write its own financing persistence:

```text
Contract
Schedule
Installment
Conversion Event / Traceability
Statement relationship state
```

It must not directly write:

```text
Account
Transaction
Ledger
Financial Balance
Financial Idempotency Store
```

If an actual financial effect is required, the conversion produces/requests the appropriate Financial Operation and the Financial Operation Engine performs the financial mutation.

## 13. Conversion vs Replacement

Conversion of a posted charge is not automatically financing contract replacement.

```text
Posted Charge
    ↓
Installment Conversion
```

is a new financing relationship around an existing financial event.

By contrast:

```text
Contract A
    ↓
Replacement
    ↓
Contract B
```

is governed by ADR-059 and creates a new contract identity while preserving historical contract state.

These workflows must not be collapsed.

## 14. Required Tests

### Existing liability is unchanged

```text
Charge = P
Conversion
→ liability remains P
```

No second principal transaction is created.

### Contract creation

```text
Charge
→ one financing contract
→ originReference points to charge
```

### Schedule creation

```text
one conversion
→ one deterministic installment set
```

### Duplicate conversion rejection/idempotency

```text
same conversion twice
→ one contract
→ one schedule
→ one installment set
```

### Existing charge cannot be converted twice

A charge already linked to an active financing conversion must not silently create another plan.

### Closed statement preservation

```text
closed statement
→ conversion later
→ closed statement unchanged
```

### Current/future statement boundary

The statement projection must not count both the original full charge and the corresponding installment contribution for the same period/economic obligation.

### Future interest

Future scheduled interest must not be posted as an immediate full liability merely because it exists in the financing schedule.

### Writer boundary

Conversion code cannot directly mutate Account, Transaction, Ledger, Balance, or Financial Engine idempotency storage.

## 15. Architectural Invariants

```text
Original Charge
    = financial truth
```

```text
Financing Contract
    = repayment structure
```

```text
Conversion
    ≠
New Principal Liability
```

```text
Conversion
    ≠
Payment
```

```text
Conversion
    ≠
Historical Mutation
```

```text
Statement Contribution
    ≠
Financial Transaction
```

```text
Actual Financial Effect
        ↓
FinancialOperationEngine
```

## 16. Consequence

The MVP can support installment conversion without creating a second liability ledger.

The resulting architecture is:

```text
                    Original Charge
                          │
                          ▼
                  Liability Account
                    (financial truth)
                          │
                          │ originReference
                          ▼
                Financing Conversion
                          │
                          ▼
                 Financing Contract
                          │
                          ▼
                 Installment Schedule
                          │
                          ▼
               Statement Contribution
                          │
                          ▼
                   Future Payment
                          │
                          ▼
                Financial Operation Engine
```

The key rule is:

> Converting an existing Credit Card charge into installments changes the contractual repayment structure and statement presentation boundary; it does not recreate the principal liability.
