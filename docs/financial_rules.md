# Wafferly Financial Architecture v2.0

Last Updated: Financial Engine Stabilization Phase

---

# Core Philosophy

Wafferly is built around one fundamental rule:

**Money exists only inside Accounts.**

Everything else is an organizational or planning layer built on top of money.

Examples:

* Goals
* Budgets
* Savings Planning
* Virtual Saving
* Reserved Money
* Analysis
* Reports

These entities do not own money.

---

# Source of Truth

The only source of truth is:

Accounts
+
Transactions

All balances, reports, analytics, progress values and financial summaries must ultimately be derived from these two sources.

---

# Single Source of Truth Rule

Every amount of money must have one source of truth.

Money must never exist in multiple places simultaneously.

---

# Derived Values Rule

Never store derived values.

Store causes, not results.

Do NOT store:

* Goal Progress
* Goal Saved Amount
* Budget Remaining
* Available Balance
* Virtual Saving Balance
* Analytics Metrics

Calculate them when needed.

---

# Financial Engine

Transactions
↓
Ledger
↓
Account Balances
↓
Reports
↓
Analytics

The Ledger is part of the financial engine.

The Ledger is not a reporting layer.

Status:
[APPROVED]

---

# Accounts

Accounts are real financial containers.

Examples:

* Cash
* Wallet
* Bank Account
* Credit Account
* Loan Account
* Investment Account
* Saving Account

Accounts are the only entities that own money.

Status:
[APPROVED]

---

# Transactions

Transactions are financial events.

Examples:

* Income
* Expense
* Transfer
* Borrow
* Lend
* Repayment
* Collection

Transactions modify balances through the Ledger.

Status:
[APPROVED]

---

# Members

Members are participants only.

Members are not financial containers.

Members do not own balances.

Members may participate in transactions.

Status:
[APPROVED]

---

# Archive Policy

Financial entities should be archived whenever possible.

Historical data should remain available for:

* Reports
* Analytics
* Auditing
* Historical Tracking

Examples:

* Accounts
* Goals
* Members
* Saving Circles

Status:
[APPROVED]

---

# Net Worth

## Formula

Net Worth

=

## Assets

Liabilities

Status:
[APPROVED]

---

# Assets

Examples:

* Cash
* Wallets
* Bank Accounts
* Investments
* Lent

---

# Liabilities

Examples:

* Borrowed
* Temporary Debt
* Loans
* Credit Accounts
* Saving Circle Liability

Status:
[APPROVED]

---

# Borrowed

Borrowed is a Liability Account.

When user borrows money:

Cash +1000

Borrowed +1000

Result:

* Cash increases
* Liability increases
* Net Worth remains unchanged

---

# Borrowed Repayment

Cash -300

Borrowed -300

Result:

* Cash decreases
* Liability decreases
* Net Worth remains unchanged

Status:
[APPROVED]

---

# Lent

Lent is an Asset Account.

When user lends money:

Cash -1000

Lent +1000

Result:

* Cash decreases
* Receivable Asset increases
* Net Worth remains unchanged

---

# Collection

Cash +300

Lent -300

Result:

* Cash increases
* Receivable Asset decreases
* Net Worth remains unchanged

Status:
[APPROVED]

---

# Double Entry Rule

Borrowed and Lent transactions must affect:

1. Real Account
2. Counterpart Account

Examples:

Cash ↔ Borrowed

Cash ↔ Lent

Forbidden:

* Updating Borrowed only
* Updating Lent only
* Ignoring real account balances

Reason:

Balances
Ledger
Reports
Analytics

must remain synchronized.

Status:
[APPROVED]

---

# Temporary Debt

Temporary Debt is a Liability Account.

Temporary Debt is NOT Borrowed.

Borrowed:

* Real borrowing event
* Real money entered an account

Temporary Debt:

* Insufficient balance workaround
* No real borrowing event occurred

Status:
[APPROVED]

---

# Insufficient Balance Flow

When:

Expense > Available Balance

User may:

* Choose another account
* Add income
* Use Temporary Debt
* Cancel

Status:
[APPROVED]

---

# Temporary Debt Accumulation

Temporary Debt accumulates into a single balance.

Example:

Shortage #1 = 300

Shortage #2 = 100

Temporary Debt Balance = 400

Separate debt records are not required.

Status:
[APPROVED]

---

# Temporary Debt Settlement

When:

Income > 0

AND

Temporary Debt Balance > 0

Wafferly may offer:

* Settle Debt
* Keep Debt

Status:
[APPROVED]

---

# Savings UI Structure

Savings is a dedicated section inside Accounts UI.

Savings may contain:

* Real Saving Accounts
* Virtual Saving
* Saving Circle

This grouping is a user experience decision.

It does not change the financial architecture.

Status:
[APPROVED]

---

