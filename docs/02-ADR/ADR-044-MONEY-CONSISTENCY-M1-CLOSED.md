# ADR-044 — Money Consistency M1 Boundary Closure

**Status:** Accepted
**Date:** 2026-09-25
**Related:** Money Boundary Ratchet, Financial Foundation Freeze V1, ADR-016

## Decision

The Financial Domain and Planning accounting path is Money-native.

Financial monetary values must use `Money` through the Domain/Planning boundary,
including:

- ExpenseIntent.amount
- IncomeIntent.amount
- OpeningBalanceIntent.amount
- TransferIntent.amount
- NormalizedIntent.amount
- EntryLine.debit
- EntryLine.credit
- BalanceReconciliationIntent.systemBalance
- BalanceReconciliationIntent.observedBalance
- BalanceReconciliationContext.systemBalance
- BalanceReconciliationContext.observedBalance
- GoalActivityMutation.amount
- ReleaseAllocationMutation.amount
- CreateAllocationMutation.amount
- CommitmentPaymentOperation.amount
- CreateGoalAllocationOperation.amount
- GoalSavingTransferOperation.amount
- GoalTransferOperation.amount

`BalancePort` is a Financial Domain port and is Money-native. Infrastructure
adapters may convert legacy/read-model `double` values to `Money` when crossing
into the Domain.

## Approved conversion boundaries

Conversions between `double` and `Money` are permitted only at an explicitly
identified compatibility/persistence boundary. Current examples include:

- `HiveBalancePort`: converts legacy BalanceService/read-model doubles to Money.
- `HiveTransactionPort`: converts FinancialTransactionRecord Money to the
  legacy Hive Transaction double representation and back.
- `HiveAllocationRecord`: preserves the legacy Hive allocation `double` field.
- Application compatibility inputs such as legacy UI/application balance input
  may convert to Money at the application boundary.

## Domain rule

The Financial Planner, Journal model, Integrity Checker, Domain Guards and
Domain constraints must not convert Money back to double merely to satisfy a
legacy type.

## Ratchet

`money_boundary_ratchet_test.dart` scans:

- `lib/financial_engine`
- `lib/core/planning`

for unapproved:

- `double amount`
- `double debit`
- `double credit`

The proven persistence boundary for `hive_allocation_record.dart` remains
explicitly documented.

## M1 audit result

The twelve historical `double amount` debt files were reviewed after the
migration. Their financial amount fields are now Money-native. No unapproved
`double amount`, `double debit`, or `double credit` declaration remains in the
scanned Financial Engine / Planning roots.

A repository-wide search still finds `double amount` declarations in UI,
application compatibility, services, legacy models and persistence models.
Those are outside the M1 Domain ratchet scope and must not be silently
reclassified as Domain debt without a separate boundary audit.

## Verification

M1 targeted Money consistency tests passed.
The Money Boundary Ratchet passed.
The full Flutter test suite subsequently passed with 151 tests.
