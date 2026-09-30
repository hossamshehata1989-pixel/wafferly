# Wafferly Financing / Credit-Card Architecture Checklist

Updated: 2026-09-28

## Release V1 — Implemented and Verified

- [x] ADR-047 — Credit Card Charge Operation
- [x] ADR-049 — Credit Limit / Credit Exposure / Available Credit boundary
- [x] ADR-050 — Current Statement Projection boundary (full persisted close lifecycle deferred)
- [x] ADR-069 — Statement ↔ Installment contribution / no-double-counting boundary
- [x] ADR-070 — Posted-charge → installment financing conversion boundary
- [x] ADR-066 — Financing financial-effects / writer boundary as architectural constraint
- [x] ADR-067 — Financing logical idempotency boundary as architectural constraint

## Contract / Calculation Foundations

- [x] ADR-052 — Installment / Financing Contract model defined and used by conversion foundation
- [x] ADR-053 — Interest / amortization model defined as calculation foundation
- [ ] Broader payment/settlement integration of ADR-052/053 — deferred to Financing Phase 2

## Financing Phase 2 — Explicitly Deferred

These are documented policy/architecture decisions, but are **not claimed as implemented operations** in the current release:

- [ ] ADR-051 — Credit Card Payment / Settlement Operation
- [ ] ADR-054 — Payment Allocation Order integration into a real payment operation
- [ ] ADR-055 — Multi-Installment Payment Allocation integration
- [ ] ADR-056 — Early Settlement / Prepayment
- [ ] ADR-057 — Late Payment Fee assessment / execution
- [ ] ADR-058 — Financing Rescheduling / Restructuring
- [ ] ADR-059 — Financing Replacement / Refinancing
- [ ] ADR-060 — Full Financing Contract Settlement / Closure evaluation
- [ ] ADR-061 — Financing Cancellation / Termination obligation classification
- [ ] ADR-062 — Financing Overpayment / Excess Payment enforcement
- [ ] ADR-063 — Financing Payment Reversal / Refund
- [ ] ADR-064 — Financing Default / Delinquency lifecycle implementation
- [ ] ADR-065 — Financing Waiver / Forgiveness

## Architecture Hardening — V24

- [x] Structural transaction writer-boundary test
- [x] Structural financing / credit-card financial-writer boundary test
- [x] Money boundary ratchet expanded to financing / credit-card domains
- [x] Concurrent conversion protection for the same origin charge
- [x] Concurrent conversion regression test
- [x] Explicit V1 financing release-scope document

## Verification Gates

- [x] `flutter test test/architecture` — **22/22 passed**
- [x] `flutter test test/financing/financing_idempotency_recovery_test.dart` — **5/5 passed**
- [x] Full `flutter test` — **240/240 passed**
- [x] `flutter analyze` — **0 compile errors** at the latest verification checkpoint
- [x] Available UI input screens manually smoke-tested
- [x] Final ADR / documentation cleanup
- [x] Final release gate — technical gates complete; human release decision remains

## Source-of-Truth Rule

Passing the full test suite does not imply that deferred ADRs are implemented. The current release claims only the implemented V1 foundation above. Any future financing feature that produces an actual financial effect on Account, Transaction, Ledger, Balance, or Financial Engine idempotency must cross the existing Financial Operation Engine boundary.

## Accounts / Liabilities UX V2
- [x] Money You Owe shows dedicated category cards even when empty
- [x] Credit Cards / Loans / Installments-BNPL / Borrowed Money are separate categories
- [x] Liability category detail screens are separate from Money You Have account details
- [x] Credit Card has a dedicated account detail screen
- [x] Generic Money You Have account detail remains unchanged
- [ ] Flutter test execution after UX change
- [ ] Architecture gate after UX change

## Accounts / Liabilities UX V3 — Verification Pending
- [x] Remove orphan legacy `AllocationRecord` model that reintroduced an unapproved `double` monetary field and missing generated adapter.
- [x] Move liability category-level outstanding aggregation into `DebtQueryService`.
- [x] Remove independent debt aggregation from `LiabilityReadService` / `MoneyYouOweScreen`.
- [x] Remove orphan legacy `CategoryCard` widget that referenced a missing expense bottom-sheet API.
- [ ] Re-run `flutter analyze` after V33 changes.
- [ ] Re-run `flutter test test/architecture/debt_balance_single_source_test.dart`.
- [ ] Re-run `flutter test test/architecture/money_boundary_ratchet_test.dart`.
- [ ] Re-run `flutter test test/financial_action_panel_grouping_test.dart` and inspect exact failure if it remains.
- [ ] Re-run full `flutter test` after V33.
