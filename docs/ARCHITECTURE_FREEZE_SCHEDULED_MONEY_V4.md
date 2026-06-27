# Wafferly V4 Scheduled Money Architecture Freeze

Status: FROZEN

Scope:
Scheduled Money, Commitments, Schedule Engine, Planning navigation boundaries, and execution flow into Transactions.

---

# 1. Architecture Freeze

## Core Decisions

Accounts own financial truth.

Transactions own actual money movement.

Investments are a separate domain.

Scheduled Money is a Manage section, not a single financial truth domain.

Commitment represents a future financial event.

ScheduleRule represents reusable timing infrastructure.

ScheduleOccurrence represents one generated due instance.

Transaction represents an executed financial event.

## Boundary Rule

Schedule Engine says WHEN.

Commitment says WHAT.

Transaction records WHAT HAPPENED.

## Manage Navigation

Manage contains:

- Scheduled Money
  - Commitments
- Planning
  - Goals
  - Budgets

Navigation labels may group domains for usability, but navigation must not redefine domain ownership.

## Source Of Truth Rule

Commitments are source data for future expected events.

ScheduleRules are source data for recurrence and timing.

ScheduleOccurrences are generated due instances and execution tracking records.

Transactions are the only source for actual money movement.

Projection, forecasting, analytics, and AI may read these domains, but must not become their source of truth.

---

# 2. Domain Map

## Financial Truth

- Accounts
- Transactions
- Ledger

## Planning

- Goals
- Budgets
- Allocations

## Scheduled Money

- Commitments
- ScheduleRules
- ScheduleOccurrences

## Investments

- Investment accounts
- Investment assets
- Investment positions
- Valuations
- Investment transactions

## Derived Layers

- Reserved Money
- Available Balance
- Goal Progress
- Budget Remaining
- Forecasts
- Reports
- AI Insights

Derived layers are never source of truth.

---

# 3. Entity Ownership Matrix

| Entity | Owns | Never Owns | Layer |
| --- | --- | --- | --- |
| Account | Money location, financial ownership | Scheduling, intent, forecast | Financial Truth |
| Transaction | Actual executed movement | Future expectations, recurrence rules | Financial Truth |
| LedgerEntry | Accounting history | User intent, schedule meaning | Financial Truth |
| Goal | Purpose | Money, balance, schedule timing | Planning |
| Budget | Spending control policy | Money, executed movement | Planning |
| Allocation | Planning reservation intent | Account balance, ledger movement | Planning |
| Reserved Money | Derived reserved amount | Source truth | Projection |
| Commitment | Future financial event meaning | Timing algorithm, actual execution | Scheduled Money |
| ScheduleRule | Timing pattern and recurrence | Amount, account, category, debt, investment meaning | Scheduling |
| ScheduleOccurrence | One due instance and execution state | Financial meaning, balance effect | Scheduling |
| Investment | Asset ownership and valuation context | Savings semantics, generic scheduling | Investments |
| Forecast | Prediction | Truth | Forecasting |
| AI Insight | Recommendation or explanation | Direct financial mutation | AI |

---

# 4. Dependency Diagram

```text
Accounts
Transactions
Ledger
    |
    v
Planning
Goals / Budgets / Allocations
    |
    v
Scheduled Money
Commitments
    |
    v
Schedule Engine
ScheduleRule -> ScheduleOccurrence
    |
    v
Execution Flow
User confirmation / domain policy
    |
    v
Transaction
    |
    v
Ledger
```

More precise ownership flow:

```text
ScheduleRule
  says WHEN

Commitment
  says WHAT is expected

ScheduleOccurrence
  says THIS instance is due

Domain execution policy
  says whether execution is allowed

Transaction
  records WHAT HAPPENED
```

Forecasting reads source domains directly:

```text
Accounts + Transactions + Allocations + Goals + Budgets + Commitments + ScheduleRules + Investments
    |
    v
Forecasting
```

Forecasting must not read Reserved Money, Available Balance, or generated reports as source truth.

---

# 5. Implementation Roadmap

## Phase 1: Freeze And Clean Boundaries

- Add architecture freeze document.
- Confirm navigation language: Scheduled Money is a section, Commitment is the domain.
- Ensure Reserved Money remains projection-only.
- Document ScheduleRule and ScheduleOccurrence boundaries.
- Audit existing services for any future-event logic mixed into Transactions.

## Phase 2: Schedule Engine Foundation

- Define ScheduleRule model conceptually.
- Define ScheduleOccurrence model conceptually.
- Support core recurrence: one-time, daily, weekly, monthly, yearly.
- Support pause, resume, skip, end date, occurrence count.
- Add idempotency rule for occurrence generation.
- Add audit trail for triggered, skipped, completed, failed occurrences.

## Phase 3: Commitments Domain

