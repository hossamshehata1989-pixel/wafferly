# ADR-0012 — Financial Engine is the only writer of Financial Truth.

**Status:** Accepted

**Date:** 2026-07-10

**Scope:** Financial Engine / Application Layer / Transactions

---

# Context

During the integration of the Financial Engine into Wafferly V4, we discovered that the Engine successfully executes the complete financial pipeline:

FinancialOperation
        ↓
Interpreter
        ↓
Domain Guard
        ↓
Policy
        ↓
Planner
        ↓
Integrity Checker
        ↓
Executor
        ↓
OperationSucceeded

However, after a successful execution:

- No Transaction is stored in Hive.
- Account balances do not change.
- Analysis pages remain unchanged.
- Transaction History remains empty.

Investigation showed that the current FinancialExecutionPlan only produces:

- JournalEntryMutation

while the rest of the application still considers Transaction as the source of financial truth.

Currently, Transactions are created only through the legacy TransactionService.

---

# Problem

The Financial Engine currently produces accounting journal entries but does not produce the application's financial truth.

This creates two independent write paths:

Legacy Flow

UI
    ↓
TransactionService
    ↓
Hive Transaction
    ↓
Ledger

New Engine Flow

UI
    ↓
Financial Engine
    ↓
JournalEntryMutation
    ↓
Memory Journal

As a result:

- Engine execution succeeds.
- No Transaction exists.
- BalanceService cannot detect any change.
- Analysis cannot detect any change.
- History remains empty.

---

# Decision

The Financial Engine becomes the single writer of Financial Truth.

The Engine is responsible for producing all financial events
(Transaction, Journal, Allocation, Goal Activity).

However, the authoritative financial state remains the Account model.

Accounts remain the only Source of Truth for financial balances and net worth.

The Engine never replaces Accounts as the source of truth; it only becomes the exclusive path through which financial state changes are written.
The Engine must produce every persistent financial mutation required by the application.

For Expense operations, the execution plan must include:

FinancialExecutionPlan

    ├── CreateTransactionMutation
    ├── JournalEntryMutation
    ├── AllocationMutation (when needed)
    └── GoalActivityMutation (when needed)

The Executor becomes responsible for executing all mutations.

---

# Transaction Creation

Transaction creation becomes a Financial Mutation.

A new mutation will be introduced:

CreateTransactionMutation

The corresponding handler:

HiveTransactionMutationHandler

will persist the Transaction into Hive.

---

# Dependency Rule

The Financial Engine MUST NOT depend on:

- TransactionService
- LedgerService
- BalanceService
- UI
- Controllers

Instead, it depends only on Ports.

Example:

Financial Engine

        ↓

TransactionPort

        ↓

HiveTransactionAdapter

        ↓

Hive

---

# Why not TransactionService?

TransactionService is currently a legacy orchestration service containing:

- CRUD
- Ledger integration
- Query helpers
- Analytics helpers
- Legacy behaviors

Using it from inside the Engine would violate Dependency Inversion and reintroduce the legacy flow into the Engine.

Instead, reusable persistence logic should be extracted behind Ports.

---

# Architectural Principle

Financial Truth has exactly one writer.

Financial Engine

        ↓

Transaction
Journal
Allocation
Goal Activity

Every financial state mutation originates from the Engine.

No UI or Service is allowed to bypass the Engine when changing Financial Truth.

---

# Migration Strategy

Sprint 1

✅ Expense

- Add CreateTransactionMutation
- Add HiveTransactionMutationHandler
- Register handler
- Planner produces Transaction + Journal mutations

Sprint 2

Income

Sprint 3

Transfer

Sprint 4

Infrastructure Completion

Sprint 5

Engine Stabilization

Sprint 6

Architecture Cleanup

---

# Consequences

Benefits

- Single Entry Point for Financial Truth.
- Engine becomes the authoritative write model.
- BalanceService automatically works.
- Analysis automatically works.
- Transaction History automatically works.
- Journal remains independent.
- Future CQRS becomes easier.

Trade-offs

- Additional TransactionPort abstraction.
- New Mutation and Handler.
- Migration effort from legacy write flow.

These trade-offs are accepted because they significantly improve architectural consistency.

---

# Accepted Principle

Financial Truth always originates from the Financial Engine.

Legacy services become orchestration or query services only.

The Financial Engine is the only component allowed to mutate Financial Truth.

---

## Architecture Rule

No financial data may be written outside the Financial Engine.

If a feature changes:

- Account balances
- Transactions
- Ledger
- Allocations
- Goals

it MUST pass through the Financial Engine.

Any direct write to persistence is considered an architectural violation.


Architecture Rule

Accounts remain the only Source of Truth.

Financial Engine remains the only Writer of Financial Truth.

These two concepts are different and must never be confused.