Wafferly Financial Rules

Status: APPROVED

Scope: Global Financial Rules

Version: V4

Purpose

This document contains the financial rules that must never be violated.

These rules apply to all domains, services, projections, forecasts, analytics, and AI systems.

If any implementation conflicts with these rules:

The implementation is wrong.

The rules are correct.

Rule 1
Accounts Own Money

Accounts are the only entities that own money.

Examples:

Cash
Wallet
Bank
Real Saving Accounts
Investment Accounts
Borrowed
Lent
Temporary Debt

Goals do not own money.

Budgets do not own money.

Allocations do not own money.

Members do not own money.

Rule 2
Transactions Move Money

Real money movement must be represented by Transactions.

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

Rule 3
Ledger Is Financial Truth

Balances must be derived from Ledger activity.

Architecture:

Transactions
↓
Ledger
↓
Balances

Never store balances as a competing source of truth.

Rule 4
Allocations Represent Planning Intent

Allocations are the Planning Source Of Truth.

Allocations:

Reference money
Reserve money
Explain intent

Allocations never:

Own money
Create money
Delete money

Creating an Allocation must never create money.

Deleting an Allocation must never delete money.

Rule 5
Planning Never Owns Money

Planning Layer contains:

Goals
Budgets
Allocations

Planning explains money.

Planning never owns money.

Rule 6
Goals Explain Purpose

Goals answer:

Why am I saving?

Goals:

Do not own money
Do not own balances
Do not own accounts

Goals store:

Metadata
Lifecycle State
Activities

Goal Funding State must be derived.

Rule 7
Budgets Monitor Spending

Budgets exist for:

Spending Control
Spending Analysis
Spending Alerts

Budgets do not own money.

Budgets do not move money.

Budget state must be derived.

Rule 8
Commitments Are Expected Future Events

Commitments represent expected future financial events.

Examples:

Bills
Subscriptions
Rent
Salary
Loan Payments
Installment Payments

Commitments are not liabilities.

Rule 9
Liabilities Are Current Obligations

Liabilities represent obligations that already exist.

Examples:

Loan
Installment
Borrowed Money
Temporary Debt
Saving Circle Liability

Liabilities affect Net Worth.

Rule 10
Members Are Actors

Members are:

Owners
Participants
Permission Holders

Members are not money containers.

Members never own balances.

Members never own money.

Accounts still own money.

Rule 11
Single Source Of Truth Rule

Money must exist in exactly one place:

Accounts

Everything else is derived.

Never duplicate financial truth.

Rule 12
Funding Sources Represent Current State

Funding Sources represent current funding state.

Funding Sources are projections.

Funding Sources are not historical records.

Funding Sources are not source of truth.

Rule 13
Activities Represent History

Activities are historical records.

Examples:

Reserve
Release
Transfer To Saving
Complete Goal
Cancel Goal

Activities represent history only.

Activities do not represent current state.

Rule 14
Never Store Derived Values

Derived values must always be calculated.

Examples:

Goal Progress
Budget Remaining
Available Balance
Reserved Money
Funding Sources

Never store derived values as source of truth.

Rule 15
Projection Ownership Rule

All derived values belong to Projection Services.

Examples:

GoalFundingProjectionService
BudgetProjectionService
AvailableBalanceProjectionService
ReservedMoneyProjectionService

UI must never calculate business state.

Rule 16
Projection Services Rule

Projection Services must remain synchronous.

Projection Services:

Read local state only
Never call APIs
Never query Supabase
Never perform network requests

Architecture:

UI
↓
Projection Services
↓
Hive

Sync Services
↓
Supabase
Rule 17
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
Rule 18
Financial Truth → Independent Computation Layers

Financial Truth:

Accounts
Transactions
Ledger
Allocations
Commitments
Liabilities

Independent Computation Layers:

Projection
Forecasting
Analytics
AI

Each layer must read directly from Financial Truth.

Rule 19
Forecasting Is Prediction

Forecasting is not financial truth.

Forecasting must:

Read from Financial Truth
Compute independently

Forecasting must never use Projection Layer as source of truth.

Rule 20
AI Is Advisory

AI is a decision-support system.

AI may:

Explain
Recommend
Compare alternatives
Analyze impact

AI may not:

Move money automatically
Create debt automatically
Release allocations automatically
Perform financial actions without confirmation

User confirmation is always required.

Final Principle
Accounts own money.

Transactions move money.

Allocations represent planning intent.

Funding Sources represent current state.

Activities represent history.

Goals explain purpose.

Budgets monitor spending.

Commitments represent expected future events.

Liabilities represent current obligations.

Members are actors.

Financial Truth
↓
Independent Computation Layers.

Status:

APPROVED ✅