- Define Commitment as future financial event.
- Support commitment types:
  - Scheduled expense
  - Scheduled income
  - Scheduled transfer
  - Bill
  - Subscription
  - Loan payment expectation
- Link Commitment to ScheduleRule.
- Link Commitment execution to ScheduleOccurrence.
- Keep all account, category, amount, and business meaning inside Commitment, not ScheduleRule.

## Phase 4: Execution Flow

- Add execution policies:
  - Reminder only
  - Confirm before create
  - Auto-create where safe
- Convert due Commitment into Transaction only after policy allows.
- Link Transaction back to ScheduleOccurrence.
- Prevent duplicate transactions from the same occurrence.
- Handle insufficient funds without automatically creating debt.

## Phase 5: Planning Integration

- Allow Commitments to inform Budget views.
- Allow Goal contribution plans to reference ScheduleRules when needed.
- Keep Goals and Budgets as planning domains.
- Keep Scheduled Money as expected future events, not planning reservations.
- Use Allocations when money is reserved.

## Phase 6: Forecasting And Analysis

- Forecast future cash flow from Commitments and ScheduleRules.
- Forecast goal completion from scheduled contributions.
- Forecast budget pressure from recurring commitments.
- Ensure forecasting reads source domains directly.

## Phase 7: Investments Integration

- Keep Investments separate from Savings and Planning.
- Allow scheduled investment contributions through domain-specific investment plans referencing ScheduleRules.
- Record executed buys, sells, deposits, and withdrawals as Transactions.
- Keep valuation changes out of Schedule Engine.

---

# 6. Open Architecture Questions

1. Should Commitment include one-time events, or should one-time events be ScheduleRules with a single occurrence?

Recommendation: support both through a one-time ScheduleRule for consistency.

2. Should variable amount commitments store estimated amount?

Recommendation: yes, as Commitment data, with amount mode: fixed, estimated, variable.

3. Should loan payment schedules be Commitments or part of Loans?

Recommendation: the Loan domain owns liability meaning. Payment expectations are Commitments linked to the Loan.

4. Should credit card statement cycles use generic ScheduleRules?

Recommendation: use ScheduleRules for dates, but keep statement balance, minimum payment, grace period, and interest logic inside Credit Card domain.

5. Should skipped occurrences be stored?

Recommendation: yes. Skips are user decisions and should be auditable.

6. Should generated future occurrences be stored far ahead?

Recommendation: store near-term generated occurrences only. Long-range forecasting should calculate from ScheduleRules and Commitments directly.

7. Should auto-create be allowed for all commitments?

Recommendation: no. Start with confirm-first as default. Allow auto-create only for low-risk, deterministic cases.

---

# 7. Two-Year Refactor Risks

## Schedule Engine Becomes A Financial Domain

Risk:
ScheduleRule gains fields like amount, accountId, categoryId, loanId, or budgetId.

Impact:
Scheduling becomes coupled to every financial domain.

Prevention:
ScheduleRule owns timing only. Financial meaning lives in the referencing domain.

## Future Events Pollute Transactions

Risk:
Scheduled events are saved as Transactions before they happen.

Impact:
Balances, ledger, reports, and net worth become inaccurate.

Prevention:
Only executed events create Transactions.

## Commitment And Allocation Merge

Risk:
A future bill is treated as reserved money.

Impact:
Available Balance becomes ambiguous.

Prevention:
Commitment means expected future event. Allocation means current planning reservation.

## Occurrence History Is Lost

Risk:
Changing a ScheduleRule rewrites or hides past due instances.

Impact:
Audit trail, reminders, and execution debugging become unreliable.

Prevention:
Store executed, skipped, and failed occurrences as history.

## Auto-Create Duplicates

Risk:
App restart, sync, retry, or timezone change creates the same transaction twice.

Impact:
Duplicate expenses or income.

Prevention:
Use occurrence-level idempotency and transaction back-reference.

## Forecasting Uses Projection As Truth

Risk:
Forecasting reads Available Balance or Reserved Money instead of Accounts, Allocations, Commitments, and ScheduleRules.

Impact:
Derived data depends on derived data, causing compounding errors.

Prevention:
Forecasting reads source domains directly.

## Investments Are Modeled As Savings

Risk:
Gold, stocks, or crypto are represented as simple saving accounts.

Impact:
Valuation, gain/loss, and asset allocation become hard to fix later.

Prevention:
Investment domain owns positions and valuations. Accounts own money location.

---

# Current Legacy Exceptions

Current Legacy Exceptions

Goal
├ recurringRule
├ contributionAmount
└ nextDueDate

Reason:
Schedule Engine not implemented yet.

Migration:
Deferred Migration #1


---

# Deferred Migrations

## Goal Scheduling Migration

Current State:
Goal
├ recurringRule
├ contributionAmount
└ nextDueDate

