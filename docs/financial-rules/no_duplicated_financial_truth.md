# No Duplicated Financial Truth

Status: APPROVED

Category: Financial Rule

Version: V4

---

# Purpose

Ensure that financial truth exists in exactly one place.

Prevent competing balances, duplicated ownership, and data drift.

This rule is one of the core architectural protections of Wafferly.

---

# Rule

Financial truth must exist in exactly one place.

There must never be multiple sources of truth for the same financial fact.

---

# Examples

Correct:

Cash Account Balance
↓
Derived Available Balance

Source Of Truth:

Cash Account

---

Correct:

Allocations
↓
Reserved Money

Source Of Truth:

Allocations

---

Correct:

Goal Activities
+
Allocations
↓
Funding Sources Projection

Source Of Truth:

Activities + Allocations

---

# Incorrect Examples

Cash Balance

and

Available Balance

both stored independently.

---

Goal Progress

stored directly on Goal

and

calculated from Funding Sources.

---

Budget Remaining

stored on Budget

and

calculated from Transactions.

---

These create conflicting truths.

---

# Single Source Of Truth Rule

Money must exist in exactly one place:

Accounts

Planning intent must exist in exactly one place:

Allocations

Transaction history must exist in exactly one place:

Ledger

Activities

Current funding state must exist in exactly one place:

Funding Sources Projection

---

# Projection Rule

Projections are derived.

Projections are never truth.

Examples:

* Available Balance
* Reserved Money
* Funding Sources
* Goal Progress
* Budget Remaining

These values must always be recalculated.

---

# Storage Rule

Never store a value if it can be reliably derived from existing truth.

Examples:

Do Not Store:

* Goal Saved Amount
* Goal Balance
* Reserved Balance
* Budget Remaining
* Available Balance

Calculate them when needed.

---

# Relationship With Accounts

Accounts own money.

Any duplicate money ownership is a bug.

Examples:

Incorrect:

Cash = 10000

Goal Balance = 3000

Reason:

The same money now exists twice.

---

Correct:

Cash = 10000

Goal Allocation = 3000

Money exists once.

Intent exists separately.

---

# Relationship With Computation Independence Rule

Truth
↓
Projection

Truth
↓
Forecast

Truth
↓
Analytics

Allowed.

Projection
↓
Forecast

Projection
↓
Analytics

Forbidden.

Duplicated truth often leads to derived-on-derived dependencies.

---

# Data Drift Prevention

This rule protects against:

* Hidden Bugs
* Data Drift
* Migration Errors
* Inconsistent Reports
* Incorrect Forecasts
* Broken Analytics

---

# Summary

Every financial fact must have exactly one source of truth.

Everything else is derived.

Never duplicate financial ownership.

Never duplicate balances.

Never duplicate planning state.

Status:

APPROVED
