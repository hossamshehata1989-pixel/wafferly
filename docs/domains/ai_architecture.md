# AI Architecture Domain

Status: APPROVED

Domain: AI

Version: V4

---

# Purpose

AI is a Decision Support Layer.

AI helps users understand, plan, and improve financial decisions.

AI is not part of Financial Truth.

AI never owns money.

AI never changes money autonomously.

---

# Core Rule

AI

=

Advisor

Not

=

Decision Maker

AI may:

* Explain
* Recommend
* Analyze
* Forecast
* Prioritize

AI may never perform financial actions without user confirmation.

---

# AI Architecture

Financial Truth
↓
Context Builder
↓
Insights Engine
↓
Recommendation Engine
↓
Action Engine
↓
User Confirmation

---

# Source Layer

AI reads directly from Financial Truth.

Sources:

* Accounts
* Transactions
* Ledger
* Allocations
* Goals
* Budgets
* Commitments
* Liabilities
* Investments
* Members

---

# Source Rule

AI must never use:

* Goal Progress
* Available Balance
* Reserved Money
* Budget Remaining

as source of truth.

AI must read underlying truth directly.

---

# Financial Context Builder

Purpose:

Build a smart financial snapshot.

AI should not receive raw financial history when unnecessary.

---

# Snapshot Examples

Current Balance

Available Balance

Top Categories

Goals

Budgets

Commitments

Liabilities

Recent Trends

Forecast Summary

---

# Memory Scope

AI receives only relevant context.

Purpose:

* Faster reasoning
* Lower token usage
* Better recommendations

---

# Insights Engine

Purpose:

Detect meaningful observations.

Examples:

* Overspending
* Budget Risk
* Goal Delays
* Debt Growth
* Cash Flow Problems

---

# Insight Priority

Levels:

## High

Immediate attention required.

Example:

Temporary Debt approaching limit.

---

## Medium

Action recommended.

Example:

Budget overspending trend.

---

## Low

Informational insight.

Example:

Savings improved this month.

---

# Recommendation Engine

Purpose:

Suggest actions.

Examples:

* Increase budget
* Reduce spending
* Reallocate money
* Accelerate goal funding
* Reduce debt

---

# Alternatives Engine

Every recommendation may include alternatives.

Example:

Goal Funding

Option A

Reserve Money

Option B

Transfer To Saving

Option C

Delay Goal

---

# Impact Analysis

AI should explain consequences.

Example:

If you reserve 2000 EGP:

Available Balance decreases by 2000 EGP.

---

# Forecast Integration

AI may consume:

* Forecasting Outputs
* Goal Forecasts
* Budget Forecasts
* Cash Flow Forecasts

Forecasting remains independent.

AI does not own forecasting logic.

---

# Shared Finance Support

AI may generate:

* Family Insights
* Shared Goal Insights
* Shared Budget Insights
* Shared Liability Insights

AI must respect Member permissions.

---

# Action Engine

Purpose:

Convert recommendations into user actions.

Examples:

* Create Goal
* Create Budget
* Release Reservation
* Transfer To Saving

---

# Confirmation Rule

Every financial action requires explicit user confirmation.

AI must never:

* Move money
* Create debt
* Delete allocations
* Execute transfers
* Settle liabilities

automatically.

---

# Autonomous Action Rule

Forbidden:

AI
↓
Financial Change

Allowed:

AI
↓
Recommendation
↓
User Confirmation
↓
Financial Change

---

# Relationship With Forecasting

Forecasting predicts.

AI explains.

These are separate responsibilities.

---

# Relationship With Analytics

Analytics explains the past.

Forecasting predicts the future.

AI connects both to user decisions.

---

# Source Of Truth

AI is never a source of truth.

Financial Truth remains:

Accounts
↓
Transactions
↓
Ledger
↓
Allocations
↓
Commitments
↓
Liabilities

Only

---

# Summary

AI is an advisor.

AI reads Financial Truth.

AI builds context.

AI generates insights.

AI recommends actions.

AI never performs autonomous financial changes.

User confirmation is always required.

Status:

APPROVED
