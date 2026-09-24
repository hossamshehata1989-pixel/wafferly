# ADR-038 — Financial Correction Write Model

**Status:** Accepted  
**Date:** 2026-09-24  
**Related:** ADR-0015 (Financial Corrections), ADR-0016 (Financial Write Model & Ledger Projection), ADR-036 (Single Writer Boundary)

## Context

The existing correction command reached the Financial Engine, but correction planning was unimplemented. The remaining architectural problem was how to represent the neutralization of previously accepted financial truth without:

- mutating the original transaction in place;
- creating a synthetic reversal transaction;
- using `JournalEntryMutation` as a substitute for the Financial Write Model; or
- writing directly to the Ledger.

The Ledger is a projection of Financial Write Models. Therefore a correction must itself be represented as an immutable Financial Write Model.

## Decision

Introduce `FinancialCorrectionRecord` as a first-class immutable Financial Write Model.

A correction contains:

- `correctionId` — unique correction identity;
- `originalTransactionId` — logical transaction being corrected;
- `before` — accepted financial truth before correction;
- `after` — corrected financial truth.

The correction is persisted through `CorrectionPort` and executed through `CreateCorrectionMutation`.

The original transaction materialization is preserved under its original transaction ID. The corrected `after` record is materialized as a new immutable transaction with a new transaction ID, while the immutable `FinancialCorrectionRecord` preserves the explicit before/after relationship and correction identity.

## Ledger Projection

`LedgerProjectionService.projectCorrection()` produces two projection effects under the correction ID:

1. reversal of the original financial effect;
2. projection of the corrected financial effect.

The reversal is marked with `LedgerPurpose.adjustment`.

No synthetic reversal `Transaction` is created and no direct Ledger write occurs outside `LedgerProjectionService`.

## Constraints

Generic correction is currently supported only for:

- expense;
- income;
- transfer.

Changing transaction type is rejected because it requires an explicit domain operation rather than a generic correction.

Debt is intentionally excluded from this generic path in accordance with the existing Debt domain architecture.

## Atomicity

The correction mutation executes as one Financial Unit of Work:

1. persist the correction write model;
2. persist the corrected transaction materialization;
3. project the correction to Ledger.

Rollback removes only the newly materialized corrected transaction and removes the correction record and correction projection; the original transaction materialization remains untouched.

## Consequences

The Financial Engine now has a canonical immutable representation for correction semantics while preserving the existing separation:

```text
Transaction = actual financial truth/materialized transaction
Correction  = immutable correction of financial truth
Journal     = accounting model where applicable
Ledger      = projection
```

Future migration from Hive to Supabase can implement `CorrectionPort` independently without changing correction domain semantics.
