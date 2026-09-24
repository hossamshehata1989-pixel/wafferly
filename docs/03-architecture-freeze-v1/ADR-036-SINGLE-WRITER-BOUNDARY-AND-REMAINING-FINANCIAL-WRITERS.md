


ADR-036 — Single Writer Boundary and Remaining Financial Writers
Status: Accepted — Tier 1 Migration Gate Closed; Tier 2 Remains Open
Date: 2026-09-22
Related: ADR-032 (Debt Architecture), Financial Foundation Freeze V1 Documentation Pack
Supersedes: Implicit assumption that "Single Writer" closes when every persistence writer is removed

Context
The FinancialOperationEngine is the canonical writer for Financial Reality. The project also contains distinct architectural state boundaries for Planning State and History / Audit.

The Single Writer audit identified production and non-production write paths that must not be treated as one undifferentiated list of violations.

Financial Reality writers
Generic transaction writers (TransactionService.addTransaction / update / delete and TransactionApplicationService equivalents)

Account balance adjustment (AccountTransactionService.createBalanceAdjustment)

Correction / Invalidation

Planning State writers
Allocation / reservation state through the PlanningEngine and its persistence adapters

Legacy allocation / reserved-money stores that still require equivalence and retirement verification

History / Audit writers
GoalActivityService.addActivity(...)

Non-production / development-only writers
Legacy Ledger CRUD adapters and development-only ledger sandbox/stress writers

The audit also identified the Non-reserved Goal → Saving flow as the final Tier 1 migration candidate. It was implemented without reusing GoalTransferOperation, because the reserved operation includes allocation-release semantics that do not exist in the non-reserved flow.

The required verification has now been completed:

Targeted Goal Saving Transfer pipeline tests passed.

Single Writer architecture boundary tests passed.

Full project regression suite passed: 119/119 tests.

No newly introduced Financial Reality writer bypass was identified by the migration boundary tests.

Therefore the Tier 1 Migration Gate can be closed.

The remaining Tier 2 paths still require their own domain decisions. They must not be migrated merely to make a checklist green.

Decision
We adopt a two-tier definition of Single Writer, with explicit classification for non-production paths.

Tier 1 — Migration Gate — CLOSED
The FinancialOperationEngine is the canonical writer for every Financial Reality flow for which an established, behavior-equivalent canonical operation exists.

Flow	Status
Expense	✅ Migrated and verified
Income	✅ Migrated and verified
Transfer	✅ Migrated and verified
Reserved Goal → Saving	✅ Migrated and verified
Non-reserved Goal → Saving	✅ Migrated and verified
Planning Engine as writer for Planning State	✅
GoalActivityService as History / Audit writer outside Financial Reality	✅
Tier 1 closure evidence
The Non-reserved Goal → Saving flow is now routed through GoalSavingTransferOperation and the FinancialOperationEngine rather than direct transaction/activity writes from the UI.

Verification completed on 2026-09-22:

Targeted pipeline tests passed for successful transfer, invalid destination, and insufficient balance.

Single Writer boundary tests passed for the reserved and non-reserved Goal transfer paths.

Full project regression suite passed with 119/119 tests.

The Tier 1 Migration Gate is therefore CLOSED.

Tier 2 — Remaining Production Write Paths / Architectural Exceptions
These are explicit architectural work items. They are not considered forgotten migration debt.

Remaining path	Current decision	Required resolution
Generic Transaction Writer	Deferred	Define explicit type-to-operation coverage for every transaction subtype the generic path can represent, then migrate or classify each path.
Balance Adjustment	Deferred	Define canonical Balance Adjustment semantics and operation before migration.
Correction / Invalidation	Partially Resolved	Correction semantics are defined by ADR-038 and migrated through the FinancialOperationEngine; invalidation/deletion remains a separate domain decision.
Legacy Allocation / Reserved Money stores	Deferred	Prove state equivalence with the Planning Engine repository, remove legacy production dependencies/readers, then retire or explicitly classify the stores.
No Tier 2 item may be closed by:

