ADR-004 — Domain Mutation Execution
Status

Accepted (Foundation ADR)
Context

The Financial Engine is responsible for executing financial operations atomically.

Initially, only accounting mutations (JournalEntryMutation) existed.

As the system evolved, operations such as Goal Transfer introduced additional domain mutations:

GoalActivityMutation
ReleaseAllocationMutation
(Future: BudgetMutation, InvestmentMutation, DebtMutation...)

The architectural question became:

Should the Financial Engine return an ExecutionPlan and let the Application Layer execute domain mutations, or should the Engine execute everything itself?

Decision

The Financial Engine remains the single authority responsible for mutating Financial Truth.

The Application Layer must never execute Financial Mutations directly.

All mutations are executed by the Engine through the Executor.

Infrastructure dependencies are hidden behind Ports, consumed by individual MutationHandlers, not by the Engine itself.

Execution Flow
FinancialOperation
        │
        ▼
Interpreter
        │
        ▼
Domain Guards
        │
        ▼
Planner
        │
        ▼
FinancialExecutionPlan
        │
        ▼
Integrity Checker
        │
        ▼
Executor
        │
        ▼
Mutation Handler
        │
        ▼
Port
        │
        ▼
Infrastructure Adapter
        │
        ▼
Hive / SQLite / Firebase / API
Rules
### Rule 1

The Engine executes every mutation.

The Application Layer never executes mutations.

### Rule 2

Each Mutation has exactly one Handler.

### Rule 3

Each Handler depends only on one Port.

Handlers never depend directly on Hive, SQLite, Firebase or Services.

### Rule 4

Ports belong to the Financial Engine.

Adapters belong to the Application/Infrastructure layer.

### Rule 5

Derived state is never mutated.

Examples:

Progress
Balance
Net Worth
Remaining
Analytics

The Engine mutates only Source of Truth.


### Rule 6

Mutation execution order is defined by the Planner.

The Executor MUST preserve the exact order of mutations contained in the
FinancialExecutionPlan.

MutationHandlers MUST NOT reorder, skip, or insert mutations.

The Executor is responsible only for execution, never orchestration.

### Rule 7

Business decisions belong exclusively to the Planner.

MutationHandlers execute mutations exactly as planned.

Handlers MUST NOT contain business rules or financial decisions.
---
## Invariants

The following invariants must always hold:

- Financial Truth is mutated only by FinancialOperationEngine.
- Every FinancialMutation is executed exactly once.
- Mutations are executed in Planner order.
- A failed execution MUST leave no partial mutations.
- Derived state is never written directly.
- MutationHandlers are infrastructure-agnostic.

---

## Rejected Alternative

Returning FinancialExecutionPlan to the Application Layer for execution
was rejected because it:

- breaks atomic execution guarantees;
- duplicates orchestration responsibilities;
- weakens the Engine as the single authority over Financial Truth;
- increases the risk of partial execution.

---


Consequences & Non-Goals


Advantages
Atomic execution.
Single source of financial truth.
Infrastructure independence.
Easy testing through mocked Ports.
Easy addition of new mutation types.
Stable architecture for long-term evolution.
Trade-offs
More interfaces (Ports).
One Adapter per external module.

The Financial Engine is not responsible for:

- UI updates
- Notifications
- Analytics
- Reporting
- Projection generation
- Caching

This complexity is intentional and prevents coupling between the Engine and Infrastructure.


## Glossary

Financial Truth
: Any persistent state representing accounting records or domain source-of-truth.

Derived State
: Any value computed from Financial Truth, such as balances, progress,
remaining amounts, reports, analytics, or projections.

Mutation
: A single atomic change to Financial Truth.

Port
: An abstraction owned by the Financial Engine that defines required
external behavior without depending on infrastructure.

Adapter
: An infrastructure implementation of a Port.

----------------------------------------------------------

Future mutations introduced to the Financial Engine MUST comply with this ADR
unless a newer Foundation ADR explicitly supersedes it.