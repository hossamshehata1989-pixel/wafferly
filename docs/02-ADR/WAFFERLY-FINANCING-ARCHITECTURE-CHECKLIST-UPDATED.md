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

## Consistency / Numbering

- [x] Credit Card Charge canonical number = ADR-047
- [x] Credit Limit canonical number = ADR-049
- [x] Stale ADR-048 references found in ADR-051/066/067 corrected in the latest consistency patch
- [x] ADR-052 updated to ADR-047 reference
- [x] ADR-050 / ADR-053 linked to ADR-069
- [x] ADR-069 created as the explicit Statement ↔ Installment boundary
- [x] ADR-070 created as the explicit posted-charge → installment conversion boundary

## Still Open Before Implementation

- [ ] Verify the full ADR-047 → ADR-070 reference graph after applying all patches
- [ ] Define concrete persisted schema/models for Contract, Schedule, Installment, and Statement relationship
- [ ] Implement the ADR-070 financing-conversion domain operation
- [ ] Define the exact statement-contribution persistence/read model
- [ ] Implement pure interest/amortization calculator
- [ ] Implement deterministic installment schedule generation
- [ ] Implement payment allocation integration with financing installments
- [ ] Implement financing lifecycle transitions
- [ ] Add architecture tests for financing writer boundaries
- [ ] Add end-to-end tests for statement/installment no-double-counting
- [ ] Add idempotency/recovery tests across financing + FinancialOperationEngine
- [ ] Run full `flutter test` and `flutter analyze` after implementation changes

## Important Boundary

The ADR layer is now substantially specified. The posted-charge conversion boundary is explicitly defined in ADR-070.

Remaining work should move toward concrete domain models, pure calculators, operations, persistence boundaries, and tests rather than creating ADRs for already-settled domain fundamentals.
