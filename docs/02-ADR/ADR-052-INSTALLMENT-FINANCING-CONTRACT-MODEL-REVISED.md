# ADR-052 — Installment / Financing Contract Model

**Status:** Proposed → Implementation  
**Date:** 2026-09-27  
**Related:** ADR-032 (Debt Domain Architecture), ADR-035 (Credit Card Domain), ADR-047 (Credit Card Charge Operation), ADR-050 (Credit Card Statement Lifecycle & Due-Date Generation), ADR-051 (Credit Card Payment / Settlement Operation)

## 1. Context

Installments introduce a distinction between the financial liability itself and the agreement that describes how that liability is expected to be settled over time.

The existing architecture establishes:

```text
Account
    = financial position / balance truth

Transaction
    = actual money movement

Commitment
    = future expected payment

ScheduleRule
    = timing rule

ScheduleOccurrence
    = concrete scheduled event
```

A financing arrangement must not introduce a second balance system merely because it has installments.

The installment contract therefore describes the financing terms and expected repayment structure, while actual financial effects continue to be created through the Financial Operation Engine.

## 2. Decision

Introduce an explicit **Installment / Financing Contract** domain model for a financing plan that divides an obligation into scheduled installments.

The contract is planning/domain metadata. It is not itself the financial balance.

Conceptually:

```text
InstallmentFinancingContract
    ├── contractId
    ├── liabilityAccountId
    ├── originReference
    ├── principal
    ├── installmentCount
    ├── paymentFrequency / recurrenceRule
    ├── firstDueDate
    ├── interest / financing policy reference
    ├── contract lifecycle state
    └── traceability / transition metadata
```

### Canonical Contract Schema Boundary

The first implementation uses the following canonical interpretation:

- `contractId` is the stable identity of the financing agreement.
- `liabilityAccountId` identifies the authoritative financial liability account.
- `originReference` links the contract to the originating financial event/agreement when one exists.
- `principal` is the canonical amortizing contractual principal. It is the amount that the generated schedule must reconcile back to through its principal components.
- `financedAmount` is **not** a second authoritative monetary field in the first implementation. If a future product genuinely distinguishes an amount funded/disbursed from contractual principal, that distinction requires an explicit domain policy rather than storing two synonymous values.
- `installmentCount`, `paymentFrequency` / `recurrenceRule`, and `firstDueDate` are structured repayment terms.
- `installmentAmount` is **not** an authoritative contract-level balance/term in the first implementation. For an amortizing plan it is calculated per scheduled installment from principal, interest, and applicable fees according to ADR-053. A scheduled installment may persist its calculated amount as part of that installment's expected obligation.
- `repaymentTerms` is therefore a conceptual grouping, not an opaque serialized field. Its implementation must expose the individual terms required by the schedule and calculation policies.
- Interest-rate, calculation-method, rounding, and related financing terms are owned by the explicit financing/interest policy defined by ADR-053 rather than hidden inside `repaymentTerms`.

The contract must not persist duplicate values merely because they can be derived from the schedule. The contract stores the terms needed to deterministically generate the schedule; the schedule stores the resulting expected installment obligations.

## 3. Two Different Financing Concepts

The architecture must distinguish:

### A. Reusable Installment Facility

A reusable financing facility is an account-level capability that may support multiple financing plans over time.

```text
Reusable Facility
    │
    ├── Plan A
    ├── Plan B
    └── Plan C
```

The facility remains associated with the relevant liability account and its domain configuration.

### B. Single Installment Plan

A single installment plan represents one concrete financing arrangement.

```text
Single Installment Plan
        │
        ├── Principal / financed amount
        ├── installment count
        ├── repayment terms
        └── scheduled installments
```

A single plan must have its own stable identity.

These concepts must not be collapsed into one object merely because both involve installments.

## 4. Contract Is Not Financial Truth

The installment contract must not own an independent:

```text
balance
outstandingBalance
availableCredit
paidAmount
```

as a competing financial source of truth.

The authoritative current liability remains derived from the Account and effective financial transactions.

Conceptually:

```text
Installment Contract
        │
        │ defines expected repayment
        ▼
Commitments / Schedule
        │
        ▼
Actual Payment
        │
        ▼
Financial Operation Engine
        │
        ▼
Liability Account / Transactions
```

