# Reserved Money Projection

Status: APPROVED

Layer: Projection

Version: V4

---

# Purpose

Reserved Money represents money that has been allocated for planning purposes.

Reserved Money does not represent ownership.

Reserved Money does not represent an Account.

Reserved Money answers:

How much money is currently reserved?

---

# Core Rule

Reserved Money

=

Projection

Reserved Money is not:

* Account
* Wallet
* Asset
* Balance
* Source Of Truth

---

# Formula

Reserved Money

=

Sum(Active Allocations)

---

# Example

Cash = 10000

Goal Allocation = 3000

Budget Allocation = 2000

Result:

Reserved Money = 5000

---

# Projection Rule

Reserved Money is derived.

Reserved Money must never be stored.

Reserved Money must always be calculated.

---

# Source Of Truth

Reserved Money is derived from:

* Goal Allocations
* Saving Allocations
* Budget Surplus Allocations
* Budget Reservations

Allocations remain the source of truth.

---

# Ownership Rule

Reserved Money does not own money.

Accounts still own money.

Example:

Cash = 10000

Reserved = 3000

Result:

Cash owns 10000

Reserved Money references 3000

---

# Net Worth Rule

Reserved Money does not affect Net Worth.

Example:

Cash = 10000

Reserved = 3000

Available = 7000

Net Worth = 10000

---

# Relationship With Available Balance

Architecture:

Allocations
↓
Reserved Money

Allocations
↓
Available Balance

Reserved Money and Available Balance are sibling projections.

Neither is source of truth for the other.

---

# Relationship With Goals

Goal Allocations contribute to Reserved Money.

Reserved Money does not belong to Goals.

Goals explain purpose.

Allocations provide intent.

Accounts own money.

---

# Relationship With Budgets

Budget Reservations contribute to Reserved Money.

Reserved Money does not belong to Budgets.

Budgets monitor spending.

---

# Relationship With Virtual Saving

Virtual Saving may display:

* Reserved Money
* Saving Allocations
* Goal Reservations
* Budget Reservations

Virtual Saving is a dashboard.

Virtual Saving owns no money.

---

# Relationship With Forecasting

Forecasting reads:

* Allocations
* Accounts
* Commitments

directly.

Forecasting must never use Reserved Money as source of truth.

---

# Relationship With AI

AI may display Reserved Money.

AI must read underlying truth directly.

Reserved Money is presentation state.

---

# Computation Independence Rule

Allowed:

Allocations
↓
Reserved Money

Forbidden:

Reserved Money
↓
Forecasting

Reserved Money
↓
Analytics

Reserved Money
↓
AI

---

# Summary

Reserved Money represents current reserved planning state.

Reserved Money

=

Sum(Active Allocations)

Reserved Money is a projection.

Allocations are the source of truth.

Accounts own money.

Status:

APPROVED
