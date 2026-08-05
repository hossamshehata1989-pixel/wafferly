ADR-020 — Planning Policies & Domain Guards

Status: Accepted

Date: 2026-08-04

Context

The Planning Engine owns all reservation logic.

To guarantee predictable behavior, all PlanningOperations must pass through a centralized validation and policy pipeline.

Planning rules must remain independent from the Financial Engine.

Decision
1. Single Validation Pipeline

Every PlanningOperation must pass through:

Interpreter

↓

Domain Guards

↓

Policy Pipeline

↓

Planner

↓

Integrity Checker

↓

Executor

No PlanningOperation may bypass this pipeline.

2. Domain Guards

Domain Guards enforce structural correctness.

They validate facts, not business preferences.

Examples include:

Allocation exists.
Goal exists.
Budget exists.
Account exists.
Allocation belongs to the correct Book.
Allocation is Active.
Allocation has sufficient reserved amount.
Reservation source supports the requested operation.

If any Domain Guard fails:

execution stops immediately.
no Allocation is modified.
no FinancialOperation is produced.
3. Policy Pipeline

Policies enforce business decisions.

Unlike Guards, Policies may:

warn
require confirmation
modify execution
block execution

Policies are configurable.

4. Over Allocation Policy

The system allows Available Balance to become negative.

Example:

Total = 1000

Reserved = 1200

Available = -200

This is valid.

The system warns the user.

Planning never changes Financial Truth.

5. Double Reservation Policy

A single monetary amount cannot be reserved twice.

Example:

Goal A

1000 Reserved

↓

Budget tries to reserve same 1000

The system prevents double reservation.

If sharing is desired, explicit Reallocation must occur.

6. Budget Policy

Budgets support two official modes.

Monitoring

No reservation.

No Allocation.

Reserved

Creates Allocation.

Reserved money remains reserved after period end.

The system never automatically transfers remaining money.

The user explicitly chooses:

Keep Reserved
Release
Transfer
7. Goal Funding Policy

Goals support:

Reserve

Money stays reserved.

Transfer

Money moves immediately through the Financial Engine.

Progress is:

Reserved

+

Transferred
8. Commitment Policy

Commitments support importance levels.

Examples:

Must

Need

Want

Default behavior:

Level	Default
Must	Reserve
Need	User Choice
Want	Reminder Only

Users may override defaults.

9. Insufficient Total Balance

If Financial Truth is insufficient:

Example:

Total = 500

Expense = 1000

Planning does not decide.

Financial Engine stops execution.

Available options:

Transfer from another account.
Temporary Debt.
Cancel operation.
10. Reserved Transfer Protection

Reserved money cannot silently leave its account.

When transferring money from an account containing reserved funds:

Planning blocks execution.

User must first:

Release reservation
Reallocate reservation

Automatic transfers are blocked.

Automatic executions become Financial Actions requiring user approval.

11. Automation Policy

Automation never bypasses Policies.

Automation produces PlanningOperations.

Those operations pass through the same pipeline as user operations.

12. Financial Boundary

Planning Policies never inspect:

Journal Entries
Ledger
Double Entry

Financial Policies never inspect:

Goals
Budgets
Reservations

Application Layer coordinates both domains.

Rationale

Separating Domain Guards from Policies ensures that structural correctness remains deterministic while business behavior remains configurable.

This architecture prevents duplicated rules across Goals, Budgets, Commitments, and future planning features.

Alternatives Considered
Hard Blocking Everywhere

Rejected.

The system favors warnings and explicit user decisions over unnecessary restrictions.

Reservation Logic Inside Goals

Rejected.

Reservation belongs exclusively to the Planning Engine.

Financial Engine Enforcing Reservations

Rejected.

Reserved Money is Planning Truth, not Financial Truth.

Financial Engine remains completely unaware of reservations.

Consequences
Benefits
Predictable execution.
One place for planning rules.
Easy extensibility.
Consistent UX.
Strong separation of concerns.
Trade-offs
Larger policy pipeline.
More PlanningOperations.
Slightly higher implementation complexity.
Out of Scope
AI Planning Policies.
Shared Book negotiation.
Multi-user conflict resolution.
Advanced priority engines.
Architectural Principles Frozen
One validation pipeline.
Domain Guards validate facts.
Policies validate business decisions.
Financial Truth is never modified by Planning.
Planning never bypasses the pipeline.
Reservations are protected by Planning Policies only.