# Real Saving Account Rule

Real Saving Account is a normal Account.

Real Saving Accounts:

* Own real money
* Participate in Ledger
* Can receive Income
* Can receive Transfers
* Can record Expenses
* Affect Net Worth

They differ only by purpose and UI grouping.

They are not a special financial entity.

Status:
[APPROVED]

---

# Virtual Saving Rule

Virtual Saving is NOT an Account.

Virtual Saving is an organizational layer.

Virtual Saving does not own money.

Virtual Saving exists to organize reserved money when the user does not have a dedicated real saving account.

Virtual Saving may display:

* Monthly Saving Allocations
* Goal Allocations
* Budget Surplus Allocations

Virtual Saving Balance is calculated.

Formula:

Virtual Saving Balance

=

Sum(Active Saving Allocations)

Virtual Saving Balance must never be stored.

Status:
[APPROVED]

---

# Goals

Goal is NOT an Account.

Goal does not own money.

Goal does not create money.

Goal represents:

* Financial Objective
* Saving Target

Status:
[APPROVED]

---

# Goal Funding

Users never add money directly to Goals.

Money always remains inside Accounts.

Goals only reserve existing money.

Status:
[APPROVED]

---

# Goal Progress

Goal Progress is calculated.

Formula:

Progress

=

Reserved Amount
÷
Target Amount

Goal Progress must never be stored.

Status:
[APPROVED]

---

# Reserved Money

Reserved Money is an allocation layer.

Reserved Money does not create money.

Reserved Money does not affect Net Worth.

Reserved Money does not affect actual balances.

Reserved Money only affects Available Balance.

Status:
[APPROVED]

---

# Reserved Money Sources

Reserved Money is calculated from active allocations.

Formula:

Reserved Money

=

Sum(Active Allocations)

Possible Sources:

* Goal Allocations
* Saving Allocations
* Budget Surplus Allocations

Budgets themselves do not reserve money.

Budgets themselves do not move money.

A Budget Surplus Allocation is created only when the user explicitly chooses:

Move Remaining Budget To Saving

Reserved Money must never be stored.

Status:
[APPROVED]

---

# Available Balance

Available Balance is calculated.

Formula:

Available Balance

=

## Account Balance

Reserved Money

Example:

Balance = 10,000

Reserved = 3,000

Available = 7,000

Available Balance must never be stored.

Status:
[APPROVED]

---

# Budgets

Budget is NOT an Account.

Budget does not own money.

Budget does not create money.

Budget is used for:

* Spending Limits
* Spending Tracking
* Spending Analysis
* Spending Alerts

Status:
[APPROVED]

---

# Budget Surplus

Budget surplus does not move automatically.

Example:

Budget = 2000

Spent = 1500

Remaining = 500

Savings do NOT increase automatically.

The user must explicitly move the surplus.

Status:
[APPROVED]

---

# Budget Toggle

Users may choose:

* Budgets ON
* Budgets OFF

Budgeting is optional.

Status:
[APPROVED]

---

# Saving Circle

Official Name:

Saving Circle

ROSCA may be used internally when needed.

Status:
[APPROVED]

---

# Saving Circle States

Saving Circle has three states:

* Waiting
* Received
* Completed

Status:
[APPROVED]

---

## Waiting State

User contributes to the Saving Circle.

User has not received the payout yet.

Characteristics:

* Considered part of Savings
* No liability exists
* No borrowing event exists

Status:
[APPROVED]

---

## Received State

User received the payout.

User still has remaining installments.

Characteristics:

* Saving Circle remains visible in Savings
* Saving Circle Liability is created

Example:

Received Amount = 10,000

Remaining Installments = 9,000

Financial Effect:

Cash +10,000

Saving Circle Liability +9,000

Net Worth reflects only the real difference.

Status:
[APPROVED]

---

## Completed State

All installments are paid.

Characteristics:

* Remaining Liability = 0
* Saving Circle becomes completed
* May be archived

Status:
[APPROVED]

---

# Planning Relationship

Money Planning is responsible for:

* Goals
* Budgets
* Reserved Money
* Progress Tracking

Accounts explain where money exists.

Planning explains why money is allocated.

Status:
[APPROVED]

---

# Net Worth Protection Rule

Anything that does not create or destroy real money must never affect Net Worth.

Examples:

* Goals
* Budgets
* Virtual Saving
* Reserved Money
* Progress
* Analysis

Status:
[APPROVED]

---

# Final Architecture Rule

Accounts own money.

Transactions move money.

Real Saving moves money.

Virtual Saving reserves money.

Goals reserve money.

Budgets monitor money.

Budget Surplus Allocations may reserve money after explicit user action.

Saving Circle may create liabilities after payout.

Planning never owns money.

Only real Accounts affect Net Worth.

Status:
[APPROVED]
