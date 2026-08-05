ADR-024- Allocation Lifecycle & Ownership
Status: Accepted

Date: 2026-08-04

Supersedes: None

Context

The Planning Engine architecture has been frozen (ADR-017).

The Planning Domain requires a single representation of reserved money that supports:

Goals
Budgets
Commitments
Scheduled Plans
Manual Reserve
Future Planning Features

The lifecycle, ownership, and mutation rules of Allocation must be defined before implementation begins.

Decision
1. Allocation Identity

Every Allocation has a permanent unique identity.

The Allocation ID is immutable and never reused.

The identity remains stable throughout the Allocation lifecycle.

2. Allocation Responsibility

Allocation represents the current reserved-money state.

Allocation is responsible for representing:

current reserved amount
current status
current owner
current planning relationship

Allocation is not responsible for:

planning decisions
business workflow
policy enforcement
financial execution

Those responsibilities belong exclusively to the Planning Engine.

3. Allocation Ownership

Allocation is a Managed Domain Entity.

Only the Planning Engine may mutate Allocation.

No component may modify Allocation directly, including:

UI
Goals
Budgets
Commitments
Schedules
Manual Reserve
Automation
Application Services
Repositories

Every mutation must originate from a PlanningOperation executed through the Planning Engine.

4. Allocation Lifecycle

Official lifecycle states are:

Draft
Active
Paused
Completed
Released
Cancelled
Draft

Allocation has been created but is not yet active.

No money is considered reserved.

Active

Money is currently reserved.

The Allocation contributes to Reserved Money calculations.

Paused

Reservation is temporarily suspended.

Reserved money is excluded from Available Balance calculations.

The Allocation may later return to Active.

Completed

The planning objective has been fulfilled.

Examples:

Goal achieved
Commitment fulfilled
Budget period finished

Completion does not imply:

money transfer
releasing reserved money
automatic financial execution

Completion only indicates that the planning objective has been achieved.

Subsequent actions remain explicit user decisions.

Released

Reserved money has been released.

The Allocation becomes read-only.

Cancelled

The reservation has been abandoned.

The Allocation becomes read-only.

5. State Transitions

The official lifecycle is:

Draft
  │
  ▼
Active
 ├────────► Paused
 ├────────► Completed
 ├────────► Released
 └────────► Cancelled

Paused
 ├────────► Active
 ├────────► Released
 └────────► Cancelled

Terminal states:

Completed
Released
Cancelled

Terminal Allocations cannot return to Active.

6. Allocation Mutations

Planning Engine supports the following Allocation mutations:

Reserve
Release
Reallocate
Adjust
Pause
Resume
Complete
Cancel

No other mutation types are supported in V1.

7. Partial Release

Partial Release is supported.

Example:

Reserved = 1000

Release 300

↓

Reserved = 700

Allocation identity remains unchanged.

8. Reallocation

Reallocation moves all or part of reserved money between planning sources.

Examples:

Goal → Goal
Goal → Manual Reserve
Budget → Goal
Manual Reserve → Commitment

Reallocation is a planning operation only.

It never creates Financial Truth.

It never moves real money.

9. Auditability

Every successful Allocation mutation is represented by an immutable PlanningOperation stored in the PlanningOperation Log.

The log exists for:

Audit
Diagnostics
History
Analytics

Allocation stores only the current planning state.

The Planning Domain intentionally does not implement full Event Sourcing.

10. Concurrency

Every Allocation contains an optimistic concurrency version.

Each successful mutation increments the version.

Concurrent modifications must fail rather than silently overwrite state.

Conflict resolution is the responsibility of the Planning Engine.

11. User Intent

Allocation state changes never occur implicitly.

Every mutation must originate from one of:

User Action
Approved Automation Rule
Planning Policy

Every state transition is represented by a PlanningOperation.

Rationale

This design establishes a single owner for reserved-money state while keeping planning decisions centralized inside the Planning Engine.

It prevents duplicated reservation logic across Goals, Budgets, Commitments, and future planning features.

It also maintains architectural consistency with the Financial Engine, where all mutations pass through a single execution pipeline.

Unlike Financial Truth, Planning Truth represents mutable planning state rather than immutable accounting history. Therefore, full Event Sourcing is intentionally avoided.

Alternatives Considered
Alternative A — Allocation as Aggregate Root

Rejected.

Business rules, policies, priorities, and planning decisions belong to the Planning Engine rather than Allocation itself.

Treating Allocation as an Aggregate Root would duplicate business logic and weaken centralized validation.

Alternative B — Full Event Sourcing

Rejected.

Reserved money does not require immutable accounting history comparable to Journal Entries.

The additional complexity of Event Streams, Replay, Snapshotting, and Event Versioning provides little practical value for the Planning Domain.

PlanningOperation Log provides sufficient auditability.

Alternative C — Direct CRUD from Planning Aggregates

Rejected.

Allowing Goals, Budgets, or Automation to modify Allocation directly would bypass Guards, Policies, and centralized execution rules.

Consequences
Benefits
Single reservation model.
Centralized planning logic.
Consistent mutation pipeline.
Clear ownership.
Excellent auditability.
Low coupling.
Future extensibility.
Trade-offs
Every Allocation change must pass through the Planning Engine.
Additional PlanningOperations are required for all mutations.
Optimistic concurrency handling becomes mandatory.
Out of Scope

The following features are intentionally excluded from V1:

Split Allocation
Merge Allocation
Allocation Version History
Event Sourcing
Allocation Snapshots
Allocation Lineage

These may be introduced by future ADRs without changing the core architecture.

Future Extensions

Potential future enhancements include:

Split and Merge operations.
Allocation templates.
Shared allocations across books.
Allocation expiration policies.
Advanced reservation strategies.
Allocation analytics.
AI-assisted allocation optimization.
Architectural Principles Frozen
Allocation is a Managed Domain Entity.
Planning Engine exclusively owns Allocation mutations.
PlanningOperation is the only write primitive.
Allocation represents current planning state.
PlanningOperation Log provides auditability.
Full Event Sourcing is intentionally excluded.
Direct Allocation mutation is prohibited.