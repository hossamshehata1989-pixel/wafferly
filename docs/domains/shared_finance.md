# Shared Finance Domain

Status: APPROVED

Domain: Shared Finance

Version: V4

---

# Purpose

Shared Finance enables multiple Members to collaborate on financial entities.

Examples:

* Family Finance
* Couple Finance
* Team Finance
* Group Finance

Shared Finance adds participation.

Shared Finance does not change money ownership.

---

# Core Rule

Members are actors.

Accounts own money.

Members never own money.

Members never own balances.

---

# Member Model

Member

=

Actor

A Member may be:

* Owner
* Participant
* Contributor
* Permission Holder

Members interact with financial entities.

Members are not financial containers.

---

# Permissions

Supported Roles:

## Owner

Can:

* Manage everything
* Edit
* Delete
* Manage members
* Manage permissions

---

## Editor

Can:

* Create transactions
* Edit transactions
* Create goals
* Edit goals
* Manage budgets

Cannot manage ownership.

---

## Viewer

Read-only access.

Can view data only.

---

# Shared Accounts

Shared Accounts are real Accounts.

Examples:

* Family Account
* Couple Account
* Business Account

Shared Accounts belong to the Accounts Layer.

Shared Accounts own money.

---

# Shared Account Rule

Money belongs to the Account.

Not to Members.

Example:

Family Account

Balance = 20000

Members:

* Ahmed
* Sara
* Ali

Result:

Family Account owns 20000.

Members own nothing.

---

# Shared Goals

Shared Goals support contribution tracking.

Example:

Family Vacation

Ahmed = 5000

Sara = 3000

Ali = 2000

---

# Shared Goal Rule

Contribution tracking is metadata.

Contribution tracking does not create Member Balances.

Money ownership remains with Accounts.

---

# Shared Budgets

Shared Budgets support:

* Contribution Tracking
* Spending Tracking
* Overspending Analysis

Per Member.

---

# Shared Budget Rule

Budgets remain Budget entities.

Member contributions are analytical data.

No Member Balance is created.

---

# Shared Liabilities

Shared Liabilities support ownership percentages.

Examples:

Home Loan

Ahmed = 50%

Sara = 50%

---

Car Loan

Ahmed = 70%

Sara = 30%

---

# Shared Liability Rule

Ownership percentages represent responsibility.

Not money ownership.

Liabilities remain Liability entities.

---

# Shared Transactions

Transactions may contain:

* Owner
* Participants

Example:

Dinner Expense

Owner:

Ahmed

Participants:

Ahmed
Sara
Ali

---

# Shared Transaction Rule

Participation tracking does not affect money ownership.

Accounts still own money.

Transactions still move money.

---

# Net Worth

Supported Views:

## Individual Net Worth

Per Member.

---

## Shared Net Worth

Examples:

* Family Net Worth
* Couple Net Worth
* Team Net Worth

---

# Net Worth Rule

These are analytical views.

They do not create Member-owned money.

---

# Relationship With Accounts

Accounts own money.

Members interact with money.

Accounts remain the financial owner.

---

# Relationship With Goals

Members may:

* Create Goals
* Fund Goals
* Contribute To Goals

Goals remain Goal entities.

Members do not own Goal balances.

---

# Relationship With Budgets

Members may:

* Fund Budgets
* Spend Against Budgets

Budgets remain Budget entities.

Members do not own Budget balances.

---

# Relationship With Forecasting

Forecasting may generate:

* Individual Forecasts
* Family Forecasts
* Shared Forecasts

Forecasting reads shared entities directly.

---

# Relationship With AI

AI may generate:

* Family Insights
* Shared Budget Insights
* Shared Goal Insights
* Shared Liability Insights

AI must never assign money ownership to Members.

---

# Source Of Truth

Financial ownership remains:

Accounts
↓
Transactions
↓
Ledger

Only

Shared Finance adds:

* Participation
* Responsibility
* Permissions
* Contribution Tracking

---

# Summary

Members are actors.

Accounts own money.

Shared Finance enables collaboration.

Shared Finance never introduces:

* Member Wallets
* Member Balances
* Member-Owned Money

Status:

APPROVED
