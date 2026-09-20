# Scheduled Money Contract V2

**Status:** Implementation Contract
**Scope:** Commitments, ScheduleRule, ScheduleOccurrence, Financial Action Center, Financial Engine execution

## 1. Purpose

Scheduled Money describes expected future events and their eventual execution. It must not become a second financial ledger.

```text
ScheduleRule       = recurrence/time rule
Commitment         = future financial meaning
ScheduleOccurrence = one concrete scheduled instance
Transaction        = what actually happened
```

## 2. Occurrence Identity

A recurrence slot has one stable identity:

```text
ScheduleRule + concrete due-date slot
```

Regenerating the same slot must return the same occurrence identity.

## 3. Occurrence Lifecycle

Target lifecycle:

```text
PENDING
  ├── COMPLETED
  ├── SKIPPED
  └── FAILED / RETRYABLE
```

Failure is an execution result and must remain distinguishable from an intentional skip.

Retrying a failed occurrence must reuse the same occurrence identity rather than generating a new financial event identity.

A one-time completed occurrence must never become actionable again.

## 4. Commitment Lifecycle Gate

Only commitments that are:

```text
status == active
AND
isArchived == false
```

may generate executable actions.

Paused/completed commitments must not create Financial Action Center execution items.

This rule must live in the production action-provider path, not only in read-side screens.

## 5. Missed Recurrence Policy

Default policy for financial commitments: **stack missed occurrences**.

Reason: an unpaid past expectation must not disappear merely because the recurring rule has a later due date.

Example:

```text
Jan 10 → unpaid
Feb 10 → unpaid
Mar 10 → current
```

The system should be able to represent the historical unpaid instances independently.

Some domains may explicitly use a `latest-only` / collapse policy, but that must be declared by the domain contract rather than being an accidental ScheduleRule behavior.

## 6. Due State

`upcoming`, `due`, and `overdue` are derived temporal states.

They must be computed from:

- occurrence due date
- current date/time
- occurrence execution state
- relevant domain rules

They must not be persisted as duplicate source-of-truth state unless a future ADR explicitly requires a cache.


## 7. Financial Action Projection Contract

Financial Action Center displays a user-oriented projection of scheduled occurrences.

Multiple occurrences belonging to the same actionable commitment may be grouped for presentation, while each occurrence remains an independent domain record and execution target.

Grouping is a presentation/projection concern only. It must not merge, delete, or replace the underlying `ScheduleOccurrence` records.

Each grouped action must retain enough information to identify and execute the individual occurrences selected by the user.

### Domain vs. Presentation Boundary

```text
ScheduleRule
    ↓
ScheduleOccurrence #1
ScheduleOccurrence #2
ScheduleOccurrence #3
    ↓
Financial Action Projection
    ↓
Grouped UI Action
```

**Rule:** Grouping in the Financial Action Center must never change the financial or scheduling truth represented by individual occurrences.

For execution, the grouped action is only a selection surface. The actual Financial Engine execution remains occurrence-based.

## 8. Execution Contract

The execution path is:

```text
Financial Action
      ↓
Financial Operation
      ↓
Financial Operation Engine
      ↓
Transaction / Ledger / required domain mutations
      ↓
Mark occurrence completed
      ↓
Advance recurrence rule
```

The financial mutation and scheduling transition are one logical business execution.

## 9. Atomicity Requirement

The system must not permanently reach:

```text
Transaction created
BUT
Occurrence still pending
```

or:

```text
Occurrence completed
BUT
Financial transaction missing
```

as a consequence of a partial failure.

The implementation must therefore provide an all-or-nothing execution boundary across the financial mutation and the scheduling state transition, or a durable recovery protocol that makes the combined operation observationally atomic.

A simple `await` wrapper around the operation is not sufficient.

## 10. Idempotency

The occurrence is the natural identity for scheduled execution.

Required property:

```text
same occurrence
+ same execution intent
+ repeated retry
        ↓
no second financial effect
```

Idempotency state must be durable for automatic/scheduled execution.

## 11. Transaction Linkage

Whenever a scheduled occurrence causes a transaction, the transaction must retain enough linkage to answer:

- Which occurrence produced this transaction?
- Which schedule rule was involved?
- Which commitment caused it?

This is required for reconciliation, retry safety, audit, and UI detail views.

## 12. Recurrence Advancement

The rule should advance only after the occurrence's financial execution has successfully completed according to the operation's contract.

A completed occurrence must not advance the rule twice.

Advancement and occurrence completion must be idempotent.

## 13. Monthly Recurrence Boundary

Monthly recurrence must define an explicit day-of-month policy.

The implementation must cover end-of-month cases such as:

```text
Jan 31 → Feb ?
Feb 28/29 → Mar ?
Apr 30 → May ?
```

The rule must not rely on implicit `DateTime` overflow behavior.

A concrete policy such as `clamp-to-last-day-of-month` must be encoded and tested if that is the selected business behavior.

## 14. Scheduled Payment Metadata

Payment method and currency metadata must come from the actual source account/instrument/session context.

Do not hard-code:

```text
paymentMethod = cash
currency = EGP
```

for all liability payments.

## 15. Provider Consolidation

There are duplicate `CommitmentActionProvider` implementations in the current codebase.

The production provider is under:

```text
lib/services/providers/commitment_action_provider.dart
```

The duplicate provider under:

```text
lib/services/commitment_action_provider.dart
```

must not become a second source of behavior or test authority.

The production path must have direct tests for its lifecycle filtering and occurrence behavior.

## 16. Minimum Regression Matrix

| Scenario | Expected result |
|---|---|
| Active commitment | Action may be created |
| Paused commitment | No action |
| Completed commitment | No action |
| Archived commitment | No action |
| Completed one-time occurrence | No action |
| Same recurrence slot requested twice | Same occurrence |
| Scheduled execution retried | One financial effect |
| Execution fails | No partial financial truth |
| Missed recurring event | Explicit stacked/collapse policy |
| Monthly end-of-month | Deterministic next due date |
| Payment from bank | Correct source metadata |
