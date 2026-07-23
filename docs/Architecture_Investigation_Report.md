# Wafferly Architecture Investigation Report
Version: 1.0
Status: Official
Last Updated: July 2026

---

# Purpose

This document records the architectural investigation conducted during the redesign of Wafferly Financial Engine.

Its purpose is to preserve architectural decisions, prevent repeating previous investigations, and document both accepted and rejected ideas.

Discussion is NOT architecture.

Only decisions recorded in this document are considered official.

---

# Investigation Scope

The investigation covered the following topics:

- Financial Truth
- Single Writer
- Transaction Reality
- Accounts Ownership
- Balance
- Financial Engine Responsibility
- Planner
- Executor
- Repository
- Domain Boundaries
- Canonical Pipeline

---

# Final Architecture Status

The investigation is considered CLOSED.

No architectural topic should be reopened unless a real product problem requires it.

---

# ==========================================================
# ACCEPTED DECISIONS
# ==========================================================

------------------------------------------------------------
AD-001
Canonical Transaction Pipeline
------------------------------------------------------------

Question

Should different entry points create different execution paths?

Decision

NO.

All transaction-producing operations MUST pass through one canonical execution pipeline.

Pipeline

Intent
↓
Interpreter
↓
Domain Guards
↓
Policies
↓
Planner
↓
Execution Plan
↓
Executor
↓
Repository

Reason

Multiple write paths eventually produce inconsistent business behavior.

Impact

- Voice
- OCR
- SMS
- Manual Entry
- API

All must use the exact same pipeline.

Status

ACCEPTED

------------------------------------------------------------
AD-002
Transactions are Historical Truth
------------------------------------------------------------

Question

What is the official historical record of financial events?

Decision

Transactions.

Reason

Every completed financial event is represented by one or more immutable transactions.

Transactions describe what happened.

They do NOT describe ownership.

They do NOT describe projections.

Impact

Transaction Domain

Status

ACCEPTED

------------------------------------------------------------
AD-003
Balance is Derived
------------------------------------------------------------

Question

Should Balance become Financial Truth?

Decision

NO.

Balance is always derived.

Reason

Balance can always be recalculated from transaction history.

Keeping Balance as primary truth creates synchronization problems.

Impact

Balance Service

BalancePort

Reports

Dashboard

Status

ACCEPTED

------------------------------------------------------------
AD-004
Accounts Represent Ownership
------------------------------------------------------------

Question

What does an Account represent?

Decision

Ownership.

Reason

Accounts describe where value belongs.

Transactions describe how value moved.

These are different concepts.

Impact

Account Domain

Status

ACCEPTED

------------------------------------------------------------
AD-005
Repository Owns Persistence Only
------------------------------------------------------------

Question

Can Repository contain Business Logic?

Decision

NO.

Repository only stores and retrieves data.

Business decisions belong to the domain.

Reason

Persistence must never define business meaning.

Impact

All repositories.

Status

ACCEPTED

------------------------------------------------------------
AD-006
Business Meaning Before Persistence
------------------------------------------------------------

Decision

The system determines business meaning before writing anything.

Execution order

Intent

↓

Interpretation

↓

Validation

↓

Planning

↓

Execution

↓

Persistence

Reason

Storage must be the final step.

Status

ACCEPTED

------------------------------------------------------------
AD-007
Validation Before Execution
------------------------------------------------------------

Decision

Every financial operation must pass validation before execution.

Validation includes

- Domain Guards

- Policies

- Integrity Checks

Only after validation may execution begin.

Status

ACCEPTED

------------------------------------------------------------
AD-008
Executor Never Makes Decisions
------------------------------------------------------------

Question

Should Executor contain business rules?

Decision

NO.

Executor executes.

Planner plans.

Reason

Separating planning from execution keeps execution deterministic.

Status

ACCEPTED

------------------------------------------------------------
AD-009
Financial Engine Scope
------------------------------------------------------------

Question

Should Financial Engine own every financial domain?

Decision

NO.

Financial Engine is responsible only for Transaction Operations.

It is NOT responsible for

- Goals

- Budgets

- Analytics

- Reports

unless they produce transaction operations.

Status

ACCEPTED

------------------------------------------------------------
AD-010
Input Source Must Not Change Business Logic
------------------------------------------------------------

Decision

Business behavior must remain identical regardless of input source.

Examples

Manual Entry

Voice

OCR

SMS

Future AI

must all produce identical business meaning.

Status

ACCEPTED

------------------------------------------------------------
AD-011
Business Logic Never Lives Inside UI
------------------------------------------------------------

Decision

UI requests operations.

UI never creates financial reality.

Reason

Presentation layer cannot own business rules.

Status

