# ADR-043 — Money Consistency Domain Boundary

**Status:** Accepted  
**Date:** 2026-09-25  
**Related:** ADR-036, ADR-037, ADR-039, ADR-042

## Decision

Financial amounts inside the Financial Engine and Planning domain are represented by `Money`, not `double`.

This includes:

- Financial intents
- NormalizedIntent
- Financial operations
- Financial mutations
- Journal `EntryLine.debit` / `credit`
- Financial integrity calculations
- Balance ports and balance constraints
- Balance reconciliation context

## Compatibility boundaries

`double` remains allowed only where the current legacy model or persistence representation requires it. Conversion occurs at the boundary, not inside the Financial Domain.

Approved examples:

- Application input (`double`) → `Money.fromDouble(...)` before creating a Financial Domain intent.
- `HiveBalancePort` legacy balance (`double`) → `Money.fromDouble(...)` before returning through `BalancePort`.
- Goal activity / legacy allocation adapters: `Money.toDouble()` only when crossing into the legacy persistence model.
- Transaction/Ledger persistence representations remain unchanged.

## Accounting boundary

`EntryLine` is part of the Financial Engine's accounting model and therefore uses `Money`. No planner-level `Money → double` conversion is permitted.

## Guard

`test/architecture/money_boundary_ratchet_test.dart` scans `lib/financial_engine` and `lib/core/planning` for new `double amount`, `double debit`, `double credit`, and `double get amount` declarations. The only current exception is the documented Hive allocation persistence representation.

## Result

The previous 12-file Money technical debt set has been migrated. The ratchet baseline is now empty, so future financial domain code cannot silently reintroduce `double` monetary fields.
