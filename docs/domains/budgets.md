# Budgets Domain

Status: APPROVED

Domain: Planning

Version: V4

---

# Purpose

Budgets exist to monitor and control spending.

Budgets answer:

How much am I willing to spend?

Budgets do not answer:

Where money exists?

Budgets do not own money.

---

# Core Rule

Budget

=

Monitoring

Budgets monitor spending.

Budgets never own money.

Budgets never affect Net Worth.

---

# Budget Types

## Monitoring Budget

Purpose:

Track spending only.

Does not reserve money.

Does not affect Available Balance.

Example:

Food Budget = 5000

Spent = 3000

Remaining = 2000

---

## Protected Budget

Purpose:

Reserve money in advance.

Reduce Available Balance.

Envelope-style budgeting.

Example:

Food Budget = 5000

Reserved = 5000

Available Balance -= 5000

---

# Budget Funding

Budgets may be funded from one or more Accounts.

Examples:

Cash = 2000

Bank = 2000

Wallet = 1000

Food Budget = 5000

---

# Multi-Source Funding

Supported.

Example:

Cash → 1000

Bank → 3000

Wallet → 1000

Food Budget = 5000

---

# Unified Funding Pattern

Goals and Budgets use the same architecture pattern.

Activities
↓
Funding Sources
↓
Projection

Status:

APPROVED

---

# Budget Funding Sources

Budget Funding Sources represent:

Current Budget Funding State

Funding Sources are projections.

Funding Sources are not stored.

Funding Sources are not source of truth.

---

# Budget Activities

Budget Activities represent history.

Examples:

* Created
* Funded
* Increased
* Reduced
* Overspent
* Released
* Transferred
* Rolled Over
* Closed

Activities are audit trail only.

Activities are not current state.

---

# Budget Consumption Model

Envelope Style

Example:

Food Budget = 5000

Expense = 1000

Result:

Reserved = 4000

Spent = 1000

Remaining = 4000

The reservation is consumed directly.

---

# Budget Remaining

Budget Remaining

=

## Budget Funding

Consumed Amount

Budget Remaining is a Projection.

Budget Remaining must never be stored.

---

# Budget Progress

Budget Progress

=

Spent
÷
Budget Funding

Budget Progress represents:

Consumption Progress

---

# Goal Progress vs Budget Progress

Goals grow.

Budgets shrink.

Goal Progress:

Accumulation Progress

Example:

Saved / Target

---

Budget Progress:

Consumption Progress

Example:

Spent / Budget

---

# Overspending

When spending exceeds budget:

Do not save the Transaction immediately.

Show:

Budget Resolution Dialog

---

# Resolution Options

## Increase Budget

Increase budget funding.

---

## Move From Another Budget

Example:

Transport -500

Food +500

---

## Ignore Budget

Ignore this budget violation.

---

## Cancel

Cancel the operation.

---

# Budget Increase Rule

Budget increases require a funding source.

Example:

Food

5000 → 7000

Must specify:

Transport -2000

or

Cash Available -2000

---

# Budget Transfer

Supported.

Example:

Transport Remaining = 1500

Move 1000

↓

Food Budget

Result:

Transport Remaining = 500

Food Remaining += 1000

Create Activity.

---

# Budget Period Policy

Each Budget has its own period policy.

---

## Reset

Start next period from zero.

---

## Carry Forward

Carry remaining amount into next period.

---

## Transfer To Saving

Move remaining amount into a real Saving Account.

Creates real Transfer Transactions.

---

## Release

Release reserved money.

Return it to Available Balance.

---

## Keep Reserved

Keep remaining money reserved.

---

# Keep Reserved Safeguard

If previous reservations already exist:

Warn the user.

Example:

Existing Reserved = 2000

New Reservation = 5000

Total Reserved = 7000

User chooses:

* Continue Existing Reservation
* Add New Reservation
* Release Existing Reservation

---

# Relationship With Goals

Goal ≠ Budget

Goals:

* Saving Money
* Long-Term
* Accumulation Driven

Budgets:

* Spending Control
* Short-Term
* Consumption Driven

---

# Relationship With Allocations

Budgets use their own reservation model.

Architecture:

Budgets
↓
Budget Allocation Engine

Goals
↓
Goal Allocation Engine

Both follow the same planning philosophy.

---

# Relationship With Virtual Saving

Budget reservations may appear inside:

Virtual Saving

Virtual Saving acts as:

Reservation Dashboard

Users may:

* Review Reservations
* Release Reservations
* Transfer Reservations

from a unified location.

---

# Budget Projection Service

BudgetProjectionService

is responsible for:

* Budget Funding
* Consumed Amount
* Remaining Amount
* Progress
* Overspending State

---

# Projection Ownership Rule

All derived values belong to Projection Services.

UI must never calculate business state.

Status:

APPROVED

---

# Relationship With Forecasting

Forecasting reads:

* Budgets
* Allocations
* Commitments
* Transactions

directly.

Forecasting must never use:

Budget Remaining

as source of truth.

---

# Relationship With AI

AI reads:

* Budgets
* Funding Sources
* Activities

directly.

AI may recommend budget changes.

AI must never modify budgets automatically.

---

# Summary

Budgets monitor spending.

Budget Funding Sources represent current state.

Budget Activities represent history.

Budget Remaining represents projection.

Goals grow.

Budgets shrink.

Accounts own money.

Budgets never own money.

Status:

APPROVED