ACCEPTED

------------------------------------------------------------
AD-012
Transactions Are Immutable
------------------------------------------------------------

Decision

Executed transactions are historical records.

History should be corrected through additional transactions rather than modifying existing history whenever possible.

Status

ACCEPTED


# ==========================================================
# REJECTED DECISIONS
# ==========================================================

------------------------------------------------------------
RJ-001
Balance as Financial Truth
------------------------------------------------------------

Question

Should Balance become the primary financial truth?

Decision

REJECTED

Reason

Balance is a calculated projection.

It can always be reproduced from transaction history.

Making Balance the truth creates synchronization risks.

Final Position

Balance is derived data only.

------------------------------------------------------------
RJ-002
Repository as Single Writer
------------------------------------------------------------

Question

Should Repository become the Single Writer?

Decision

REJECTED

Reason

Repository only persists data.

Business meaning is already finalized before persistence begins.

Repository cannot own business reality.

------------------------------------------------------------
RJ-003
Planner Owns Business Reality
------------------------------------------------------------

Question

Does Planner become the owner of business logic?

Decision

REJECTED

Reason

Planner builds an execution plan.

It does not execute.

It does not persist.

It does not own financial reality.

------------------------------------------------------------
RJ-004
UI Creates Transactions
------------------------------------------------------------

Question

Can UI create transactions directly?

Decision

REJECTED

Reason

UI expresses user intent.

The Financial Engine creates business reality.

UI must never bypass the canonical pipeline.

------------------------------------------------------------
RJ-005
Multiple Independent Write Pipelines
------------------------------------------------------------

Question

Should each feature own its own write pipeline?

Decision

REJECTED

Reason

Different pipelines eventually drift apart.

Validation rules become inconsistent.

Business behavior becomes unpredictable.

Final Position

Exactly one canonical transaction pipeline.

------------------------------------------------------------
RJ-006
One Giant Financial Engine
------------------------------------------------------------

Question

Should one engine own every financial domain?

Decision

REJECTED

Reason

Different domains evolve independently.

One giant engine becomes a God Object.

Transaction execution is only one domain.

------------------------------------------------------------
RJ-007
Financial Truth as a Universal Concept
------------------------------------------------------------

Question

Can the entire system be modeled around one Financial Truth?

Decision

REJECTED

Reason

The investigation showed that the concept mixes multiple responsibilities.

History.

Ownership.

Projection.

Planning.

Goals.

Budgets.

These are different concepts.

Using one universal "Financial Truth" creates ambiguity.

------------------------------------------------------------
RJ-008
Business Logic Inside Repository
------------------------------------------------------------

Decision

REJECTED

Reason

Persistence must remain infrastructure.

Repositories should never decide business behavior.

------------------------------------------------------------
RJ-009
Balance Stored As Primary State
------------------------------------------------------------

Decision

REJECTED

Reason

Primary state duplication increases inconsistency.

Balance should always be reproducible.

------------------------------------------------------------
RJ-010
Feature-Specific Financial Logic
------------------------------------------------------------

Decision

REJECTED

Reason

Features should compose existing architecture.

They should not invent new financial rules.

# ==========================================================
# DEFERRED DECISIONS
# ==========================================================

------------------------------------------------------------
DF-001
Domain Truth
------------------------------------------------------------

Status

DEFERRED

Discussion

The investigation explored replacing Financial Truth with Domain Truth.

No final architecture decision was reached.

Reason for Deferral

Current MVP does not require this abstraction.

May be revisited if multiple financial domains become independent.

------------------------------------------------------------
DF-002
Domain Writers
------------------------------------------------------------

Status

DEFERRED

Discussion

Whether every domain should own its own canonical writer.

Reason

Current architecture has only one mature transaction pipeline.

Future domains may require their own writers.

------------------------------------------------------------
DF-003
Multiple Financial Engines
------------------------------------------------------------

Status

DEFERRED

Discussion

Separate engines for Goals.

Budgets.

Investments.

Loans.

Reason

Premature for MVP.

------------------------------------------------------------
DF-004
Bounded Context Split
------------------------------------------------------------

Status

DEFERRED

Reason

Current project size does not justify additional complexity.

------------------------------------------------------------
DF-005
Goal Execution Engine
------------------------------------------------------------

Status

DEFERRED

Reason

Goals currently don't require an execution pipeline.

------------------------------------------------------------
DF-006
Budget Engine
------------------------------------------------------------

Status

DEFERRED

Reason

Budget implementation is not mature enough.

------------------------------------------------------------
DF-007
Allocation Engine
------------------------------------------------------------

Status

DEFERRED

Reason

Allocation model still under exploration.

------------------------------------------------------------
DF-008
Financial Domain Expansion
------------------------------------------------------------

