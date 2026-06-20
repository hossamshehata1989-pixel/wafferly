# Financial Layers

Status: APPROVED

Version: V4

---

# Purpose

Describe the complete layer hierarchy of Wafferly.

This document defines responsibilities and boundaries between layers.

---

# Layer Hierarchy

Financial Truth Layer

↓

Obligations Layer

↓

Scheduling Layer

↓

Commitment Layer

↓

Planning Layer

↓

Projection Layer

↓

Forecasting Layer

↓

Analytics Layer

↓

AI Layer

---

# Financial Truth Layer

Purpose:

Store financial truth.

Contains:

* Accounts
* Transactions
* Ledger

Rule:

Truth exists here.

Only here.

---

# Obligations Layer

Purpose:

Represent current obligations.

Contains:

* Liabilities

Examples:

* Loans
* Installments
* Borrowed Money
* Temporary Debt
* Saving Circle Liability

---

# Scheduling Layer

Purpose:

Schedule future events.

Contains:

* Recurring Engine

Responsible for:

* Frequency
* Reminder
* Auto Create
* Pause
* Resume
* Skip
* End Date

---

# Commitment Layer

Purpose:

Represent expected future events.

Contains:

* Commitments

Examples:

* Bills
* Subscriptions
* Rent
* Salary
* Loan Payments
* Installment Payments

---

# Planning Layer

Purpose:

Represent financial intent.

Contains:

* Allocations
* Goals
* Budgets

Rule:

Planning never owns money.

Accounts own money.

---

# Projection Layer

Purpose:

Represent current state.

Contains:

* Funding Sources
* Reserved Money
* Available Balance
* Goal Progress
* Budget Remaining

Rule:

Projection is derived.

Projection is never truth.

---

# Forecasting Layer

Purpose:

Predict future outcomes.

Contains:

* Future Balance
* Future Available Balance
* Future Cash Flow
* Future Obligations
* Goal Forecasts
* Budget Forecasts

Rule:

Forecasting reads source domains directly.

Forecasting never reads Projection Layer as source of truth.

---

# Analytics Layer

Purpose:

Explain historical behavior.

Contains:

* Reports
* Trends
* Net Worth Analysis
* Spending Analysis

Rule:

Analytics reads source domains directly.

Analytics never depends on Projection Layer.

---

# AI Layer

Purpose:

Support decisions.

Contains:

* Context Builder
* Insights Engine
* Recommendation Engine
* Action Engine

Rule:

AI never changes financial state without confirmation.

---

# Independent Computation Layers

Financial Truth
│
├── Projection
│
├── Forecasting
│
├── Analytics
│
└── AI

Each computation layer reads directly from source domains.

---

# Derived Data Independence Rule

Allowed:

Truth
↓
Computation

Forbidden:

Computation
↓
Computation

---

# Final Principle

Financial Truth is the foundation.

Every computation layer is independent.

No derived layer becomes a source of truth for another derived layer.

Status:

APPROVED
