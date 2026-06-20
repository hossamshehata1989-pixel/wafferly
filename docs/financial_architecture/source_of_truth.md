# Source Of Truth Architecture

Status: APPROVED

Version: V4

---

# Purpose

Define where financial truth exists inside Wafferly.

Financial truth must exist exactly once.

Financial truth must never be duplicated.

Financial truth must never be derived from projections.

---

# Core Principle

Truth exists only in source domains.

Everything else is derived.

---

# Financial Truth Domains

Accounts

Transactions

Ledger

Allocations

Liabilities

Commitments

Investments

Members

---

# Accounts

Own money.

Examples:

- Cash
- Wallet
- Bank
- Saving Accounts
- Investment Accounts

Accounts are financial truth.

---

# Transactions

Represent money movement.

Examples:

- Income
- Expense
- Transfer
- Debt Settlement

Transactions are financial truth.

---

# Ledger

Represents historical financial truth.

Ledger is financial truth.

---

# Allocations

Represent planning intent.

Allocations are the Planning Source Of Truth.

Allocations are not projections.

---

# Liabilities

Represent current obligations.

Liabilities are financial truth.

---

# Commitments

Represent future expected financial events.

Commitments are financial truth.

---

# Investments

Represent investment ownership and valuation.

Investments are financial truth.

---

# Members

Represent participation and permissions.

Members are financial truth.

---

# Not Source Of Truth

The following are never source of truth:

- Available Balance
- Reserved Money
- Goal Progress
- Budget Remaining
- Funding Sources
- Forecasts
- Reports
- Analytics
- AI Insights

---

# Source Of Truth Rule

Truth
↓
Computation

Allowed

---

Computation
↓
Computation

Forbidden

---

# Examples

Allowed:

Allocations
↓
Reserved Money

---

Allowed:

Allocations
↓
Goal Progress

---

Forbidden:

Reserved Money
↓
Goal Progress

---

Forbidden:

Available Balance
↓
Forecasting

---

# Summary

Financial truth exists only in source domains.

Everything else is derived.

Truth must never be duplicated.

Status:

APPROVED