# ADR-040 — Durable Idempotency

**Status:** Accepted  
**Date:** 2026-09-24  
**Related:** ADR-036 — Single Writer Boundary; ADR-037 — Balance Reconciliation; ADR-039 — Balance Reconciliation Accounting Contract

## 1. Decision

Financial idempotency state must be durable for operations whose retry can cross an engine/process lifetime, especially scheduled financial execution.

Production wiring therefore uses a Hive-backed `IdempotencyStore`. `MemoryIdempotencyStore` remains available only for isolated/non-persistent contexts.

## 2. Persistence Contract

Only a successfully completed financial operation is persisted as an idempotency record. Failed, rejected, confirmation-required, and domain-violation results are not remembered as completed financial effects.

The durable record stores the successful execution summary required to reconstruct the result on a later engine instance.

## 3. Retry Contract

For the same stable operation identity:

```text
first execution
    ↓
financial effect committed
    ↓
durable idempotency record
    ↓
process / engine restart
    ↓
retry with same identity
    ↓
return stored success
    ↓
no second financial effect
```

The durable record is written only after the financial executor reports `OperationSucceeded`.

## 4. Scheduled Execution

Scheduled money operations must use an occurrence-level stable identity so a retry of the same occurrence does not create another transaction. This ADR provides the durable storage boundary; occurrence identity remains part of the scheduled-money contract.

## 5. Failure Safety

A failed execution must not poison its idempotency key. The same logical operation may be retried after the failure without receiving a cached failure as if the financial effect had committed.

Malformed durable idempotency records fail closed rather than silently executing the financial operation again.

## 6. Current Scope

This ADR closes durable persistence across engine/process lifetime. It does not claim to solve concurrent same-key executions across isolates/processes; that requires an atomic claim/locking protocol and remains a separate concern.
