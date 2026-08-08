# ADR-031 — Money Reservation Architecture

**Status:** Accepted

**Date:** 2026-08-07

**Related ADRs**

- ADR-028 Planning Engine
- ADR-029 Accounts Architecture
- ADR-030 Transaction Engine

---

# Context

Wafferly separates financial responsibilities into multiple engines.

The system must support reserving money for Goals and future Planning Sources without duplicating financial data or introducing synchronization problems.

The architecture must remain extensible for future Planning Sources such as:

- Goals
- Budgets
- Envelopes
- Saving Rules
- Future Planning Modules

---

# Decision

Money reservation is represented exclusively by **Allocations**.

Accounts own money.

Planning owns reservations.

Goals own purpose.

Each domain has a single responsibility.

---

# Source of Truth

## Accounts

Responsible for:

- Account Balance
- Financial ownership
- Money movement through Transactions

Accounts are the only source of truth for money.

---

## Planning

Responsible for:

- Reserved Money
- Allocation lifecycle
- Reservation planning

Planning never owns account balances.

---

## Goals

Responsible for:

- Saving purpose
- Metadata
- Target amount
- Progress presentation

Goals never own money.

---

# Allocation

Allocation represents reserved money.

It is the only object allowed to represent reserved funds.

Example

Cash

5000

↓

Allocation

1000

↓

Vacation Goal

The money still belongs to the Cash account.

The Goal never owns the money.

---

# Goal

A Goal represents intent only.

A Goal never stores:

- Balance
- Reserved Amount
- Available Amount
- Allocation list

Relationships are resolved through AllocationRepository.

---

# Reserved Money

Reserved money is computed exclusively from Allocations.

Reserved money must never be duplicated inside Account.

Reserved money must never be duplicated inside Goal.

---

# Available Money

Available money is derived.

Formula

Available

=

Account Balance

−

Reserved Money

Reserved Money

=

SUM(Active Allocations for Account)

Available is never persisted.

---

# Planning Sources

Planning Engine is generic.

Allocations reference Planning Sources using:

- sourceType
- sourceId

The engine never depends directly on Goal.

Future Planning Sources may include:

- Goal
- Budget
- Envelope
- Saving Rule

without modifying the Planning Engine.

---

# Goal Progress

Funding progress is computed.

Progress

=

SUM(Allocations for Goal)

The Goal entity never stores current reserved amount.

---

# Reserve Operation

Reserve never creates a financial transaction.

Reserve never changes Account Balance.

Reserve only creates an Allocation.

---

# Release Operation

Release decreases or removes an Allocation.

It does not modify Account Balance.

---

# Split Operation

Split transfers part of one Allocation into another Planning Source.

Money ownership remains inside the same Account.

---

# Merge Operation

Merge combines two Allocations into one.

The source Allocation becomes inactive.

---

# Reallocate Operation

Reallocate transfers part of an Allocation.

Rule

amount < source allocation

Reallocate

amount == source allocation

Merge

---

# Planning Engine Boundary

Planning Engine is treated as a black box.

Application Layer communicates only through

PlanningEngine.execute()

Application Layer has no knowledge of:

- Planner
- Executor
- Mutations
- Guards
- Policies

---

# Infrastructure

Planning Domain remains infrastructure-independent.

Domain Entities must not depend on Hive.

Persistence is implemented through:

Allocation

↓

AllocationMapper

↓

AllocationRecord

↓

HiveAllocationRepository

The Domain layer never imports Hive.

---

# Memory Repository

MemoryAllocationRepository exists only for:

- Domain development
- Unit tests
- Early feature implementation

Production storage will use HiveAllocationRepository.

The Planning Engine must not change when replacing repositories.

---

# Architectural Principles

- Single Source of Truth
- No duplicated financial state
- Accounts own money
- Planning owns reservations
- Goals own purpose
- Derived values are never persisted
- Planning is extensible through Planning Sources
- Infrastructure never leaks into Domain

---

# Consequences

Benefits

- No synchronization issues.
- Unlimited future Planning Sources.
- Clean separation of responsibilities.
- Stable Planning Engine.
- Independent persistence implementation.
- Easier testing.
- Future database migration without touching Domain.

Trade-offs

- Some values are calculated dynamically.
- UI must aggregate data from Accounts and Planning.
- Progress is projection-based rather than stored.