# Wafferly Financial Architecture V4

## Core Principles

Accounts
= Source Of Truth

Transactions
= Money Movement

Allocations
= Planning Source Of Truth

Funding Sources
= Current Funding State

Goals
= Purpose

Budgets
= Monitoring

Projections
= Read-Only Views

Analytics
= Derived Insight

---

# Layer Architecture

Accounts Layer
↓
Transactions Layer
↓
Allocation Layer
↓
Projection Layer
↓
Planning Layer
↓
Analytics Layer

---

# Accounts Layer

Accounts own money.

Only Accounts affect Net Worth.

Examples:

* Cash
* Wallet
* Bank
* Real Saving Accounts
* Borrowed
* Lent
* Temporary Debt
* Saving Circle Liability

---

# Transactions Layer

Transactions represent real financial movement.

Examples:

* Income
* Expense
* Transfer
* Borrow
* Lend
* Debt Settlement

Rule:

Record what actually happened.

Never create artificial transactions.

---

# Allocation Layer

Allocations never own money.

Allocations only reference money already inside Accounts.

Creating an Allocation must never create money.

Deleting an Allocation must never delete money.

Allocations affect:

* Available Balance
* Planning Projections

Allocations never affect:

* Net Worth
* Account Balances

Allocation Types:

* Goal Allocation
* Saving Allocation
* Budget Surplus Allocation

---

# Projection Layer

Projections are read-only views.

Examples:

* Reserved Money
* Available Balance
* Goal Progress
* Funding Sources
* Budget Remaining

Projection Rule:

Modify source data.

Then recompute projection.

Never edit projections directly.

---

# Goals Domain

# Goal

Purpose Only

Goal does not own money.

Goal does not have balance.

Goal does not have account ownership.

Goal stores:

* Metadata
* Activities

Goal exposes:

* Progress Projection
* Funding Sources Projection

---

# Goal Funding Model

# Funding Sources

Current State

# Goal Activities

History

# Goal Progress

Achievement Tracking

These concepts are independent.

---

# Goal Funding Types

Reserved Funding

Money remains inside source accounts.

Saving Funding

Money exists inside real Saving Accounts.

---

# Goal Progress Rule

Goal Progress measures achievement.

Goal Progress is not current balance.

Goal Progress must not decrease because money moved between valid funding states.

Example:

Reserved Funding
→ Transfer To Saving

Progress remains unchanged.

---

# Goal Funding Projection Service

Single Source Of Truth for Goal Funding State.

Returns:

* Reserved Sources
* Saving Sources
* Total Reserved
* Total Saved
* Total Progress

All Goal UI depends on this Projection.

---

# Goal Completion

Complete Goal is not a financial transaction.

Complete Goal is a lifecycle event.

Available actions:

* Keep Reserved
* Release Money
* Transfer To Saving

---

# Transfer To Saving

Transfer To Saving is a real financial operation.

Creates Transfer Transactions.

Uses real Saving Accounts.

Does not create Saving Allocations.

After successful transfer:

* Goal Allocations are released
* Goal Activities are recorded
* Goal remains completed

---

# Saving Architecture

Real Saving Account

Belongs to Accounts Layer.

Owns money.

Examples:

* Emergency Fund
* Vacation Fund
* Home Safe
* Savings Bank Account

Virtual Saving

Belongs to Planning Layer.

Projection only.

Owns no money.

Aggregates saving-related planning information.

---

# Saving Allocation

Saving Allocation belongs to Planning Layer.

Represents saving intent.

Does not own money.

Does not represent account balances.

Saving Allocation is different from a Real Saving Account.

---

# Investment Rule

Investments are not Savings.

Examples:

* Gold
* Stocks
* Mutual Funds
* Crypto Assets

Investments belong to Investment Domain.

Savings belong to Saving Domain.

---

# Budgets

# Budget

Monitoring

Budgets:

* Track spending
* Analyze spending
* Alert spending

Budgets never own money.

Budgets never move money.

Budget Remaining is a Projection.

---

# Budget Surplus

Unused budget does not automatically become savings.

User may explicitly create:

Budget Surplus Allocation

---

# Reserved Money

# Reserved Money

Sum(Active Allocations)

Reserved Money is a Projection.

Reserved Money is not:

* Money
* Wallet
* Asset
* Account

---

# Temporary Debt

# Temporary Debt

Emergency Liability Mechanism

Purpose:

* Preserve history
* Allow expense recording
* Track debt
* Force settlement

Debt Settlement uses:

TransactionType.debtSettlement

---

# Temporary Debt Completion

When debt reaches zero:

* Deactivate Debt Cycle
* Archive Debt Configuration
* Keep System Account

---

# Saving Circle

Saving Circle has:

* Waiting
* Received
* Completed

Received State creates:

Saving Circle Liability

---

# Net Worth Rule

Net Worth

=

## Assets

Liabilities

Only Accounts Layer affects Net Worth.

Planning Layer never affects Net Worth.

Projections never affect Net Worth.

---

# Single Source Of Truth Rule

Money must exist in exactly one place:

Accounts.

Everything else is derived.

---

# Golden Rules

Accounts own money.

Transactions move money.

Allocations reserve money.

Goals explain purpose.

Budgets monitor spending.

Funding Sources represent current state.

Activities represent history.

Goal Progress measures achievement.

Reserved Money is a projection.

Planning never owns money.

Only Accounts Layer affects Net Worth.