silent removal;

routing it through an unrelated existing operation;

inventing an operation solely to make the Single Writer checklist green;

changing its semantics without a domain decision;

deleting the writer without proving that its state ownership has been replaced.

Each Tier 2 item must resolve through one of two paths:

(a) Canonical Migration

A canonical FinancialOperationEngine or PlanningEngine operation is defined, reviewed, proven behavior-equivalent, implemented, regression-tested, and becomes the sole production writer for that state.

(b) Explicit Architectural Classification

An accepted ADR or ADR amendment establishes that the path does not represent a Financial Reality mutation or belongs to another defined architectural state boundary.

State Boundary Clarification
Single Writer applies to Financial Reality, not to every persistence operation in the application.

Financial Reality
        │
        ▼
FinancialOperationEngine
        │
        ├── Expense
        ├── Income
        ├── Transfer
        ├── Goal → Saving financial effects
        └── Future canonical financial operations

Planning State
        │
        ▼
PlanningEngine
        │
        ├── Allocation
        └── Reservation

History / Audit
        │
        ▼
GoalActivityService

Development / Test Only
        │
        ▼
Sandbox / Stress / Test Writers
The relevant question is:

Does more than one production path own the mutation of the same architectural state?

The existence of multiple persistence adapters does not, by itself, violate Single Writer when those adapters only persist mutations produced by their canonical engine/operation.

Non-reserved Goal → Saving
The Non-reserved Goal → Saving flow is a Tier 1 migration, not a Tier 2 exception.

It is implemented through GoalSavingTransferOperation and the FinancialOperationEngine.

It deliberately does not reuse GoalTransferOperation, because reserved Goal → Saving includes allocation-release semantics that are not present in the non-reserved flow.

Its verification is now complete and therefore the flow is part of the closed Tier 1 Migration Gate.

Debt-02A — Legacy TransactionType.debt Classification
Context
As part of the Generic Transaction Writer and Debt domain audit, the legacy TransactionType.debt vocabulary was reviewed to determine whether it represents an active financial subtype, a hidden Financial Reality writer, or merely obsolete terminology.

The audit covered:

current production usages;

current test usages;

transaction writers;

transaction readers and filters;

legacy fixtures;

migration code;

persisted representation at the Hive boundary;

relationship to the current Debt domain architecture.

Audit Result
The audit found:

No current production usage of TransactionType.debt.

No current test usage of TransactionType.debt.

No active transaction writer creates transactions using TransactionType.debt.

No current reader or filter depends on TransactionType.debt.

No transaction migration was found that converts or otherwise handles Transaction.type = "debt".

No available transaction fixture/test was found that creates a persisted Transaction with type = "debt".

Current Debt financial flows use the approved Financial Operation Engine pipeline and do not require TransactionType.debt.

CommitmentPaymentOperation is an active, implemented Financial Operation Engine flow and is not dependent on TransactionType.debt.

Resolution.tempDebt and TransactionSource.tempDebt belong to the current Temporary Debt behavior and must not be conflated with the legacy TransactionType.debt vocabulary.

Occurrences of the string debt found in Account-related migration/test material refer to Account.type and are not evidence of a Transaction.type = "debt" dependency.

Persistence Compatibility
Transaction.type is persisted as a String in Hive.

The persistence layer therefore does not require the TransactionType.debt Dart constant in order to deserialize an existing record whose stored value is "debt".

This means:

Removing the Dart constant does not itself migrate existing persisted values.

An old persisted Transaction could technically still contain type = "debt" even after the constant is removed.

The available source code, tests, fixtures, and migration material do not provide evidence that such persisted production records currently exist.

Production database contents were not directly inspected as part of this source-level audit.

Therefore the audit does not claim that no historical production Transaction contains "debt". It only establishes that no such dependency was found in the available code and test/migration material.

Architectural Classification
TransactionType.debt is classified as:

Deprecated legacy vocabulary.

It is not a canonical Debt financial operation.

It must not be reintroduced as a generic Debt writer.

