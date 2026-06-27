# Wafferly Financial Architecture V4

Status: APPROVED

Version: V4

---

# Purpose

This document defines the complete financial architecture of Wafferly.

All domains, services, projections, forecasting systems, AI systems, and future features must follow this architecture.

---

# Financial Truth Layer

Financial Truth represents objective financial reality.

Financial Truth owns money.

Financial Truth records money movement.

Financial Truth records obligations.

Components:

* Accounts
* Transactions
* Ledger

Financial Truth is the foundation of all computation layers.

Everything else is derived directly or indirectly from Financial Truth.


---

# Obligations Layer

Contains:

* Liabilities

Purpose:

Represent current obligations that already exist.

Examples:

* Loan
* Installment
* Borrowed Money
* Temporary Debt
* Saving Circle Liability

Liabilities affect:

* Net Worth
* Financial Position
* Future Obligations

---

# Financial Truth Rule

Truth must exist exactly once.

Truth must never be duplicated.

Truth must never be derived from projections.

---

# Layer Architecture

Financial Truth Layer

Accounts

Transactions

Ledger

↓

Obligations Layer

Liabilities

↓

Scheduling Layer

Recurring Engine

↓

Commitment Layer

Commitments

↓

Planning Layer

Allocations

Goals

Budgets

↓

Projection Layer

Funding Sources

Reserved Money

Available Balance

Goal Progress

Budget Remaining

↓

Forecasting Layer

Future Balance

Future Available Balance

Future Cash Flow

Future Obligations

Goal Completion Forecast

Budget Exhaustion Forecast

↓

Analytics Layer

Reports

Insights

Net Worth

Trends

↓

AI Layer

Context Builder

Insights Engine

Recommendation Engine

Action Engine


---

# Accounts

Accounts own money.

Only Accounts own money.

Examples:

- Cash
- Wallet
- Bank
- Saving Accounts
- Investment Accounts
- Shared Accounts

---

# Transactions

Transactions move money.

Examples:

- Income
- Expense
- Transfer
- Debt Settlement

---

# Ledger

Ledger represents financial truth.

Ledger records financial history.

---

# Allocations

Allocations represent planning intent.

Allocations never own money.

Allocations are the Planning Source Of Truth.

Allocations belong to the Planning Layer.

Allocations are not part of the Financial Truth Layer.

---

# Goals

Goals represent purpose.

Goals do not own money.

Goals explain:

Why money is being reserved or saved.

---

# Budgets

Budgets monitor spending.

Budgets do not own money.

---

# Liabilities

Liabilities represent current obligations.

Examples:

- Loans
- Installments
- Borrowed Money
- Temporary Debt

Current MVP Implementation

The following obligation types are represented as
Liability Accounts:

- Credit Card
- Loan
- Borrowed Money
- Installment
- Temporary Debt

Future debt-domain features may introduce specialized
contract metadata and schedule logic while keeping
Financial Truth ownership rooted in Accounts.


Liabilities affect Net Worth.

---

# Commitments

Commitments represent future expectations.

Examples:

- Bills
- Subscriptions
- Rent
- Salary
- Loan Payments

Commitments do not affect Net Worth directly.

---

# Commitment Foundation (Phase 0)

Purpose:
Represent future scheduled financial obligations.

Examples:
- Loan Payment
- Credit Card Payment
- Installment Payment
- Rent
- Subscription
- Salary

Core Models

Commitment
ScheduleRule

Relationship

Commitment
    1
    |
    | scheduleRuleId
    |
    v
ScheduleRule

Account Relationship

Commitment
    |
    | sourceAccountId
    v
Account

Optional:

Commitment
    |
    | liabilityAccountId
    v
Liability Account

Commitment Types

- income
- expense
- transfer
- liabilityPayment

Important Decision

Debt payments are NOT expenses.

Credit card payments,
loan payments,
installment payments,
borrowed money repayments

must use:

CommitmentType.liabilityPayment

Reason:

Avoid double counting expenses.
Preserve future forecasting.
Preserve debt payoff workflows.
Support OCR / SMS parsing.


---

# Investments

Investments are not Savings.

Examples:

- Gold
- Stocks
- ETFs
- Mutual Funds
- Crypto

Investments affect Net Worth.

---

# Members

Members are actors.

Members are not balances.

Members are not wallets.

Accounts own money.

---

# Projection Layer

Projection Layer represents current state.

Projection Layer never owns money.

Projection Layer never becomes source of truth.

---

Projection Examples:

- Funding Sources
- Reserved Money
- Available Balance
- Goal Progress
- Budget Remaining

---

# Forecasting Layer

Forecasting predicts future outcomes.

Forecasting reads directly from source domains.

Forecasting must never use Projection Layer
as a source of truth.

Forecasting must never depend on Projection Layer.

---

# Analytics Layer

Analytics explains historical behavior.

Analytics reads source domains directly.

Analytics must never depend on Projection Layer.

---

# AI Layer

AI is a decision support system.

AI may:

- Explain
- Analyze
- Forecast
- Recommend

AI may never:

- Move money
- Create debt
- Execute transfers

without user confirmation.

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

# Core Rules

Accounts Own Money

Transactions Move Money

Allocations Represent Planning Intent

Members Are Actors

Derived Data Independence Rule

No Duplicated Financial Truth

Projection Layer Is Not Truth

Forecasting Reads Source Domains Directly

AI Requires User Confirmation

---

# Final Principle

Accounts own money.

Transactions move money.

Allocations represent intent.

Goals represent purpose.

Budgets monitor spending.

Liabilities represent obligations.

Commitments represent expectations.

Projections represent current state.

Forecasting predicts the future.

Analytics explains the past.

AI assists decisions.

Financial Truth remains the foundation of everything.

Status:

APPROVED