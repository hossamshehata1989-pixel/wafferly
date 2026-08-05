ADR-023 — Planning Domain Model

Status: Accepted

Date: 2026-08-04

Context

The Planning Engine architecture has been frozen.

The next decision is defining the official Planning Domain Model.

The system must support multiple planning features while avoiding duplicated reservation logic.

Supported planning concepts include:

Goals
Budgets
Commitments
Scheduled Plans
Manual Reserve
Future Planning Features
Decision
1. Planning Aggregates

The Planning Domain consists of independent Aggregates.

Current Planning Aggregates are:

Goal
Budget
Commitment
Schedule
Manual Reserve

Each Aggregate owns its own lifecycle and business rules.

No Aggregate manages reserved money directly.

2. Reserved Money

Reserved money is represented exclusively by Allocation.

Planning Aggregates never implement reservation logic themselves.

Instead, they issue PlanningOperations.

3. Allocation Ownership

Allocation belongs exclusively to the Planning Engine.

Planning Aggregates:

create reservations
release reservations
modify reservations

only by submitting PlanningOperations.

They never mutate Allocation directly.

4. Funding Strategies

Every reservation uses one Funding Strategy.

Supported strategies:

Reserve
Transfer
Ask At Execution

Meaning:

Reserve

Money remains inside the original account.

Only Available Balance changes.

Transfer

Money is physically moved through the Financial Engine.

Reserved balance becomes Real Saving.

Ask At Execution

The decision is postponed until execution time.

The user decides whether to:

Reserve
Transfer
Cancel
5. Reservation Sources

Every Allocation has exactly one originating source.

Possible source types:

Goal

Budget

Commitment

Schedule

Manual Reserve

This relationship exists only for traceability.

Reservation ownership remains inside the Planning Engine.

6. Budget Modes

Budgets support two official modes.

Monitoring Budget

Tracks spending only.

Creates no Allocation.

Produces no Reserved Money.

Reserved Budget

Creates Allocations.

Reserved money reduces Available Balance.

Unused reserved money remains reserved until the user decides its fate.

The system never transfers remaining money automatically.

7. Goal Funding

Goals support multiple funding strategies.

Reserve Goal

Money remains reserved.

User decides later whether to:

Transfer
Release
Keep Reserved
Transfer Goal

Money moves immediately into a real saving account.

Goal progress includes transferred money.

Goal Progress is calculated as:

Reserved Amount

+

Transferred Amount
8. Manual Reserve

Users may reserve money without creating:

Goal
Budget
Commitment

Manual Reserve is a first-class planning feature.

9. Planning Independence

Planning Aggregates never depend on:

Ledger
Journal Entries
Account Balances

Planning depends only on:

Planning Engine
Planning Operations

Real money movement always occurs through the Financial Engine.

Consequences
Benefits
One reservation model.
No duplicated planning logic.
Simple extensibility.
Consistent behavior across all planning features.
Clear separation between planning and accounting.
Trade-offs
Every planning feature must integrate through the Planning Engine.
Direct reservation manipulation is prohibited.
Architectural Principles Frozen
Independent Planning Aggregates.
Allocation owned by Planning Engine.
One reservation model.
Two official Budget modes.
Multiple Goal funding strategies.
Manual Reserve as first-class feature.
No duplicated reservation logic.