Status

DEFERRED

Reason

Architecture should expand only when new domains require independent behavior.

# ==========================================================
# OPEN QUESTIONS
# ==========================================================

These questions remain intentionally unanswered.

They are not architecture decisions.

They should only be reopened when a concrete product requirement appears.

------------------------------------------------------------

OQ-001

Does every financial domain require its own canonical pipeline?

Status

OPEN

------------------------------------------------------------

OQ-002

Should Goals eventually become an execution domain?

Status

OPEN

------------------------------------------------------------

OQ-003

Should Budgeting become an operational domain or remain analytical?

Status

OPEN

------------------------------------------------------------

OQ-004

When should Domains become separate bounded contexts?

Status

OPEN

------------------------------------------------------------

OQ-005

Should cross-domain orchestration eventually replace a single transaction engine?

Status

OPEN

# ==========================================================
# DEFINITIONS UPDATED
# ==========================================================

Financial Truth

Removed as an official architectural term.

------------------------------------------------------------

Transaction

Official historical record of executed financial events.

------------------------------------------------------------

Account

Represents ownership.

Not financial history.

------------------------------------------------------------

Balance

Derived financial projection.

Never primary truth.

------------------------------------------------------------

Planner

Produces execution plans.

Does not execute.

------------------------------------------------------------

Executor

Executes plans.

Does not decide business behavior.

------------------------------------------------------------

Repository

Infrastructure persistence layer.

Owns storage.

Never owns business meaning.

------------------------------------------------------------

Single Writer

No longer means a single class.

It means a single canonical business pipeline responsible for creating Transaction Reality.

------------------------------------------------------------

Financial Engine

Responsible for transaction operations.

Not responsible for every financial domain.

# ==========================================================
# FINAL CONCLUSIONS
# ==========================================================

The investigation reached the following conclusions:

✓ One canonical transaction pipeline.

✓ Transactions are immutable historical records.

✓ Accounts represent ownership.

✓ Balance is always derived.

✓ Business meaning precedes persistence.

✓ Repository owns storage only.

✓ Planner plans.

✓ Executor executes.

✓ UI never creates financial reality.

✓ Financial Engine owns transaction operations only.

The investigation is officially considered CLOSED.

Future architectural discussions should start from this document rather than repeating previous investigations.

Any future architectural proposal must explicitly state whether it:

- Introduces a new Accepted Decision.
- Reopens a Deferred Decision.
- Challenges an existing Accepted Decision.

Otherwise, the current architecture remains the official reference.


# ==========================================================
# ARCHITECTURE INVESTIGATION HISTORY
# ==========================================================

This section documents the major architectural investigations that shaped the current architecture.

It exists to preserve context.

It is NOT a source of architectural decisions.

Only the Accepted Decisions section defines the official architecture.

------------------------------------------------------------
Investigation 01
Financial Truth
------------------------------------------------------------

Objective

Determine whether the entire financial system can be modeled around a single Financial Truth.

Result

The investigation concluded that multiple concepts had been incorrectly grouped together.

These concepts include:

- Historical Events
- Ownership
- Derived Values
- Planning
- Goals
- Budgets

Final Outcome

The concept of "Financial Truth" was abandoned as an official architectural term.

------------------------------------------------------------
Investigation 02
Single Writer
------------------------------------------------------------

Objective

Determine what "Single Writer" actually means.

Initial Assumption

A single class should write all financial data.

Final Understanding

Single Writer refers to a single canonical business pipeline.

It does NOT require a single class.

------------------------------------------------------------
Investigation 03
Balance
------------------------------------------------------------

Objective

Determine whether Balance should become stored financial truth.

Result

Balance is always derived.

------------------------------------------------------------
Investigation 04
Accounts
------------------------------------------------------------

Objective

Determine the responsibility of Accounts.

Result

Accounts represent ownership.

They do not represent financial history.

------------------------------------------------------------
Investigation 05
Financial Engine
------------------------------------------------------------

Objective

Determine the responsibility boundaries of Financial Engine.

Result

Financial Engine owns transaction operations only.

------------------------------------------------------------
Investigation 06
Repository
------------------------------------------------------------

Objective

Determine whether Repository owns business meaning.

Result

Repositories only persist data.

Business meaning is finalized before persistence.

------------------------------------------------------------
Investigation 07
Planner vs Executor
------------------------------------------------------------

Objective

Separate planning from execution.

Result

Planner produces execution plans.

Executor executes them.

------------------------------------------------------------
Investigation Summary

The investigation reduced architectural ambiguity and established a stable execution model for the MVP.

Future investigations should begin from the conclusions recorded in this document rather than restarting previous discussions.