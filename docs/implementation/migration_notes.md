# Migration Notes

Status: APPROVED

Category: Implementation

Version: V4

---

# Purpose

Track architectural migrations.

Document transitions from legacy structures to V4 architecture.

Prevent accidental reintroduction of deprecated concepts.

---

# Migration Strategy

Migration must be gradual.

Existing features must continue working while new architecture is introduced.

Avoid large destructive refactors.

---

# Allocation Migration

Status:

IN PROGRESS

---

Old Architecture

ReservedMoney
↓
Direct Feature Logic

---

New Architecture

Allocations
↓
Projection Services
↓
Features

---

Rule

Allocations become the Planning Source Of Truth.

Reserved Money becomes a Projection.

---

# Reserved Money Migration

Status:

APPROVED

---

Reserved Money is no longer considered long-term source of truth.

Reserved Money becomes:

Projection Layer

Formula:

Reserved Money

=

Sum(Active Allocations)

---

Rule

Do not add major new functionality to ReservedMoney models.

New planning features must use Allocations.

---

# Goal Migration

Status:

APPROVED

---

Old Goal Architecture

Goal

- Balance
- Saved Amount
- Account Binding

---

New Goal Architecture

Goal

- Metadata
- Lifecycle
- Activities
- Configuration

---

Rule

Goal does not own money.

Goal does not contain AccountId.

Goal Progress is derived.

---

# Goal Funding Migration

Status:

APPROVED

---

Old Thinking

Goal
↓
Owns Funding

---

New Thinking

Funding Sources
↓
Current State

Activities
↓
History

Goal Progress
↓
Achievement

---

Rule

Funding Sources become the current funding state.

---

# Saving Architecture Migration

Status:

APPROVED

---

Real Saving Account

Belongs To:

Accounts Layer

Owns Money

---

Virtual Saving

Belongs To:

Planning Layer

Projection Only

Owns Nothing

---

Rule

Never treat Virtual Saving as a real account.

---

# Transfer To Saving Migration

Status:

APPROVED

---

Transfer To Saving

=

Real Financial Operation

Creates:

- Transfer Transactions
- Goal Activities
- Allocation Releases

Creates NO Saving Allocations.

---

# AllocationType.saving

Status:

UNDER REVIEW

---

Current Understanding

AllocationType.saving

represents:

Saving Intent

inside Planning Layer.

---

Rule

No architectural expansion until full review is completed.

---

# Forecasting Migration

Status:

APPROVED

---

Old Risk

Forecast
↓
Projection

---

New Rule

Forecast
↓
Financial Truth

---

Rule

Forecasting must never use Projection Layer as source of truth.

---

# Shared Finance Migration

Status:

APPROVED

---

Rule

Members are actors.

Members are not balances.

Members are not wallets.

Members do not own money.

Accounts own money.

---

# Investment Migration

Status:

APPROVED

---

Rule

Gold

≠

Saving

Gold

=

Investment

---

Same Rule Applies To:

- Stocks
- ETFs
- Mutual Funds
- Crypto

---

# Projection Migration

Status:

APPROVED

---

Never Store:

- Available Balance
- Goal Progress
- Reserved Money
- Budget Remaining
- Funding Sources

Always derive them.

---

# Future Migration Notes

Record future architectural transitions here.

Every major architecture decision should be documented before implementation.

---

# Summary

Migrations must be incremental.

Architecture drives migration.

Financial truth remains stable.

Derived state must remain derived.

Status:

APPROVED