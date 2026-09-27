# Wafferly Financing / Credit-Card Architecture Checklist

Updated: 2026-09-27

## Foundation / Source of Truth

- [x] Credit Card Charge has a dedicated Financial Engine operation — ADR-047
- [x] Credit Limit / Credit Exposure / Available Credit canonical boundary — ADR-049
- [x] Credit Card Statement lifecycle — ADR-050
- [x] Credit Card Payment / Settlement operation — ADR-051
- [x] Installment / Financing Contract boundary — ADR-052
- [x] Interest / amortization model — ADR-053
- [x] Payment allocation order — ADR-054
- [x] Multi-installment payment allocation — ADR-055
- [x] Early settlement / prepayment policy — ADR-056
- [x] Late-payment fee policy — ADR-057
- [x] Financing restructuring policy — ADR-058
- [x] Financing replacement / refinancing boundary — ADR-059
- [x] Financing settlement / closure lifecycle — ADR-060
- [x] Financing cancellation / termination boundary — ADR-061
- [x] Financing overpayment / excess-payment policy — ADR-062
- [x] Financing payment reversal / refund boundary — ADR-063
- [x] Financing default / delinquency lifecycle — ADR-064
- [x] Financing waiver / forgiveness boundary — ADR-065
- [x] Financing financial-effects / writer boundary — ADR-066
- [x] Financing operation idempotency — ADR-067
- [x] Financing audit / traceability boundary — ADR-068
- [x] Credit Card Statement ↔ Installment relationship — ADR-069
- [x] Credit Card posted-charge → installment conversion boundary — ADR-070

## Schema / Terminology Decisions

- [x] `principal` established as canonical amortizing contractual principal
- [x] `financedAmount` not duplicated as a second authoritative monetary field in MVP
- [x] `installmentAmount` belongs to scheduled installment obligation, not authoritative contract balance/term
- [x] `repaymentTerms` decomposed into structured terms
- [x] Contract lifecycle separated from contract delinquency
- [x] Installment status kept separate from contract lifecycle/delinquency
- [x] Statement inclusion based on installment eligibility for the statement cycle
- [x] No-double-counting invariant established for financed purchases
- [x] Existing posted charge remains the financial principal source during conversion
- [x] Conversion does not create a second principal liability
- [x] Conversion does not rewrite the original charge
- [x] Closed statements remain immutable after later conversion
- [x] Future interest is not posted as immediate full liability merely because it is scheduled

## Persisted Financing Schema

- [x] Concrete persisted `FinancingContract` model
- [x] Concrete persisted `FinancingSchedule` model linked to existing `ScheduleRule`
- [x] Concrete persisted `FinancingInstallment` model
- [x] Concrete persisted `StatementInstallmentContribution` relationship/read-model
- [x] Financing monetary persistence uses exact decimal strings and exposes `Money` in the domain model
- [x] Hive adapter IDs allocated without colliding with existing model IDs (110–114)
- [x] Financing boxes registered/opened in application bootstrap
- [x] Schema tests added for principal semantics, installment composition, schedule linkage, and statement contribution identity
- [x] Durable `FinancingConversionEvent` model added (Hive 114)
- [x] ADR-070 conversion operation implementation added
- [x] ADR-070 focused conversion tests added
- [x] Financing conversion writer-boundary test added

## Consistency / Numbering

- [x] Credit Card Charge canonical number = ADR-047
- [x] Credit Limit canonical number = ADR-049
- [x] Stale ADR-048 references found in ADR-051/066/067 corrected in the latest consistency patch
- [x] ADR-052 updated to ADR-047 reference
- [x] ADR-050 / ADR-053 linked to ADR-069
- [x] ADR-069 created as the explicit Statement ↔ Installment boundary
- [x] ADR-070 created as the explicit posted-charge → installment conversion boundary

## Still Open After ADR-070 Implementation

- [x] Verify the ADR-047 → ADR-070 reference graph and canonical numbering
- [x] Implement the ADR-070 financing-conversion domain operation
- [x] Fix missing Hive `FrequencyAdapter` registration in ADR-070 conversion tests
- [x] Fix credit-card charge test fixture seeding order so ledger category mappings exist after per-test cleanup
- [x] Define and implement the exact statement-generation service/repository integration around `StatementInstallmentContribution`
- [x] Implement pure interest/amortization calculator
- [x] Define ADR-053 fixed-rate model and pure interest/amortization calculator implementation
- [x] Verify ADR-053 calculator tests locally
- [x] Implement deterministic installment schedule generation
- [x] Verify deterministic installment schedule tests locally
- [x] Implement pure financing payment allocation calculator for ADR-054/055/062
- [ ] Implement financing lifecycle transitions
- [x] Add architecture tests for financing writer boundaries
- [x] Add end-to-end tests for statement/installment no-double-counting
- [x] Correct Statement Projection so installment contributions are projected independently from the originating-charge loop
- [x] Fix Statement Projection to use the canonical `TransactionType.creditCardCharge` value for originating-charge detection
- [x] Expand Statement ↔ Installment E2E coverage for future-cycle eligibility, interest/fees preservation, and payment separation
- [x] Align E2E installment identity assertions with the canonical conversion-generated installment IDs (`scheduleId|sequence`)
- [x] E2E no-double-counting tests pass locally — 6/6
- [ ] Add idempotency/recovery tests across financing + FinancialOperationEngine
- [ ] Run full `flutter test` and `flutter analyze` after implementation changes

## Verification Note

Latest local execution reported by the user:
- Schema test: passed 4/4.
- Financing conversion test: passed 4/4.
- Financing writer-boundary test: passed 1/1.
- Credit-card charge pipeline: passed 5/5.

The ADR reference-graph consistency pass was performed against the canonical financing source set and the implementation ADRs used by this project. No remaining known ADR-048 reference exists in that canonical set.

## Important Boundary

The concrete persisted schema and ADR-070 conversion operation are now implemented without creating a second financial ledger. The next gate is local test execution, followed by statement/installment integration.
