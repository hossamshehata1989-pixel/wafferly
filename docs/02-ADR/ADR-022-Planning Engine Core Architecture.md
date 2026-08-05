ADR-022 — Planning Engine Core Architecture

Status: Accepted

Date: 2026-08-04

Context

After freezing the Financial Engine architecture, the Planning Domain required defining its own canonical architecture.

The system must support:

Goals
Budgets
Commitments
Scheduled Plans
Manual Reserve
Future Automation
Shared Books
Investments
Future Financial Products

without coupling the Planning Domain to the Financial Engine.

The primary question was:

What is the canonical write primitive of the Planning Domain?

Decision
1. Canonical Write Primitive

The Planning Domain adopts PlanningOperation as its only canonical write primitive.

All planning intents must be represented as PlanningOperations.

Examples:

Reserve
Release
Reallocate
Split
Merge
Adjust
Pause
Resume

No Planning Aggregate may modify Allocation directly.

2. Planning Engine Pipeline

Every PlanningOperation passes through the Planning Engine.

PlanningOperation

↓

Interpreter

↓

Domain Guards

↓

Policies

↓

Planner

↓

Integrity Checker

↓

Executor

↓

Allocation State

No alternative write path exists.

3. Allocation

Allocation represents the current reserved-money state.

Allocation:

has persistent identity
has lifecycle
has state
is mutable
is managed exclusively by the Planning Engine

Allocation is NOT:

the canonical primitive
an append-only event stream
the source of planning decisions
directly modified by Goals, Budgets, Automation, or UI

Allocation is a Managed Domain Entity.

4. PlanningOperation Log

Every executed PlanningOperation is stored in an immutable PlanningOperation Log.

The log exists for:

Audit
History
Diagnostics
Analytics
Future replay if required

This log is not an Event Store.

The Planning Domain intentionally does not implement full Event Sourcing.

5. Planning Truth

The Planning Domain distinguishes between:

Planning Decision

Represented by:

PlanningOperation Log
Current Planning State

Represented by:

Allocation

Planning decisions are immutable.

Allocation represents only the current state.

6. Automation

Automation never modifies Allocation.

Automation may only:

observe completion signals
evaluate rules
generate new PlanningOperations

Automation behaves as a command producer.

7. Source Aggregates

Planning Aggregates remain independent.

Examples:

Goal
Budget
Commitment
Schedule
Manual Reserve

Each Aggregate owns its own lifecycle.

They communicate with the Planning Engine exclusively by issuing PlanningOperations.

8. Financial Engine Boundary

Planning Engine never writes directly into the Financial Ledger.

Whenever real money must move:

PlanningOperation

↓

Planning Engine

↓

Application Layer

↓

FinancialOperation

↓

Financial Engine

Financial Truth remains completely independent.

9. Design Principles

The architecture follows:

Single write pipeline
Explicit user intent
Separation of Planning Truth and Financial Truth
No hidden write paths
No duplicated business rules
No direct Allocation mutations outside the Planning Engine
Consequences
Benefits
Clear separation of responsibilities.
Consistent architecture with the Financial Engine.
Easy addition of future planning features.
Centralized validation and policies.
Excellent auditability.
Low coupling between Planning and Financial domains.
Suitable for long-term evolution.
Trade-offs
Every planning change must pass through the Planning Engine.
Allocation cannot be modified directly.
Some operations require coordination with the Application Layer before reaching the Financial Engine.
Architectural Principles Frozen
PlanningOperation is the canonical planning primitive.
Planning Engine owns all planning mutations.
Allocation is a managed domain entity.
Automation is a command producer only.
Financial Engine remains the sole owner of Financial Truth.
Planning Domain intentionally avoids full Event Sourcing.
Notes

This ADR establishes the architectural foundation of the Planning Engine and should be considered frozen. Future features (Goals, Budgets, Commitments, Virtual Saving, Automation, Shared Books, Investments, etc.) must conform to these principles unless superseded by a later ADR.