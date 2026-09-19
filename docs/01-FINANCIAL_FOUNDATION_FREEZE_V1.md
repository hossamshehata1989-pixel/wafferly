# Financial Foundation Freeze V1

**Status:** Implementation Gate
**Scope:** Financial Engine, Accounts, Transactions, Ledger, Planning integration, Scheduled Money
**Audit Basis:** Current project snapshot / commit `76428f2`

## 1. Purpose

Wafferly must finish the financial foundation before introducing real Credit Card financial behavior.

The objective is not to add more features. The objective is to make the existing financial contracts true in runtime code.

## 2. Current Architecture Truth

The intended authority chain remains:

```text
UI / Controller / Application
            ↓
FinancialOperation
            ↓
FinancialOperationEngine
            ↓
Interpreter
            ↓
Domain Guards
            ↓
Policy
            ↓
Planner
            ↓
Integrity Checker
            ↓
Executor
            ↓
Financial Truth / Ledger / Domain mutations
```

The established source-of-truth boundaries remain:

| Area | Authoritative meaning |
|---|---|
| Accounts | Financial position / balance truth |
| Transactions | Executed money movement history |
| Ledger | Accounting projection/history produced from executed transactions |
| Allocations | Planning intent / reserved planning state |
| Goals | Purpose and goal state |
| Budgets | Monitoring state |
| Commitments | Expected future financial events |
| Schedule Rules | Recurrence/time rules |
| Schedule Occurrences | Concrete scheduled instances and execution state |

Derived values such as Available Balance, Net Worth, Goal Progress, Remaining, analytics, and forecasts must remain derived.

## 3. Foundation Gates

### Gate A — Single Writer

**Required invariant:** No application/UI/service path may directly mutate financial truth outside the Financial Operation Engine.

Current known bypasses include direct `TransactionService.addTransaction(...)` usage from application/UI code and legacy transaction CRUD paths.

Required end state:

```text
All financial writes
        ↓
FinancialOperationEngine
```

Legacy writers may remain temporarily only as read/query compatibility or as explicitly isolated migration code. They must not be the active write path for migrated features.

### Gate B — Correction and Invalidation

Accepted architecture treats financial edits as corrections and invalidation rather than generic database CRUD.

Required behavior:

- Financial fields changing → Financial Correction operation.
- Financial invalidation → dedicated invalidation/deletion semantics.
- Non-financial metadata changes may remain outside the Financial Engine.
- Correction/invalidation must preserve financial history and ledger consistency.

Current implementation gap: the production planner currently throws `UnimplementedError` for correction and deletion planning.

### Gate C — Balance Adjustment

Editing an account's opening/current balance must have a real financial operation path.

Current implementation gap: `AccountTransactionService.createBalanceAdjustment(...)` throws `UnsupportedError`, while `UpdateAccountUseCase` calls it after updating the account.

Required end state:

```text
Account edit
    ↓
Balance Adjustment Operation
    ↓
Financial Engine
    ↓
Transaction/Ledger effects
```

The account metadata update and financial adjustment must not leave the system in a half-updated state.

### Gate D — Exact Money

`Money` is the authoritative domain representation per ADR-034.

Required end state:

```text
Financial domain
    ↓
Money / Decimal

Persistence / legacy boundary only
    ↓
double (temporary where required)
```

Current implementation gap: multiple financial-engine commands, intents, planner structures, mutations, and commitment-payment operations still use `double` internally.

No new Credit Card financial domain logic may copy the existing `double` pattern.

### Gate E — Atomic Execution

ADR-004 requires failed execution to leave no partial financial mutations.

Required end state:

```text
Validate whole operation
        ↓
Prepare execution
        ↓
Apply mutation set atomically
        ↓
Commit
```

If one mutation fails, the operation must not leave financial truth partially changed.

The current `MemoryFinancialUnitOfWork` is not a transaction/rollback mechanism; it only awaits the supplied function. This is a foundation gap, not a cosmetic refactor.

### Gate F — Durable Idempotency

Idempotency keys must survive process restart for operations whose effects may be retried automatically or through scheduled execution.

The current bootstrap uses `MemoryIdempotencyStore`, which loses history after process restart.

Required end state:

```text
Stable operation identity
        ↓
Durable idempotency record
        ↓
At-most-one financial effect for the same operation identity
```

Scheduled execution should use occurrence-level identities where the occurrence is the business event identity.

### Gate G — Scheduled Money Correctness

At minimum:

- Active commitments only create actions.
- Completed one-time occurrences never reappear as actionable.
- Recurring missed instances follow an explicit policy.
- Occurrence identity is stable.
- Successful execution completes the occurrence and advances the rule consistently.
- Failed execution is retryable without creating a second financial effect.
- Executed transactions can be traced back to their scheduling origin.

Current gaps are detailed in `05-SCHEDULED-MONEY-CONTRACT_V2.md`.

### Gate H — Production Planning Repository Wiring

Financial Engine and Planning Engine must not silently operate on different allocation repositories in production.

Current bootstrap behavior creates a production planning allocation repository for the Planning Engine, while the Financial Engine can default to a separate in-memory allocation repository when one is not explicitly supplied.

Required end state:

```text
Production Planning Repository
            ↑
     shared dependency
            ↓
Financial Engine allocation mutations
```

### Gate I — Real Regression Coverage

The existing full test suite passes (`105` tests in the latest terminal log), but passing tests do not prove every accepted architecture invariant is implemented.

Before freeze, add tests for at least:

- Correction
- Invalidation / deletion
- Balance adjustment
- Writer-boundary enforcement
- Durable/restart-safe idempotency behavior
- Active/paused/completed commitment filtering
- Completed one-time occurrence suppression
- Missed recurring occurrence policy
- Atomic multi-mutation failure
- Transaction ↔ occurrence linkage
- Production allocation-repository wiring
- Money usage through Card-related domain operations

## 4. Freeze Rule

Credit Card financial execution must not depend on an unclosed foundation gate.

The current Credit Cards screen may remain a UX prototype and may be refined visually. It must not become a financial writer until the above foundation gates are closed or an explicit exception is documented.

## 5. Definition of Done

The foundation is considered frozen only when all of the following are true:

```text
[ ] Single Writer is enforced for financial mutations
[ ] Correction is executable
[ ] Invalidation/Delete semantics are executable
[ ] Account balance adjustment is executable
[ ] Financial domain monetary values use Money
[ ] Financial Unit of Work provides true all-or-nothing semantics
[ ] Idempotency survives restart where required
[ ] Scheduled occurrence lifecycle contract is enforced
[ ] Transaction can be traced to its scheduling origin
[ ] Production Planning/Financial allocation repositories are aligned
[ ] Regression tests cover the above contracts
[ ] Existing docs no longer claim unimplemented work is complete
```

Only after this gate should the real Credit Card operation layer be wired to the UI.
