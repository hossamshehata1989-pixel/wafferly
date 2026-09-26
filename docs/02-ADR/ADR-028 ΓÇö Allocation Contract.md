ADR-028 — Allocation Contract

Status: Accepted

Date: 2026-08-05

Decision Type: Core Architecture

Scope: Planning Engine

1. Context

PlanningOperation is the canonical planning write primitive.

Interaction Platform manages user interactions.

The Planning Engine requires a mutable operational state representing reserved money.

This state is Allocation.

2. Decision

Allocation is introduced as the operational state of the Planning Engine.

Allocation is the only mutable representation of reserved money.

All Allocation changes are performed exclusively by the Planning Engine.

No external component may modify Allocation directly.

3. Nature of Allocation

Allocation is:

Entity
Persistent Identity
Mutable
Versioned
Operational State

Allocation is NOT:

Source of Truth
Immutable Log
Event Store
Projection Cache
Aggregate Root

PlanningOperation remains the historical planning record.

Allocation represents the current operational state.

4. Ownership

Allocation belongs exclusively to the Planning Engine.

Goals

Budgets

Commitments

Manual Reserve

Automation

Interaction Platform

Financial Engine

must never update Allocation directly.

They request PlanningOperations.

5. Identity

Every Allocation owns a permanent identifier.

Identity survives:

Reserve
Partial Release
Reallocation
Pause
Resume

Identity changes only when a completely new Allocation is intentionally created.

6. Lifecycle

Allocation lifecycle:

Draft

↓

Active

↓

Paused

↓

Released

↓

Completed

↓

Cancelled

Terminal states:

Released
Completed
Cancelled

Terminal Allocations are never reactivated.

7. Versioning

Every Allocation contains:

version

The version increments after every successful mutation.

Planning Engine uses optimistic concurrency.

Concurrent conflicting updates must fail.

8. Mutation Policy

Allocation never exposes public mutation to external domains.

Every mutation originates from:

PlanningOperation

↓

Planning Engine

↓

Executor

The Executor is the exclusive mutation gateway.

9. Supported Mutations

Initially:

Create
Reserve
Partial Release
Full Release
Reallocate
Complete
Cancel

Future:

Pause
Resume
Split
Merge

The contract is Open/Closed.

10. Split & Merge Rules

Split creates new Allocation identities.

The original Allocation enters a terminal Split state (أو Released إذا فضلتوا عدم إضافة حالة Split).

Merge creates a new Allocation (or promotes one existing Allocation according to future policy).

Generated Allocation identities must be recorded by the originating PlanningOperation.

11. Planning Integrity

Allocation itself performs minimal invariant protection.

Examples:

cannot release more than allocated
terminal allocations cannot mutate
negative amount prohibited

Business policies remain inside:

Interpreter
Guards
Policies
Planner

Allocation never becomes a business rule engine.

12. Repository Contract

Repository responsibilities:

save
update
find
delete (soft only if policy allows)

Repository never calculates:

available balance
goal progress
virtual saving

Repositories persist only.

13. Read Model Boundary

Allocation is operational state.

UI never depends directly on Allocation.

User interfaces consume:

GoalFundingProjection
BudgetProjection
AvailableBalanceProjection
VirtualSavingProjection

Allocation remains an internal planning model.

14. Relationship with Financial Engine

Allocation never moves money.

Moving money always requires:

PlanningOperation

↓

FinancialOperation

↓

Financial Engine

Reserved money and actual money remain independent concepts.

15. Recovery

If Allocation storage is lost:

PlanningOperation Log is sufficient to reconstruct Allocation state.

Reconstruction must preserve generated Allocation identities recorded in the immutable operation history.

16. Architectural Principles

Allocation follows:

Single ownership
Mutable operational state
Immutable history
Versioned updates
No business orchestration
No cross-domain mutation
Deterministic reconstruction
17. Explicit Non-Goals

Allocation is not:

Goal progress
Budget progress
Virtual Saving
Available Balance
Financial Ledger

Those are independent read models.

18. ADR Outcome

Allocation becomes the exclusive operational state managed by the Planning Engine.

PlanningOperation remains the immutable planning history.

The Planning Engine becomes the only component capable of translating immutable planning decisions into mutable Allocation state.