# Allocations Represent Planning Intent

Status: APPROVED

Category: Financial Rule

Version: V4

---

# Purpose

Define the role of Allocations inside Wafferly.

Allocations are the foundation of the Planning Layer.

---

# Rule

Allocations represent planning intent.

Allocations do not represent money ownership.

Allocations do not represent balances.

Allocations do not represent assets.

---

# Planning Source Of Truth

Within the Planning Layer:

Allocations are the Source Of Truth.

Examples:

* Goal Allocation
* Saving Allocation
* Budget Surplus Allocation

All planning projections must originate from Allocations.

---

# Allocation Ownership Rule

Allocations never own money.

Allocations only reference money that already exists inside Accounts.

Creating an Allocation must never create money.

Deleting an Allocation must never delete money.

---

# Examples

Correct:

Cash = 10000

Goal Allocation = 3000

Result:

Cash owns 10000

Allocation references 3000

---

Incorrect:

Goal Balance = 3000

Reason:

Money still exists inside Cash.

The Goal does not own money.

---

# Allocation Effects

Allocations may affect:

* Available Balance
* Reserved Money
* Goal Progress
* Budget Funding
* Forecasting

Allocations must never affect:

* Account Balances
* Ledger Balances
* Net Worth

directly.

---

# Allocation Types

Current Allocation Types:

* Goal Allocation
* Saving Allocation
* Budget Surplus Allocation

Additional Allocation Types may be added in the future.

---

# Relationship With Goals

Goals explain purpose.

Allocations provide funding intent.

Architecture:

Account
↓
Allocation
↓
Goal

Goals never own money.

Allocations never own money.

Accounts own money.

---

# Relationship With Budgets

Budgets may reserve money through Allocations.

Budget state is derived from Allocations.

Budgets never own money.

---

# Relationship With Projections

Allocations are source data.

Examples:

Allocations
↓
Reserved Money

Allocations
↓
Funding Sources

Allocations
↓
Goal Progress

Allocations
↓
Available Balance

---

# Single Source Of Truth Rule

Planning truth must exist in exactly one place:

Allocations

Everything else is derived.

---

# Summary

Accounts own money.

Allocations represent planning intent.

Allocations never own money.

Allocations are the Planning Source Of Truth.

Status:

APPROVED
