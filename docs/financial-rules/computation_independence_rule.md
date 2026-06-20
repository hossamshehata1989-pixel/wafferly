# Computation Independence Rule

Status: APPROVED

Category: Financial Architecture Rule

Version: V4

---

# Purpose

Protect Wafferly from Derived-On-Derived dependencies.

This rule applies to:

* Projection Layer
* Forecasting Layer
* Analytics Layer
* AI Layer
* Any future computation layer

---

# Rule

Derived systems must never use other derived systems as their source of truth.

Allowed:

Truth
↓
Computation

Forbidden:

Computation
↓
Computation

---

# Financial Truth

Financial Truth consists of:

* Accounts
* Transactions
* Ledger
* Allocations
* Commitments
* Liabilities
* Investments
* Members

These layers contain the underlying truth.

---

# Computation Layers

Examples:

* Projection Layer
* Forecasting Layer
* Analytics Layer
* AI Layer

These layers compute results.

They do not store truth.

---

# Correct Examples

Allocations
↓
Reserved Money

Allocations
↓
Goal Progress

Accounts + Allocations + Commitments
↓
Forecast

Transactions + Budgets
↓
Analytics

---

# Incorrect Examples

Reserved Money
↓
Forecast

Goal Progress
↓
Forecast

Available Balance
↓
Forecast

Budget Remaining
↓
Analytics

Forecast
↓
AI Context

---

# Reason

Derived values may contain:

* Bugs
* Temporary inconsistencies
* Migration issues
* Projection errors

A defect in one computation layer must never corrupt another computation layer.

---

# Architecture Pattern

Correct:

Financial Truth
│
├── Projection
│
├── Forecasting
│
├── Analytics
│
└── AI

Each layer reads directly from Financial Truth.

---

# Anti-Pattern

Never:

Truth
↓
Projection
↓
Forecast
↓
Analytics

This creates hidden dependencies.

This creates debugging complexity.

This creates data drift.

---

# Forecasting Rule

Forecasting Layer must never use Projection Layer as a source of truth.

Forecasting reads directly from:

* Accounts
* Transactions
* Ledger
* Allocations
* Commitments
* Liabilities

and computes independently.

---

# AI Rule

AI must never rely on:

* Available Balance
* Goal Progress
* Reserved Money
* Budget Remaining

as financial truth.

AI reads directly from Financial Truth and builds its own context.

---

# Summary

Truth
↓
Computation

is allowed.

Computation
↓
Computation

is forbidden.

Financial Truth
↓
Independent Computation Layers

Status:

APPROVED
