# Phase 2 — Planning Layer

Status: COMPLETED

Version: V4

---

# Goal

Transform Wafferly from an expense tracker into a financial planning platform.

Introduce planning without violating financial truth.

---

# Domains

Completed:

- Allocations
- Goals
- Goal Funding
- Goal Completion
- Goal Transfer To Saving
- Budget Architecture
- Budget Funding
- Multi-Source Funding

---

# Major Architectural Decisions

## Goal Does Not Own Money

Goal

=

Purpose Only

Goals do not contain:

- Balance
- Saved Amount
- Current Amount
- AccountId

---

## Funding-Centric Architecture

Old Thinking:

Goal owns money.

---

New Thinking:

Accounts own money.

Activities describe history.

Funding Sources describe current state.

Goals describe purpose.

---

## Funding Sources

Funding Sources

=

Current State

Funding Sources are projections.

Funding Sources are not stored.

---

## Goal Activities

Goal Activities

=

History

Examples:

- Reserve
- Release
- Transfer To Saving
- Complete
- Cancel
- Archive

Activities are immutable.

---

## Goal Progress

Goal Progress

=

Total Reserved
+
Total Saved

Goal Progress is a projection.

Goal Progress must never be stored.

---

## Reserved Funding

Money remains inside source accounts.

Example:

Cash Reserved = 500

---

## Saving Funding

Money exists inside real Saving Accounts.

Example:

Emergency Fund = 500

---

## Partial Transfer To Saving

Supported.

Example:

Reserved = 600

Transfer = 200

Result:

Reserved = 400

Saved = 200

Progress = 600

---

## Transfer To Saving

Transfer To Saving

=

Real Financial Operation

Creates:

- Transfer Transactions
- Goal Activities
- Goal Allocation Releases

Creates NO Saving Allocations.

---

## Source Traceability

Every funding source must preserve traceability.

Example:

Cash → Emergency Fund

Wallet → Emergency Fund

Bank → Emergency Fund

Separate transfers required.

---

## Saving Accounts

Saving Accounts are real Accounts.

Examples:

- Emergency Fund
- Vacation Fund
- Home Safe
- Savings Bank Account

Saving Accounts affect Net Worth.

---

## Virtual Saving

Virtual Saving

=

Projection Layer

Virtual Saving is not a real Account.

Virtual Saving owns no money.

---

## Allocation Architecture

Allocations

=

Planning Source Of Truth

Allocations represent planning intent.

Allocations never own money.

---

## Budget Architecture

Budget Types:

- Monitoring Budget
- Protected Budget

---

## Budget Funding

Multi-source funding supported.

Example:

Cash
Bank
Wallet

↓

Food Budget

---

## Budget Remaining

Budget Remaining

=

Projection

Never stored.

---

# Projection Services Introduced

- GoalFundingProjectionService
- BudgetProjectionService

Rule:

Projection Services own derived calculations.

UI never calculates business state.

---

# Core Rules Established

Accounts own money.

Allocations represent planning intent.

Goals explain purpose.

Budgets monitor spending.

Funding Sources represent current state.

Activities represent history.

Goal Progress represents achievement.

---

# Outcome

Planning Layer completed.

Architecture:

Accounts
↓
Allocations
↓
Goals

Accounts
↓
Allocations
↓
Budgets

Status:

COMPLETED