Future State:
Goal
└ GoalContributionPlan
      └ ScheduleRule
            └ ScheduleOccurrence

Status:
Deferred

Reason:
Avoid premature refactor until Schedule Engine is implemented.

---
# Financial Network Freeze

Status: FROZEN

## Liability Accounts (Transitional MVP Rule)

Current MVP implementation represents:

- Credit Card
- Loan
- Borrowed Money
- Installment

as Liability Accounts inside the Financial Network.

Reason:

- Accounts remain the Financial Truth source.
- Net Worth requires obligations to be represented structurally.
- Manage > Debts acts as a workflow layer, not a separate balance layer.

Future Evolution:

Liability Accounts may later gain domain-specific profiles:

- Credit Card Profile
- Loan Contract
- Installment Contract
- Borrowed Money Agreement

without changing Financial Network ownership.

Rule:

Current obligation = Liability Account.

Future payment expectation = Commitment.

## Core Rule

Accounts are the financial network root.

Accounts represent financial positions.

Transactions change account balances.

Ledger proves financial history.

## Account Groups

The Financial Network contains:

- Money You Have
- Liabilities
- Investments
- Receivables
- Savings

## Money You Have

Represents liquid money controlled by the user.

Examples:

- Bank Account
- Debit Card
- Cash
- Electronic Wallet

Nature:
Asset

## Liabilities

1) Liability Types

Supported Liability Types

- Credit Card
- Loan
- Installment
- Borrowed Money
- Temporary Debt

2) Liability Metadata Rule
Liability accounts may own:

- Original Amount
- Remaining Balance
- Down Payment
- Interest
- Administrative Fees
- Settlement Amount
- Due Information
- Provider Information

3) Smart Import Future Rule

Future Smart Import

Liability accounts may be created or updated from:

- Bank SMS
- Email Statements
- OCR Documents
- PDF Contracts
- AI Extraction Pipelines

Imported data must be validated before affecting financial truth.



Represents money the user currently owes.



Nature:
Liability

Liability accounts affect Net Worth.

Liability accounts may be created and managed from Manage > Debts, but they appear in Accounts > Financial Network.

## Investments

Represents assets intended for growth or market exposure.

Examples:

- Gold
- Stocks
- Certificates

Nature:
Asset

Investments are separate from Savings.

Investment accounts may require investment-specific metadata later, but ownership remains rooted in Accounts.

## Receivables

Represents money the user expects to receive because another party owes the user.

Examples:

- Lent Money

Nature:
Asset

Receivables are not income until money is actually received through a Transaction.

## Savings

Represents real saving accounts and virtual saving views.

Examples:

- Real Savings Account
- Virtual Saving Goal
- Virtual Reserve Bucket

Rules:

- Real Savings Account is an Account.
- Virtual Saving Goal is not a real Account.
- Virtual Reserve Bucket is not a real Account.
- Virtual saving and reserve nodes are derived from Goals, Budgets, Allocations, and Reserved Money projections.

## Financial Network Boundary

Allowed:

```text
Manage > Debts
  creates or manages liability Accounts

Accounts > Financial Network
  displays those Accounts structurally
```

Forbidden:

```text
Debt domain owns a separate balance disconnected from Account

Virtual Goal owns real money

Virtual Reserve Bucket becomes a real Account
```

## Final Financial Network Rule

Account owns financial position.

Domain-specific profiles own specialized rules.

Commitments own future expectations.

Transactions own actual movement.

---

# Saving Circle Lifecycle

Status: FROZEN

Official name:
Saving Circle

Internal/historical name:
ROSCA

## Core Rule

Saving Circle is not automatically a liability.

Saving Circle becomes a liability only after payout is received and future installments remain due.

## Lifecycle States

### Waiting

The user is contributing to the circle.

No payout has been received.

No liability exists yet.

Financial treatment:

- Contributions are actual Transactions when paid.
- No liability account is created only because the user joined the circle.

### Received

The user has received the payout.

Remaining installments now represent a current obligation.

Financial treatment:

- Create or activate a Saving Circle Liability Account.
- Future installment expectations may be represented as Commitments.
- Actual installment payments are Transactions.

### Completed

All remaining installments have been paid.

No outstanding obligation remains.

Financial treatment:

- Liability balance reaches zero.
- Saving Circle may be archived.
- Historical Transactions and Ledger entries remain.

## Relationship With Schedule Engine

ScheduleRule owns installment timing.

Commitment owns future installment expectation.

Transaction records each paid installment.

Account represents the current liability only after payout is received.

## Boundary Rule

Before payout:
Saving Circle is participation/history, not liability.

After payout:
Saving Circle may create a liability Account for remaining obligations.

At completion:
Liability is settled, history remains.

---

# Final Rule

Schedule Engine says WHEN.

Commitment says WHAT.

Transaction records WHAT HAPPENED.

Ledger proves it.

Status:
FROZEN
