# ADR-046 — Scheduled Execution Atomicity and Recovery

**Status:** Accepted
**Date:** 2026-09-25
**Related:** ADR-004, ADR-041, `01-FINANCIAL_FOUNDATION_FREEZE_V1.md`

## Context

Scheduled financial execution crosses two persistence boundaries:

1. `FinancialOperationEngine` owns financial truth and its durable idempotency key.
2. `ScheduleOccurrenceService` owns occurrence completion and rule advancement.

Hive does not provide one transaction spanning the financial transaction/ledger state and the scheduling boxes. Therefore a literal database transaction across both boundaries is not available.

The previous flow was:

```text
FinancialOperationEngine.execute()
        ↓ success
completeOccurrence()
        ↓
advanceRuleAfterOccurrence()
```

A failure between these steps could leave a financial effect already committed while the occurrence remained pending or the recurrence cursor remained stale.

## Decision

Scheduled execution uses **observational atomicity with durable recovery**, not a pretend cross-box transaction.

A durable per-occurrence execution journal records:

```text
executing
    ↓
financial_succeeded
    ↓
completed
```

A financial failure records `failed` and leaves scheduling state unchanged.

Once `financial_succeeded` is recorded, retries MUST NOT execute the financial operation again. They resume only the scheduling transition.

The financial operation continues to use the stable occurrence-level idempotency key:

```text
scheduled-commitment:<occurrenceId>
```

This also protects the crash window between the financial engine committing its effect and the journal recording `financial_succeeded`: a retry may call the engine again, but the durable financial idempotency layer returns the existing successful result instead of creating a second effect.

## Recovery Contract

### Financial operation fails

```text
Journal = failed
Financial effect = none
Occurrence = pending
Rule cursor = unchanged
```

A later retry may execute the financial operation again using the same stable idempotency identity.

### Financial operation succeeds, scheduling transition fails

```text
Journal = financial_succeeded
Financial effect = committed
Occurrence/rule transition = incomplete
```

A later retry MUST skip creating a new financial effect and resume:

```text
complete occurrence
        ↓
advance rule
        ↓
mark journal completed
```

### Scheduling transition succeeds

```text
Journal = completed
Financial effect = committed exactly once
Occurrence = completed
Rule cursor = advanced consistently
```

Subsequent execution of the same occurrence is a no-op at the orchestration boundary.

## Consequences

### Positive

- No duplicate financial effect during scheduled retries.
- Process-crash recovery has an explicit durable state.
- Scheduling recovery does not require weakening Financial Engine idempotency.
- The pattern is reusable for future Credit Card scheduled operations such as statement close, due-date processing, and scheduled payments.

### Constraint

This is **observational atomicity**, not a literal multi-box database transaction. The invariant is eventual convergence to one financial effect plus the corresponding scheduling state, with durable evidence of an interrupted transition.

## Required Tests

The implementation must cover:

1. financial success → occurrence completion → rule advancement;
2. financial failure → no scheduling mutation;
3. completion failure after financial success → journal remains `financial_succeeded`;
4. retry after completion failure → no second financial execution;
5. advancement failure after financial success → journal remains `financial_succeeded`;
6. retry after advancement failure → no second financial execution;
7. completed orchestration → repeated call is a no-op.
