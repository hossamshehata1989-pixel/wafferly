# ADR-045 — Money Boundary M2 Hardening

**Status:** Accepted  
**Date:** 2026-09-25  
**Related:** ADR-044 (Money Consistency M1 Closed)

## Decision

M2 hardens the remaining monetary boundaries identified after M1 without converting legacy storage/read/UI models wholesale.

### Planning boundary

The following APIs are Money-native:

- `AvailableBalanceProjectionService.project(balance: Money)`
- `CannotReserveMoreThanAvailableGuard.accountBalanceProvider`
- `PlanningEngineBootstrap.create(accountBalanceProvider: Money Function(String))`

The application composition root may explicitly adapt the legacy `BalanceService.getBalance()` double into `Money`.

### Ledger projection boundary

`TransactionLedgerBuilder` now accepts `Money` throughout its public API. The conversion to the legacy `LedgerEntry.amount` double occurs only inside `_createEntry`, at the projection/storage compatibility boundary.

Legacy `Transaction` callers are adapted with `Money.fromDouble(...)` in `LedgerProjectionService`; `FinancialTransactionRecord` and correction/invalidation records pass their existing `Money` values directly.

## Non-decisions

This ADR does **not** migrate the following wholesale:

- `BalanceService` public read API
- legacy `Transaction` model
- legacy `LedgerEntry` model
- UI/read-model monetary fields
- legacy Allocation model

Those require separate caller/semantics audits and are not justified merely by the presence of `double`.

## Guards

- M1 ratchet continues to scan `lib/financial_engine` and `lib/core/planning` for unapproved monetary `double` declarations.
- M2 adds targeted architecture tests for the Planning balance boundary and Ledger builder boundary.

## Verification

User verification remains required on the actual Flutter/Dart environment. This package does not claim to have executed Flutter tests locally.


## M2.1 Correction after integration compile audit

The first M2 package exposed two compatibility assumptions that were rejected by the real project build: `BalanceService` must convert its legacy `double` balance to `Money` before calling the Planning projection service, and the current LedgerEntry boundary in the target branch is already Money-native, so `TransactionLedgerBuilder` must not convert the amount back to `double`. The integration test was updated to pass Money directly.


## Correction after compiler verification

The initial M2 hardening guard incorrectly prohibited the final `Money -> double`
conversion inside `TransactionLedgerBuilder`. The target `LedgerEntry` remains a
legacy double-backed projection/persistence model, so this conversion is an
approved compatibility boundary. The builder's public financial API remains
Money-native; the conversion occurs only when constructing `LedgerEntry`.
Correction/invalidation helper calls remain Money-native and must not call
`toDouble()` before reaching that constructor boundary.
