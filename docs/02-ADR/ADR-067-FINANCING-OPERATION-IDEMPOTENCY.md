# ADR-067 — Financing Operation Idempotency Policy

**Status:** Proposed → Implementation  
**Date:** 2026-09-27  
**Related:** ADR-041, ADR-047, ADR-047, ADR-051, ADR-059, ADR-063, ADR-066

## Decision
Every financing operation capable of producing a financial effect has a stable idempotency identity.

Examples:
```text
Charge
Payment
Settlement
Refund
Reversal
Fee Assessment
Replacement
```

## Stable Identity
The idempotency key identifies the logical operation, not an execution attempt.

```text
Same Operation
  ↓
Same Key
  ↓
Same Financial Effect
```

## Retry
A retry after success must not create a second financial mutation. The durable prior outcome is reused.

## Failure
Failure before financial mutation may be retried. Failure after financial success must be recoverable without repeating the financial effect.

## Scope
Idempotency covers the entire financial effect, not merely UI button presses.

## Required Tests
- same operation twice;
- retry after success;
- retry after partial workflow failure;
- durable restart/recovery;
- no duplicate transaction;
- no duplicate ledger movement;
- no duplicate contract transition.
