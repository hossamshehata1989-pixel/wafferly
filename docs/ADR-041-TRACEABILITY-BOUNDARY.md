# ADR-041 — Financial Operation Traceability Boundary

**Status:** Accepted
**Date:** 2026-09-24
**Related:** ADR-036 (Single Writer), ADR-0013 (Financial Write Model), Durable Idempotency

## Context

Wafferly's FinancialOperationEngine is the canonical writer for Financial Reality. History / Audit is a distinct state boundary and must not become a second financial source of truth.

The engine already has an execution identity (`idempotencyKey`) and scheduled linkage (`commitmentId`, `scheduleRuleId`, `occurrenceId`), while produced financial records carry actor attribution. Before Credit Card Backend work, an immutable execution trail is required so a financial result can be traced back to its initiating operation and execution context without inspecting transaction internals manually.

## Decision

Introduce a dedicated **Traceability / History** boundary:

- `TraceabilityRecord` is immutable audit data.
- `TraceabilityPort` owns persistence/query access.
- Hive is the production durable adapter; memory is the test/fallback adapter.
- The FinancialOperationEngine records terminal outcomes for the first execution attempt:
  - `succeeded`
  - `failed`
  - `rejected`
  - `confirmation_required`
  - `domain_violation`
- An idempotency cache hit does not create a second execution trace because no second financial execution occurred.
- A successful trace links produced transaction IDs and relevant mutation/journal IDs.
- Trace records can be queried by trace ID, idempotency key, and transaction ID.
- Traceability persistence must never mutate Financial Reality and must not convert an already-applied financial success into a reported financial failure if the audit adapter itself fails.

## Trace Fields

Each record may contain:

- trace ID
- operation type / command type
- operation ID when available
- idempotency key
- actor member ID when supplied by the initiating boundary
- source (`manual`, `scheduled`, etc.) when supplied
- commitment / schedule rule / occurrence linkage
- produced transaction IDs
- mutation / journal IDs
- terminal status and error information
- start and completion timestamps

## Consequences

### Positive

- Financial operations become explainable without treating audit history as financial truth.
- Scheduled operations can be traced to their commitment and occurrence.
- Corrections and invalidations can be connected to their affected transaction IDs.
- Durable history survives process restart when Hive is configured.
- Credit Card operations can reuse the same trace boundary instead of inventing a separate audit mechanism.

### Explicit Limitations

- Traceability is not a concurrency lock and does not solve concurrent same-key idempotency races.
- The current trace adapter is intentionally outside the Financial Unit of Work. Its persistence failure is logged rather than changing an already-applied financial result.
- Actor/source fields remain optional because not every existing application boundary currently supplies them.
