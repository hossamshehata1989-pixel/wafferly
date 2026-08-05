ADR-027 — Interaction Platform

Status: Accepted

Date: 2026-08-05

Decision Type: Platform Architecture

Scope:
Entire Wafferly Platform

1. Context

As Wafferly evolved, multiple independent domains began requiring user interaction before execution.

Examples include:

Planning Engine
Financial Engine
OCR
SMS Import
AI Assistant
Investment Engine
Prediction Engine
Future synchronization conflicts

Each domain requires the user to make decisions before execution, including:

approval
rejection
choosing between alternatives
editing extracted data
providing missing information
resolving conflicts

Originally these interactions appeared as "Pending Financial Actions".

As more domains were introduced it became clear that pending actions are not a Financial concept.

They are a platform-wide capability.

2. Problem

Allowing every domain to implement its own approval workflow creates:

duplicated lifecycle management
duplicated UI
duplicated expiration logic
duplicated notifications
duplicated audit
inconsistent user experience

At the same time, allowing a shared component to execute business logic would violate domain boundaries and eventually create a God Object.

A dedicated platform capability is therefore required.

3. Decision

Wafferly introduces a dedicated Interaction Platform.

The Interaction Platform is NOT:

a Domain
an Engine
a Workflow Engine
a Business Rules Engine

It is a platform capability responsible only for managing user interactions.

4. Responsibilities

The Interaction Platform owns:

interaction lifecycle
interaction persistence
interaction presentation
interaction expiration
interaction prioritization
interaction notifications
interaction history

It provides a unified Action Center where every pending user interaction is displayed.

5. Non-Responsibilities

The Interaction Platform never:

validates business rules
evaluates domain policies
checks financial integrity
checks planning integrity
modifies domain entities
executes domain operations

Business logic always remains inside the originating domain.

6. Interaction Flow

Every domain may publish an Interaction Request.

Example:

Planning Engine
      │
      ▼
Interaction Required
      │
      ▼
Interaction Platform
      │
      ▼
User Interface
      │
      ▼
User Decision
      │
      ▼
Original Domain

The Interaction Platform never decides what should happen after approval.

It only delivers the user's decision back to the originating domain.

7. Domain Independence

Interaction Platform knows only:

interaction identity
source domain
source operation
interaction type
display snapshot
lifecycle state

It must never understand:

Goal rules
Budget rules
Financial rules
OCR rules
Investment rules
8. Snapshot Policy

Each Interaction stores an immutable display snapshot representing the information shown to the user at the moment the interaction was created.

The snapshot exists only for presentation.

It is never trusted for execution.

9. Revalidation Rule

When the user confirms an interaction:

The originating domain must always execute its complete validation pipeline again.

Example:

User Approves

↓

Planning Engine

↓

Interpreter

↓

Guards

↓

Policies

↓

Planner

↓

Integrity

↓

Executor

The Interaction Platform never bypasses validation.

This guarantees correctness even if system state changed while the interaction was pending.

10. Supported Interaction Types

Examples include:

Approval
Review
Selection
Confirmation
Data Completion
Conflict Resolution
Authentication
Warning Acknowledgement

Future interaction types may be added without changing existing domains.

11. Relationship with Automation

Automation Engine may generate interactions.

Example:

Automation Rule

↓

PlanningOperation

↓

Interaction Required

↓

Interaction Platform

Automation never communicates directly with the UI.

12. Relationship with Planning Engine

Planning Engine owns planning logic.

Interaction Platform owns only the user interaction lifecycle.

Planning Engine remains the exclusive owner of:

PlanningOperation
Allocation
Planning validation
Planning execution
13. Relationship with Financial Engine

Financial Engine owns:

FinancialOperation
Journal Entries
Ledger Integrity

Interaction Platform cannot execute FinancialOperations.

It only returns user decisions.

14. Cross-Domain Capability

The Interaction Platform is shared by every domain.

Example future integrations:

OCR receipt correction
SMS parsing confirmation
AI suggestions
Goal funding decisions
Budget conflict resolution
Investment approval
Cloud synchronization conflicts
Shared Book conflict resolution

No new domain should implement its own pending workflow.

15. Architectural Principles

The Interaction Platform follows these principles:

Single interaction center.
Zero business logic.
Zero domain ownership.
Domain-agnostic.
UI-oriented.
Revalidation before execution.
Immutable interaction snapshot.
Extensible interaction types.
16. Consequences
Benefits
Unified user experience.
Elimination of duplicated approval workflows.
Clear separation of concerns.
Future-proof architecture.
Simplified UI integration.
Supports AI, OCR, SMS, Investments, Shared Books and future domains.
Trade-offs
Additional platform component.
One extra dispatch step before execution.
Requires every domain to expose a safe execution entry point.
17. Explicit Non-Goals

The Interaction Platform is not intended to become:

a Business Process Manager
a Saga Engine
a Rule Engine
an Orchestrator
a Domain Service

If business logic begins migrating into the Interaction Platform, the architecture must be reconsidered immediately.

18. ADR Outcome

Interaction Platform becomes a permanent platform capability of Wafferly.

It serves as the single user interaction gateway for all present and future domains while preserving strict domain ownership and business isolation.


Interaction Payload

Interaction Platform never stores:

Goal

Budget

Allocation

FinancialOperation

PlanningOperation

or any mutable domain object.

It stores only:

immutable display snapshot

references

user decisions


② Dispatch Rule

The Interaction Platform never invokes
repositories or domain entities directly.

It dispatches the user decision
to the originating Application Service.

The originating Application Service
creates a NEW operation
which enters the engine normally.

③ Expiration Policy
Expired interactions
never execute automatically.

Expiration requires the originating domain
to decide whether:

- recreate
- ignore
- notify
- archive