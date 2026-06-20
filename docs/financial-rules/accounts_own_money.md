# Accounts Own Money

Status: APPROVED

Category: Financial Rule

Version: V4

---

# Purpose

Define the ownership of money inside Wafferly.

This rule is one of the foundational rules of the entire architecture.

---

# Rule

Accounts are the only entities that own money.

Examples:

* Cash
* Wallet
* Bank
* Real Saving Accounts
* Investment Accounts
* Borrowed
* Lent
* Temporary Debt

---

# Non-Owners

The following entities never own money:

* Goals
* Budgets
* Allocations
* Reservations
* Funding Sources
* Members
* Projections
* Forecasts
* Analytics
* AI Context

---

# Net Worth

Only Accounts affect Net Worth.

Changes to:

* Goals
* Budgets
* Allocations
* Funding Sources
* Projections

must never directly affect Net Worth.

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

Goals do not own money.

---

# Relationship With Other Rules

Related Rules:

* Transactions Move Money
* Allocations Represent Planning Intent
* Single Source Of Truth Rule

---

# Summary

Accounts own money.

Everything else references, explains, projects, analyzes, or forecasts money.

Only Accounts hold financial ownership.

Status:

APPROVED
