# ADR-042 — Effective Financial Truth Read Boundary

**Status:** Accepted  
**Date:** 2026-09-25  
**Related:** ADR-0015 Financial Corrections, ADR-0016 Financial Write Model & Ledger Projection, Financial Invalidation, Balance Reconciliation

## Context

Correction and invalidation intentionally preserve immutable financial history.
A correction preserves the original transaction and materializes a new corrected
transaction. An invalidation preserves the transaction and records that its
financial effect is no longer active.

The existing read paths treated every persisted transaction as active truth.
This caused a corrected transaction and its superseded original to both appear
in transaction lists and both contribute to derived balances.

## Decision

Introduce a read-side `FinancialEffectiveTransactionQuery`.

A persisted transaction is **effective financial truth** only when:

1. the transaction exists in the transaction store;
2. its ID is not the `originalTransactionId` of a persisted correction; and
3. its ID is not the `originalTransactionId` of a persisted invalidation.

The query is read-only and does not modify financial history.

### Correction chain

```text
Original 200
    ↓ correction
Corrected 500
    ↓ correction
Corrected 700
```

Only `700` is effective. `200` and `500` remain immutable history.

### Correction followed by invalidation

```text
Original 200
    ↓ correction
Corrected 500
    ↓ invalidation
(no active financial effect)
```

Both persisted transaction records remain available as history, but neither is
active financial truth.

## Consequences

### Production read paths using effective truth

- Transactions screen lists and filters.
- Transaction lookup used by production application-service operations.
- BalanceService current balance.
- BalanceService historical/date-derived balance.
- Transaction totals and category/source analytics that delegate to the query methods.

### Explicitly unchanged

- Original transaction persistence.
- Correction records.
- Invalidation records.
- Ledger projection/history.
- Financial write semantics.

The change therefore fixes read semantics without turning correction into a
hard update or deletion.

## Regression requirements

The effective-truth tests must prove:

- corrected original is hidden from active transaction lists;
- corrected transaction remains active;
- correction chains expose only the latest transaction;
- invalidating the current corrected transaction removes its active effect;
- immutable transaction history is not deleted or modified;
- balances are derived from effective transactions only.
