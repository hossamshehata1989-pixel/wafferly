# Projection Architecture

Status: APPROVED

Version: V1

---

# Purpose

Projection represents the current financial state of Wafferly.

Projection is a computation layer.

Projection never owns money.

Projection never becomes a source of truth.

---

# Philosophy

Projection answers:

"What is my financial situation right now?"

Projection never predicts the future.

Projection never explains history.

Projection only computes current state.

---

# Source Domains

Projection reads directly from:

* Accounts
* Transactions
* Ledger
* Goals
* Allocations
* Budgets
* Liabilities
* Commitments (when required)

Projection never reads another derived layer.

---

# Projection Outputs

Examples:

* Available Balance
* Reserved Money
* Goal Progress
* Budget Remaining
* Funding Sources
* Current Net Worth
* Debt Summary

---

# Projection Rules

Projection is derived.

Projection must never be persisted as financial truth.

Projection may be cached for performance.

Deleting projection data must never lose financial information.

Projection is always reproducible.

---

# Dependency Rule

Allowed

Financial Truth

↓

Projection

Forbidden

Projection

↓

Forecasting

Projection

↓

Analytics

Projection

↓

AI

Every computation layer reads directly from source domains.

---

# Responsibilities

Projection is responsible for:

* Current balances
* Current reservations
* Current funding state
* Current budget state

Projection is NOT responsible for:

* Historical analysis
* Future prediction
* User recommendations
* Automatic execution

---

# Final Principle

Projection answers:

"What exists now?"

Nothing more.

Status:

APPROVED