If a read model needs values such as remaining principal or paid installments, they must be derived from authoritative financial state and/or explicitly defined contract state rather than becoming a second financial ledger.

## 5. Origin of an Installment Plan

An installment plan must identify the financial event or agreement from which it originated.

For a Credit Card use case, the plan may be associated with the relevant card/account and originating charge or financing action.

The origin reference is traceability/domain linkage. It does not replace the actual financial transaction.

The implementation must preserve enough identity to prevent the same source charge or financing instruction from creating duplicate plans.

## 6. Financial Effect

Creating an installment contract is not automatically equivalent to creating a payment.

The architecture must distinguish:

```text
Contract creation
    ≠
Financial settlement
```

Where a financing conversion creates or changes financial liability, the resulting financial mutation must pass through the Financial Operation Engine.

The contract itself must never directly write:

```text
Hive
Account
Transaction
Ledger
Balance
```

## 7. Installment Schedule

An installment contract defines the expected repayment sequence.

Conceptually:

```text
Contract
    ↓
Installment 1
Installment 2
Installment 3
...
Installment N
```

Each concrete installment may be represented through the existing Commitment / ScheduleOccurrence architecture rather than introducing an independent scheduling subsystem.

The schedule must have stable occurrence identity.

Repeated evaluation or execution must not create duplicate installments.

## 8. Date Semantics

Installment due dates must use the established scheduled-money date contract.

Monthly recurrence must reuse ADR-046:

```text
original anchor
    ↓
target month
    ↓
explicit valid day
    ↓
clamp when necessary
```

End-of-month anchors remain end-of-month.

Dart `DateTime` overflow must not define installment business semantics.

## 9. Money Semantics

All financial amounts inside the domain/planning boundary must remain `Money`-native.

Relevant values include:

```text
principal
financedAmount
installmentAmount
fees
```

where those values are part of the actual domain contract.

Legacy `double` representations may only be used at already-approved persistence/application compatibility boundaries.

No installment planner or domain guard may convert `Money` to `double` merely to satisfy a legacy type.

## 10. Payment Relationship

An installment becoming due does not itself constitute a completed payment.

The lifecycle is:

```text
Installment Due
      ↓
Commitment / ScheduleOccurrence
      ↓
Payment Operation
      ↓
Financial Truth
```

For a Credit Card financing plan:

```text
Installment
    ≠
CreditCardPaymentOperation
```

The payment operation defined by ADR-051 remains the actual financial settlement path.

## 11. Early Payment / Partial Payment

The first contract must distinguish expected installment amount from actual payment.

Therefore:

```text
Expected Installment
    ≠
Actual Payment
```

A partial or early payment must not silently rewrite the original installment contract.

Any future policy for:

- partial installment payment;
- early settlement;
- prepayment;
- installment restructuring;
- cancellation;

must be explicitly defined before implementation changes the contract semantics.

## 12. Fees, Interest and Financing Cost

This ADR does not define a universal interest or fee calculation engine.

If financing cost exists, it must have an explicit domain representation and financial effect.

It must not be hidden inside an arbitrary installment amount without preserving the contract semantics required by the product.

Interest, fees, grace periods, and other financing calculations require their own policy/implementation contracts where necessary.

## 13. Contract State

The contract lifecycle must distinguish agreement lifecycle from both financial transaction state and delinquency state.

The canonical lifecycle follows the decisions established by ADR-060 and ADR-061:

```text
DRAFT
  ↓
ACTIVE
  ↓
SETTLED
  ↓
CLOSED
```

With explicit terminal/exception transitions where applicable:

```text
DRAFT → CANCELLED
ACTIVE → TERMINATED
ACTIVE → REPLACED
```

`SETTLED` means the applicable contractual financial obligations have been resolved. `CLOSED` is the subsequent administrative terminal state and creates no new financial effect.

Delinquency is a separate dimension governed by ADR-064:

```text
CURRENT
DELINQUENT
DEFAULTED
```

It must not be encoded as a Contract lifecycle state. Likewise, installment status is a separate dimension for individual scheduled obligations.

The contract must never use a lifecycle transition to delete or rewrite immutable financial history.

## 22. Contract vs Schedule vs Installment State Boundary

The following ownership is mandatory:

