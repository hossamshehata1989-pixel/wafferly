Wafferly V4 Architecture

Status: APPROVED

Phase: V4 Foundation

Last Updated: Phase 4

Vision

Wafferly is a Financial Planning Platform.

The architecture is designed around a strict separation between:

Financial Truth
Planning
Computation
Insights

The system is:

Offline First
Projection Driven
Forecast Ready
AI Ready
Shared Finance Ready
Core Principles

Accounts own money.

Transactions move money.

Allocations represent planning intent.

Goals explain purpose.

Budgets monitor spending.

Commitments represent expected future events.

Liabilities represent current obligations.

Members are actors, not money owners.

Financial Truth Layer

Source Of Truth:

Accounts
Transactions
Ledger
Allocations
Commitments
Liabilities
Investments
Members

Financial Truth is the only layer allowed to store financial reality.

Everything else is derived.

Accounts Layer

Accounts own money.

Examples:

Cash
Wallet
Bank
Real Saving Accounts
Borrowed
Lent
Temporary Debt
Investment Accounts

Only Accounts affect Net Worth.

Transactions Layer

Transactions represent real money movement.

Examples:

Income
Expense
Transfer
Borrow
Lend
Debt Settlement

Rule:

Record what actually happened.

Never create artificial transactions.

Ledger Layer

Ledger is the financial engine.

Architecture:

Transactions
↓
Ledger
↓
Balances

All balances must be derived from Ledger activity.

Obligations Layer
Liabilities

Current obligations.

Examples:

Loan
Installment
Borrowed Money
Temporary Debt
Saving Circle Liability

Liabilities affect:

Net Worth
Future Obligations
Financial Position
Scheduling Layer
Recurring Engine

Recurring Engine is scheduling infrastructure.

Responsible for:

Frequency
Reminder
Auto Create
Pause
Resume
Skip
End Date

Recurring Engine never owns money.

Recurring Engine never owns balances.

Commitment Layer

Commitments represent expected future events.

Examples:

Bills
Subscriptions
Rent
Salary
Loan Payments
Installment Payments

Commitments are NOT Liabilities.

Liabilities exist now.

Commitments are expected future events.

Planning Layer

Planning never owns money.

Planning explains financial intent.

Components:

Goals
Budgets
Allocations
Allocations

Allocations are the Planning Source Of Truth.

Allocations never own money.

Allocations only reference money already existing inside Accounts.

Allocation Types:

Goal Allocation
Saving Allocation
Budget Surplus Allocation

Creating an Allocation must never create money.

Deleting an Allocation must never delete money.

Goals

Goals represent purpose.

Goals do not own money.

Goals do not have balances.

Goals store:

Metadata
Lifecycle State
Activities

Goals expose:

Funding Sources Projection
Progress Projection
Goal Funding Architecture

Funding Sources represent:

Current State

Goal Activities represent:

History

Goal Progress represents:

Achievement

These concepts are independent.

Funding Types
Reserved Funding

Money remains inside source accounts.

Saving Funding

Money exists inside real Saving Accounts.

Goal Progress

Goal Progress

=

Total Reserved
+
Total Saved

Goal Progress is a Projection.

Goal Progress must never be stored.

Budgets

Budgets represent monitoring.

Budgets do not own money.

Budgets do not move money.

Budgets are used for:

Spending Control
Spending Analysis
Spending Alerts

Budget Remaining is a Projection.

Projection Layer

Projection Layer contains:

Funding Sources
Reserved Money
Available Balance
Goal Progress
Budget Remaining

Projections are:

Read Only
Derived
Recomputable

Projections are never Source Of Truth.

Projection Services Rule

Projection Services must remain synchronous.

Projection Services:

Read local state only
Never perform network requests
Never query Supabase
Never call remote APIs

Architecture:

UI
↓
Projection Services
↓
Hive

Sync Services
↓
Supabase
Forecasting Layer

Forecasting predicts future financial outcomes.

Examples:

Future Balance
Future Available Balance
Future Cash Flow
Future Obligations
Goal Forecasts

Forecasting is not Source Of Truth.

Forecasting is prediction only.

Forecasting Rule

Forecasting Layer must read directly from:

Accounts
Transactions
Ledger
Allocations
Commitments
Liabilities
Goals
Budgets

Forecasting must never use Projection Layer as a source of truth.

Analytics Layer

Analytics derives insights.

Examples:

Reports
Trends
Net Worth Analysis
Spending Analysis
Budget Analysis

Analytics must read directly from Financial Truth.

Analytics must never depend on Projection Layer.

Investments Domain

Investments are separate from Savings.

Examples:

Gold
Stocks
Mutual Funds
Crypto Assets

Investment Assets belong to the Investment Domain.

They are not Saving Accounts.

Shared Finance Layer

Members are actors.

Members are not money containers.

Members do not own balances.

Members may be:

Owners
Participants
Permission Holders
Permissions
Owner
Editor
Viewer
Shared Finance Components
Shared Accounts
Shared Goals
Shared Budgets
Shared Liabilities

Accounts still own money.

Members never own money.

AI Layer

AI is a Decision Support Layer.

AI is not a financial domain.

Source Layer

AI reads directly from:

Accounts
Transactions
Ledger
Allocations
Goals
Budgets
Commitments
Liabilities
Investments
Members

AI must not use derived views as source of truth.

Context Layer

Financial Context Builder

Creates:

Smart Snapshot
Memory Scope
Financial Context
Recommendation Layer

Provides:

Recommendations
Alternatives
Impact Analysis
Action Layer

AI may suggest actions.

AI may never perform autonomous financial changes.

User confirmation is always required.

Computation Independence Rule

Derived systems must never use other derived systems as their source of truth.

Allowed:

Truth
↓
Computation

Forbidden:

Computation
↓
Computation
Independent Computation Layers

Financial Truth
│
├── Projection
│
├── Forecasting
│
├── Analytics
│
└── AI

Each computation layer reads directly from Financial Truth.

Golden Rules

Accounts own money.

Transactions move money.

Allocations represent planning intent.

Funding Sources represent current state.

Activities represent history.

Goal Progress measures achievement.

Commitments represent expected future events.

Liabilities represent current obligations.

Members are actors.

Planning never owns money.

Projection never owns money.

Forecasting never owns money.

Analytics never owns money.

AI never owns money.

Financial Truth
↓
Independent Computation Layers.

Current V4 Status

Stable Domains:

Accounts
Transactions
Ledger
Liabilities
Goals
Allocations
Budgets
Recurring
Commitments
Projection Layer
Forecasting Layer
Investments
Shared Finance
AI Architecture

Wafferly V4 Foundation Status:

APPROVED ✅