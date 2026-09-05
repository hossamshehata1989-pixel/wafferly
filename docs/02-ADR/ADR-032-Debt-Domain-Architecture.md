# ADR-032 — Debt Domain Architecture

**Status:** Accepted  
**Date:** 2026-09-05

## Related ADRs

- ADR-007 — Financial Engine is the only writer of Financial Truth
- ADR-021 — Financial Truth Boundary & Opening Balance Modeling
- ADR-031 — Money Reservation Architecture
- ADR-011 — Debt Domain (Master Rules baseline)

---

# Context

Wafferly needs a Debt Domain that supports several user-facing debt concepts:

- Credit Cards
- Loans
- Reusable Installment Facilities
- Single Installment Plans
- Borrowed Money
- Temporary Debt
- Rotating Savings / Saving Circle liabilities after actual receipt

These concepts have different workflows, but they must not create competing financial sources of truth.

The application also exposes both **Accounts** and **Manage** screens. Without an explicit boundary, debt logic can easily become duplicated between the two screens, resulting in:

- duplicated debt balances;
- duplicate CRUD flows;
- financial mutations bypassing the canonical execution pipeline;
- confusion about whether a debt is an Account, a Commitment, or a workflow object;
- inconsistent status such as Overdue / Due Soon / Upcoming;
- inconsistent treatment of installment facilities versus one-off installment plans.

The architecture therefore needs one explicit ownership decision for the Debt Domain.

---

# Decision

Wafferly will use a **single financial source of truth** for debts while allowing Accounts and Manage to have different responsibilities.

The architectural boundary is:

```text
Accounts
    ↓
Financial Position / Liability Representation

Manage
    ↓
Debt Workflow / Operational UX

Financial Operation Execution Engine
    ↓
Transaction
    ↓
Ledger
    ↓
Balance / Financial Truth
```

**Accounts owns financial position. Manage owns debt workflow. Neither screen owns an independent debt balance.**

---

# 1. Accounts Responsibility

Accounts is responsible for the user's structural financial network and current financial position.

## Real operational accounts

Examples include:

- Bank Accounts
- Cash Accounts
- Credit Cards
- Reusable Installment Facilities
- Other approved operational financial facilities

Where a debt concept requires an actual financial position, it is represented internally through the approved **Liability Account** model.

Examples include:

- Loan liability
- Borrowed Money liability
- Temporary Debt liability
- Saving Circle liability after actual receipt

Accounts may present these liabilities as grouped, summarized, or navigational representations.

The presentation must not create another balance source.

---

# 2. Manage Responsibility

Manage is the primary UX/workflow owner for debt operations.

Manage may provide workflows for:

- Adding and managing Loans
- Adding and managing Borrowed Money
- Adding and managing Temporary Debt
- Entering Credit Card transactions
- Creating and managing installment operations
- Managing Reusable Installment Facilities
- Managing Single Installment Plans
- Handling approved Saving Circle / Rotating Savings workflows
- Settling or repaying debt through approved financial operations

Manage is **not** a second financial engine.

Manage must not maintain a separate authoritative debt balance.

Any displayed debt amount must ultimately be derived from the approved financial/domain sources.

---

# 3. Accounts ↔ Manage Navigation Boundary

Debt items displayed in Accounts may be:

- real liability Accounts;
- rollups;
- grouped representations;
- navigational display items.

A display/rollup item is still expected to be **navigable** when the underlying concept has an approved workflow.

Selecting the item must lead to the existing underlying details/workflow rather than introducing a second implementation.

The same debt concept must therefore not have:

```text
Accounts CRUD
        +
Manage CRUD
```

when both operate on the same financial/domain truth.

Instead:

```text
Accounts
  → position / navigation

Manage
  → workflow

Shared domain/application services
  → actual behavior
```

---

# 4. Accounts Add Boundary

The `+ Add` action in Accounts is for creating approved operational financial accounts/facilities.

It must not expose duplicate generic Account-creation paths for workflow-owned debt concepts such as:

- Loans
- Borrowed Money
- Temporary Debt

Those concepts are entered through their approved Manage workflows.

Credit Cards and Reusable Installment Facilities may remain valid Account creation targets because they are continuing financial facilities and may represent actual liability Accounts.

---

# 5. Debt Financial Source of Truth

Debt workflows must never create an independent balance store.

The authoritative chain remains:

```text
Approved Financial Operation
        ↓
Financial Operation Execution Engine
        ↓
Transaction
        ↓
Ledger
        ↓
Balance / Financial Position
```

A debt UI may calculate presentation state, totals, or categories, but it must not become the owner of financial truth.

In particular, the following are prohibited as independent debt truth:

- `DebtBalance`
- `ManageDebtBalance`
- screen-local authoritative outstanding amount
- duplicated liability totals stored outside the financial model

unless a future ADR explicitly establishes a derived/read-model purpose rather than a second source of truth.

---

# 6. Credit Card and Installment Financial Operations

Entering a Credit Card transaction or creating an installment operation through Manage is a workflow action, not a separate accounting mechanism.

When the operation represents an actual financial movement, it must pass through the canonical financial execution boundary and produce the authoritative Transaction/Ledger records according to the existing financial architecture.

The UI must not directly mutate balances or Ledger records.

Future payment expectations remain distinct from executed movements.

```text
Future payment expectation
        → Commitment / Schedule

Actual payment / settlement
        → Financial Operation
        → Transaction / Ledger
```

---

# 7. Installment Classification

Installments are classified by **business concept**, not solely by whether a limit exists.

