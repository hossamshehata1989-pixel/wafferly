# Wafferly Manage V1

Status:
APPROVED

Purpose:
Define the approved Manage navigation structure and its domain boundaries.

---

# Core Principle

Manage is a user-facing workspace.

Manage groups workflows.

Manage does not redefine domain ownership.

Navigation labels may group related features, but source-of-truth ownership remains with the underlying domains.

---

# Approved Navigation

```text
Manage
  Scheduled Money
    Commitments

  Planning
    Goals
    Budgets

  Debts
    Credit Cards
    Loans
    Borrowed Money
    Temporary Debt
```

---

# Scheduled Money

## Contains

- Commitments

## Domain Boundary

Commitment represents a future financial event.

ScheduleRule represents timing infrastructure.

ScheduleOccurrence represents one generated due instance.

Transaction represents an actual executed event.

## Rule

Schedule Engine says WHEN.

Commitment says WHAT.

Transaction records WHAT HAPPENED.

Scheduled Money must not create financial movement until execution is confirmed or allowed by policy.

---

# Planning

## Contains

- Goals
- Budgets

## Domain Boundary

Goals represent purpose.

Budgets represent spending control.

Allocations represent planning reservation intent.

Reserved Money is derived.

## Rule

Planning does not own money.

Accounts own money.

Transactions move money.

Allocations reserve planning intent.

---

# Debts

## Contains

- Credit Cards
- Loans
- Borrowed Money
- Installments
- Temporary Debt
- Saving Circle Liability (future)

## Domain Boundary

Debts is a Manage workflow section.

Internally, debt items are represented as liability Accounts where they represent current obligations.

Debt-specific screens may create, edit, explain, and settle liability Accounts.

Debt-specific screens may create, edit, explain, and settle liability Accounts.

## Rule

Manage > Debts is UX ownership.

Accounts > Financial Network is structural ownership.

Liability Account owns the current financial position.

Commitment owns future payment expectations.

Transaction records actual payment or settlement.

---

# Financial Network Relationship

Debt items created from Manage appear in:

```text
Accounts
  Financial Network
    Liabilities
```

Examples:

- Credit Card
- Loan
- Borrowed Money
- Temporary Debt

Manage may provide domain-specific actions, but it must not duplicate account balances outside Accounts.

---

# Forbidden

Manage must not own financial truth.

Scheduled Money must not store executed transactions as future events.

Planning must not own account balances.

Debts must not maintain separate balances disconnected from Accounts.

Virtual Saving Goals must not become real Accounts.

Virtual Reserve Buckets must not become real Accounts.

---

# Final Rule

Manage organizes work.

Accounts own financial position.

Commitments own future expectations.

Allocations own planning intent.

Transactions own actual movement.

Ledger proves history.
