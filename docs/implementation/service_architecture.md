# Service Architecture

Status: APPROVED

Category: Implementation

Version: V4

---

# Purpose

Define how business logic is organized inside Wafferly.

Services contain business rules.

Services do not own financial truth.

Services coordinate domain operations.

---

# Core Rule

Models store data.

Services execute business logic.

Projection Services calculate derived state.

UI displays results.

---

# Architecture

UI
↓
Controllers / ViewModels
↓
Services
↓
Repositories
↓
Hive
↓
Sync Services
↓
Supabase

---

# Service Categories

## Domain Services

Contain business logic.

Examples:

- GoalService
- BudgetService
- AccountService
- LiabilityService
- CommitmentService

---

## Projection Services

Contain derived calculations.

Examples:

- GoalFundingProjectionService
- AvailableBalanceProjectionService
- ReservedMoneyProjectionService
- BudgetProjectionService

Projection Services never own data.

Projection Services never store data.

---

## Validation Services

Contain business validation.

Examples:

- AllocationValidator
- GoalValidator
- BudgetValidator

---

## Repository Layer

Responsible for persistence.

Examples:

- GoalRepository
- BudgetRepository
- AccountRepository

Repositories do not contain business rules.

---

## Sync Services

Responsible for synchronization.

Examples:

- GoalSyncService
- AccountSyncService
- BudgetSyncService

Sync Services communicate with Supabase.

---

# Projection Services Rule

Projection Services must remain synchronous.

Projection Services read only from local hydrated state.

Projection Services must never:

- Call APIs
- Query Supabase
- Perform network requests

Architecture:

UI
↓
Projection Services
↓
Hive

---

# Source Of Truth Rule

Services never become source of truth.

Financial truth remains:

- Accounts
- Transactions
- Ledger
- Allocations
- Commitments
- Liabilities

---

# Computation Independence Rule

Projection Services must calculate independently.

Forbidden:

Projection
↓
Projection

Example:

Goal Progress
↓
Forecast

Not Allowed.

Correct:

Allocations
↓
Goal Progress

Allocations
↓
Forecast

---

# Domain Ownership

Goals Domain

- GoalService
- GoalFundingProjectionService

---

Budgets Domain

- BudgetService
- BudgetProjectionService

---

Accounts Domain

- AccountService
- AvailableBalanceProjectionService

---

Liabilities Domain

- LiabilityService

---

Commitments Domain

- CommitmentService

---

# Offline First Rule

All services operate on local data first.

Synchronization happens separately.

User experience must not depend on network availability.

---

# Summary

Services execute logic.

Repositories store data.

Projection Services calculate derived state.

Sync Services communicate with remote systems.

Financial truth remains independent from service implementations.

Status:

APPROVED