## Reusable Installment Facility

A continuing facility that can support multiple financed operations.

A facility may have:

- a credit/financing limit;
- remaining availability;
- repeated financed operations;
- ongoing liability position.

The presence of a limit is a property of the facility, not the definition by itself.

## Single Installment Plan

A one-off financed obligation created for a specific purchase or obligation.

It does not become a reusable facility merely because the plan has a defined amount, installments, or remaining balance.

This distinction must remain visible in the domain/workflow model even if both concepts ultimately use liability Accounts and Commitments.

---

# 8. Future Payment Status

Debt status such as:

- Overdue
- Due Soon
- Upcoming

is **derived state**.

It must not be hardcoded into the UI or maintained as an unrelated screen-owned financial truth.

The status must be derived from the approved future-payment domain information, such as applicable Commitments, Schedule Rules, Schedule Occurrences, due dates, and settlement state.

The exact implementation/service boundary must be verified against the existing runtime architecture before introducing a new service.

---

# 9. Rotating Savings / Saving Circle Lifecycle

A Rotating Savings / Saving Circle has a specific financial-state boundary.

Before the payout is actually received:

```text
Expected payout
      ↓
Future entitlement / expected receivable
```

The expected payout does **not** automatically create an active liability merely because the expected date has arrived.

The application should inform the user that the payout is due and require the appropriate confirmation of actual receipt.

After the user confirms actual receipt:

```text
Actual receipt confirmed
        ↓
Approved financial operation
        ↓
Actual financial records
        ↓
Active liability position
```

This prevents an expected future event from being confused with an executed financial event.

The date alone is not sufficient to mutate the financial truth.

---

# 10. Commitments and Schedules

Debt schedules describe future expectations and timing.

They do not replace Transactions.

The ownership remains:

```text
Liability Account
    → current financial position

Commitment
    → future financial event meaning

ScheduleRule
    → timing rule

ScheduleOccurrence
    → concrete due instance

Transaction
    → actual executed movement

Ledger
    → accounting history
```

A scheduled debt payment must not be represented as an executed Transaction until the approved execution policy actually executes it.

---

# 11. Debt UI Read Model Principle

The Debts screen may aggregate information from multiple authoritative sources to produce a user-friendly overview.

For example:

```text
Total Outstanding
Overdue
Due Soon
Upcoming

Loans
Credit Cards
Installment Companies / Facilities
Borrowed Money
Temporary Debt
Rotating Savings
```

These are presentation/read concerns.

The screen must not create a second domain model merely to make the dashboard convenient.

Where a new projection/read model is required, its ownership and contract must be established through the existing architecture and verified before implementation.

---

# 12. No Duplicate Financial Mutation Paths

The following architectural pattern is prohibited:

```text
Manage
   ↓
Direct Account Balance Mutation
```

or:

```text
Manage
   ↓
Direct Ledger Mutation
```

or:

```text
DebtsScreen
   ↓
Local Debt Balance Store
```

The approved pattern is:

```text
UI
 ↓
Controller / ViewModel
 ↓
Service / Use Case
 ↓
Financial Operation Execution Engine
 ↓
Transaction / Ledger
```

Existing services and engines must be verified and reused before introducing new debt-specific infrastructure.

---

# 13. Consequences

## Positive

- Accounts and Manage no longer compete for ownership.
- Debt balances remain consistent with the financial engine.
- Credit Card and installment operations follow the canonical financial pipeline.
- Future-payment status can be derived consistently.
- Reusable facilities and one-off installment plans remain conceptually distinct.
- Rotating Savings can move from expected entitlement to liability only after actual receipt is confirmed.
- The Debts dashboard can evolve without becoming a second financial engine.

## Trade-offs

- The UI may require aggregation across Accounts, Commitments, Schedules, and other approved read-side sources.
- Some debt workflows may require additional domain/application contracts before implementation.
- Existing debt code must be verified before adding new services or models.

---

# 14. Implementation Guardrails

Before implementing the Debts screen or expanding debt workflows:

1. Verify the existing Account model and liability representation.
2. Verify existing debt-related models and services.
3. Verify Commitment/Schedule APIs for due-date and settlement state.
4. Reuse existing Financial Operation Execution Engine behavior.
5. Do not create a duplicate debt balance source.
6. Do not hardcode Overdue / Due Soon / Upcoming.
7. Do not create a new repository/service merely to satisfy the screen until the existing architecture is verified.
8. Add or update financial integrity/regression tests for any financial mutation.

---

# Final Decision

Wafferly's Debt Domain follows one financial truth with separated responsibilities:

```text
                    ┌─────────────────────┐
                    │      ACCOUNTS       │
                    │ Financial Position  │
                    │ Liability Accounts  │
                    └──────────┬──────────┘
                               │
                               │ authoritative position
                               │
                               ▼
                    ┌─────────────────────┐
                    │       MANAGE        │
                    │ Debt Workflow / UX  │
                    └──────────┬──────────┘
                               │
                               │ approved operation
                               ▼
              ┌─────────────────────────────────┐
              │ Financial Operation Execution   │
              │            Engine               │
              └────────────────┬────────────────┘
                               │
                       ┌───────┴────────┐
                       ▼                ▼
                  Transaction        Ledger
                       │                │
                       └───────┬────────┘
                               ▼
                         Financial Truth
```

**Accounts owns financial position. Manage owns workflow. Transactions/Ledger own executed financial history. Commitments/Schedules own future payment expectations. No screen may create a competing financial truth.**
