# Available Balance Projection

Status: APPROVED

Layer: Projection

Version: V4

---

# Purpose

Available Balance represents money that is currently available for use.

Available Balance does not represent ownership.

Available Balance does not represent actual account balance.

Available Balance answers:

How much money can be used right now?

---

# Core Rule

Available Balance

=

Projection

Available Balance is not:

* Account Balance
* Ledger Balance
* Source Of Truth

---

# Formula

Available Balance

=

## Account Balance

Active Allocations

---

# Example

Cash = 10000

Goal Allocation = 3000

Budget Reservation = 2000

Result:

Actual Balance = 10000

Available Balance = 5000

---

# Projection Rule

Available Balance is derived.

Available Balance must never be stored.

Available Balance must always be calculated.

---

# Source Of Truth

Available Balance is derived from:

* Accounts
* Allocations

Accounts remain the ownership source.

Allocations remain the planning source.

---

# Ownership Rule

Available Balance does not own money.

Accounts still own all money.

Example:

Cash = 10000

Available = 7000

Reserved = 3000

Result:

Cash owns 10000

Available Balance owns nothing.

---

# Net Worth Rule

Available Balance does not affect Net Worth.

Example:

Cash = 10000

Reserved = 3000

Available = 7000

Net Worth = 10000

---

# Multi-Account Example

Cash = 3000

Bank = 7000

Wallet = 1000

Total Balance = 11000

Allocations = 4000

Result:

Available Balance = 7000

---

# Relationship With Reserved Money

Architecture:

Allocations
↓
Reserved Money

Allocations
↓
Available Balance

Available Balance and Reserved Money are sibling projections.

Neither is source of truth for the other.

---

# Relationship With Goals

Goal Allocations reduce Available Balance.

Goals do not modify Available Balance directly.

Accounts own money.

Allocations affect planning state.

---

# Relationship With Budgets

Protected Budget reservations reduce Available Balance.

Monitoring Budgets do not affect Available Balance.

---

# Relationship With Temporary Debt

Temporary Debt validation uses:

Available Liquidity

before debt creation.

Decision Flow:

Liquidity
↓
Savings Review
↓
Reserved Money Review
↓
Temporary Debt

---

# Relationship With Forecasting

Forecasting reads:

* Accounts
* Allocations
* Commitments
* Liabilities

directly.

Forecasting must never use Available Balance as source of truth.

---

# Relationship With AI

AI may display Available Balance.

AI must read underlying truth directly.

Available Balance is presentation state.

---

# Computation Independence Rule

Allowed:

Accounts + Allocations
↓
Available Balance

Forbidden:

Available Balance
↓
Forecasting

Available Balance
↓
Analytics

Available Balance
↓
AI Context

---

# Summary

Available Balance represents usable money.

Available Balance

=

## Account Balance

Active Allocations

Available Balance is a projection.

Accounts own money.

Allocations represent planning intent.

Status:

APPROVED