A new DebtOperation must not be created solely to preserve or replace this legacy transaction type.

Current Debt financial mutations must continue to use the approved Financial Operation Engine and authoritative Transaction / Ledger pipeline defined by the Debt architecture.

Decision
The TransactionType.debt constant is not removed as part of the Single Writer migration.

It remains temporarily as deprecated legacy vocabulary until the project's explicit data-cleanup / migration phase establishes the policy for historical persisted values.

No new production code may use it.

Physical removal is therefore a data-cleanup / migration concern, not a Financial Operation Engine migration task.

Debt-02A Status
CLOSED — Architectural classification established.

The closure means that the Single Writer audit has resolved the architectural question around this constant. It does not claim that historical production storage has been exhaustively inspected.

Final Single Writer Closure Criterion
The Tier 1 Migration Gate is closed when all currently identified Financial Reality flows with an established behavior-equivalent canonical operation have been migrated and verified. This condition is now satisfied.

The overall Single Writer architecture is fully closed only when every remaining production Financial Reality write path has been resolved through one of the following classifications:

(A) Canonical Production Writer — The path has been migrated to the appropriate canonical engine/operation with passing regression coverage.

(B) Explicit Architectural Exception — An accepted ADR or ADR amendment establishes that the path does not represent a Financial Reality mutation, or belongs to another defined architectural state boundary.

(C) Explicitly Non-Production — The path is proven to be development/test/sandbox-only, has no active production caller, and is excluded from the production Financial Reality boundary.

Therefore:

Final Single Writer Closure does not require every write operation in the repository to pass through FinancialOperationEngine. It requires every production mutation of Financial Reality to have one explicitly defined canonical owner, with all other production write paths either migrated or explicitly classified by architecture.

Follow-up Work Required
The remaining work is intentionally separated into domain decisions rather than being folded into an indiscriminate migration pass:

Balance Adjustment semantics

Invalidation / Deletion semantics

Generic Transaction Writer type-to-operation coverage

Legacy Allocation / Reserved Money state equivalence and retirement

Final production active-writer audit after those decisions

Data-cleanup / migration policy for deprecated legacy transaction vocabulary

These items are not blockers for closing the Tier 1 Migration Gate, but they remain blockers for declaring the overall Single Writer architecture fully closed, except where an item is explicitly classified as a non-production or data-cleanup concern.

Audit Trail
Single Writer Audit established the production writer inventory.

Reserved Goal → Saving migrated to GoalTransferOperation.

Non-reserved Goal → Saving migrated to GoalSavingTransferOperation.

Generic Transaction Writer production fallback was removed after its active caller was identified and classified.

Debt-02A audited TransactionType.debt across production usage, tests, writers, readers, fixtures, and migration material.

TransactionType.debt was classified as deprecated legacy vocabulary.

No new Debt operation was introduced.

Targeted Goal Saving Transfer tests passed.

Single Writer boundary tests passed.

Full project regression suite passed: 119/119 tests on 2026-09-22.

Tier 1 Migration Gate: CLOSED.

Tier 2: OPEN — explicit domain decisions required.

Current Status
Tier 1 — Migration Gate
        │
        ├── Expense                         ✅
        ├── Income                          ✅
        ├── Transfer                        ✅
        ├── Reserved Goal → Saving          ✅
        └── Non-reserved Goal → Saving      ✅
                                                │
                                                ▼
                                      Migration Gate CLOSED
                                                │
                                                ▼
Tier 2 — Remaining Production Paths
        │
        ├── Generic Transaction Writer      ⏳ Domain coverage / classification
        ├── Balance Adjustment              ⏳
        ├── Correction                     ✅ ADR-038
        ├── Invalidation / Deletion        ⏳
        └── Legacy Allocation/Reserved      ⏳
            Money state equivalence

Debt-02A
        │
        └── TransactionType.debt             ✅
            Deprecated legacy vocabulary
            Physical removal deferred to
            data-cleanup / migration phase

Non-Production
        │
        └── Ledger sandbox/stress writers   🟦 Explicitly excluded