```text
Contract
    ↓
financing terms + lifecycle + linkage

Schedule / Installment
    ↓
due dates + expected principal/interest/fee components
+ scheduled installment amount

Financial Operation Engine
    ↓
actual payment / actual financial effect

Financial Truth
    ↓
Account + effective financial transactions
```

Accordingly:

- Contract terms are structured and deterministic.
- Scheduled installment amounts are schedule-level expected obligations.
- Actual paid amounts are derived from effective financial state and payment/allocation history; they are not a competing contract balance.
- Contract lifecycle, contract delinquency, and installment status are separate state dimensions.

This boundary is a domain architecture decision, not a requirement that every product or database use identical field names.

## 22. Idempotency

Creating or activating an installment contract must be idempotent where the operation can be retried.

A retry of the same financing instruction must not create:

```text
duplicate contract
duplicate schedule
duplicate occurrence
duplicate financial transaction
```

Financial mutation continues to use the existing Financial Engine idempotency mechanism.

Scheduled execution continues to use the durable recovery contract established for scheduled financial actions.

## 22. Traceability

The contract and its financial operations should preserve linkage between:

```text
Financing Contract
        ↓
Originating Operation / Transaction
        ↓
Commitment / Schedule
        ↓
Schedule Occurrence
        ↓
Payment Operation
        ↓
Resulting Transaction
```

The existing Traceability boundary remains audit/history infrastructure and must not become a financial source of truth.

## 22. Credit Card Interaction

For Credit Cards, an installment plan is a domain layer on top of the existing card architecture:

```text
CreditCardProfile
        │
        ▼
Credit Card Liability Account
        │
        ▼
Originating Charge / Financing Event
        │
        ▼
Installment Contract
        │
        ▼
Commitments / ScheduleOccurrences
        │
        ▼
CreditCardPaymentOperation
        │
        ▼
Financial Truth
```

The contract must not replace:

- CreditCardProfile;
- Liability Account;
- FinancialOperationEngine;
- Statement lifecycle;
- Payment operation.

## 22. Non-Goals

This ADR does not define:

- interest-rate calculation;
- APR;
- late fees;
- minimum payment;
- grace periods;
- statement generation;
- statement closing;
- refund/reversal behavior;
- automatic payment execution;
- early-settlement economics;
- installment restructuring;
- merchant-side installment conversion rules;
- currency conversion policy.

These require separate contracts where needed.

## 22. Required Tests

The implementation gate must cover:

### Contract creation

```text
valid financing terms
→ one stable contract
```

### Duplicate creation

```text
same financing instruction twice
→ one contract
```

### Schedule generation

```text
contract
→ deterministic installment occurrences
```

### Monthly EOM

```text
Jan 31 anchor
→ Feb 28
→ Mar 31
```

and leap-year behavior according to ADR-046.

### Contract / financial truth separation

```text
contract state
≠
liability balance source
```

### Payment separation

```text
installment due
≠
payment completed
```

### Payment mutation

Actual payment must pass through the Financial Operation Engine.

### Idempotent payment

```text
same payment operation twice
→ one financial mutation
```

### Cancellation / completion

Contract state changes must not delete or mutate immutable financial history.

## 22. Architectural Invariants

The following are mandatory:

```text
Installment Contract
    ≠
Liability Balance
```

```text
Installment
    ≠
Payment
```

```text
Commitment
    ≠
Transaction
```

```text
ScheduleOccurrence
    ≠
Financial Transaction
```

And:

```text
Actual financial effect
        ↓
FinancialOperationEngine
```

The installment feature must not introduce a second financial writer.

## 22. Consequence

This establishes installments as an explicit financing contract while preserving the existing financial architecture.

The system gains a clear separation between:

```text
Financing Terms
        ↓
Expected Repayment Schedule
        ↓
Actual Payment
        ↓
Financial Truth
```

This allows future work on interest, early settlement, restructuring, and more advanced financing rules without contaminating the Account/Transaction source-of-truth model.

## 22. Implementation Boundary

Implementation should begin with:

1. `InstallmentFinancingContract` domain model;
2. stable contract identity;
3. explicit contract-to-account linkage;
4. contract-to-origin linkage;
5. deterministic installment schedule generation;
6. integration with existing Commitment / ScheduleOccurrence infrastructure;
7. idempotent payment linkage.

No independent installment balance ledger should be introduced.
